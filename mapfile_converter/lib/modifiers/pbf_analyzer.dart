import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:mapfile_converter/modifiers/cachefile.dart';
import 'package:mapfile_converter/modifiers/large_data_splitter.dart';
import 'package:mapfile_converter/modifiers/way_connect.dart';
import 'package:mapfile_converter/osm/osm_data.dart';
import 'package:mapfile_converter/pbf/pbf_reader.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/special.dart';

import '../custom_tag_modifier.dart';
import '../modifiers/way_repair.dart';
import '../osm/osm_reader.dart';

/// Reads data from a pbf file and converts it to PointOfInterest and Way objects
/// so that they are usable in mapsforge. By implementing your own version of
/// [PbfAnalyzerConverter] you can control the behavior of the converstion from
/// OSM data to PointOfInterest and Way objects.
class PbfAnalyzer {
  final _log = Logger('PbfAnalyzer');

  final double maxGapMeter;

  final Map<int, _PoiHolder> _nodeHolders = {};

  final Map<int, WayholderUnion> _wayHolders = {};

  final List<Wayholder> _wayHoldersMerged = [];

  Map<int, OsmRelation> relations = {};

  Set<int> nodeNotFound = {};

  Set<int> wayNotFound = {};

  int nodesWithoutTagsRemoved = 0;

  int waysWithoutNodesRemoved = 0;

  int closedWaysWithLessNodesRemoved = 0;

  int waysMergedCount = 0;

  int nodesFiltered = 0;

  int waysFiltered = 0;

  BoundingBox? boundingBox;

  PbfAnalyzerConverter converter = PbfAnalyzerConverter();

  List<PointOfInterest> get pois => _nodeHolders.values.map((e) => e.pointOfInterest).toList();

  Future<List<Wayholder>> get ways async {
    List<Wayholder> result = [];
    for (var e in _wayHolders.values) {
      Wayholder wayholder = await e.get();
      result.add(wayholder);
    }
    return result;
  }

  List<Wayholder> get waysMerged => _wayHoldersMerged;

  PbfAnalyzer._({this.maxGapMeter = 200, required RuleAnalyzer ruleAnalyzer}) {
    converter = CustomTagModifier(
      allowedNodeTags: ruleAnalyzer.nodeValueinfos(),
      allowedWayTags: ruleAnalyzer.wayValueinfos(),
      negativeNodeTags: ruleAnalyzer.nodeNegativeValueinfos(),
      negativeWayTags: ruleAnalyzer.wayNegativeValueinfos(),
      keys: ruleAnalyzer.keys,
    );
  }

  static Future<PbfAnalyzer> readFile(String filename, RuleAnalyzer ruleAnalyzer, {double maxGapMeter = 200, BoundingBox? finalBoundingBox}) async {
    ReadbufferSource readbufferSource = ReadbufferFile(filename);
    PbfAnalyzer result = await readSource(readbufferSource, ruleAnalyzer, maxGapMeter: maxGapMeter, finalBoundingBox: finalBoundingBox);
    readbufferSource.dispose();
    return result;
  }

  static Future<PbfAnalyzer> readSource(
    ReadbufferSource readbufferSource,
    RuleAnalyzer ruleAnalyzer, {
    double maxGapMeter = 200,
    BoundingBox? finalBoundingBox,
  }) async {
    int length = await readbufferSource.length();
    PbfAnalyzer pbfAnalyzer = PbfAnalyzer._(maxGapMeter: maxGapMeter, ruleAnalyzer: ruleAnalyzer);
    await pbfAnalyzer.readToMemory(readbufferSource, length);
    await pbfAnalyzer.analyze(finalBoundingBox);
    if (finalBoundingBox != null) {
      await pbfAnalyzer.filterByBoundingBox(finalBoundingBox);
    }
    await pbfAnalyzer.removeSuperflous();
    //    print("rule: ${ruleAnalyzer.closedWayValueinfos()}");
    //    print("rule neg: ${ruleAnalyzer.closedWayNegativeValueinfos()}");
    return pbfAnalyzer;
  }

  static Future<PbfAnalyzer> readOsmFile(String filename, RuleAnalyzer ruleAnalyzer, {double maxGapMeter = 200, BoundingBox? finalBoundingBox}) async {
    PbfAnalyzer pbfAnalyzer = PbfAnalyzer._(maxGapMeter: maxGapMeter, ruleAnalyzer: ruleAnalyzer);
    await pbfAnalyzer.readOsmToMemory(filename);
    await pbfAnalyzer.analyze(finalBoundingBox);
    if (finalBoundingBox != null) {
      await pbfAnalyzer.filterByBoundingBox(finalBoundingBox);
    }
    await pbfAnalyzer.removeSuperflous();
    return pbfAnalyzer;
  }

  Future<void> readToMemory(ReadbufferSource readbufferSource, int sourceLength) async {
    PbfReader pbfReader = PbfReader();
    await pbfReader.open(readbufferSource);
    while (readbufferSource.getPosition() < sourceLength) {
      OsmData pbfData = await pbfReader.readBlobData(readbufferSource);
      await _analyze1Block(pbfData);
    }
    boundingBox = pbfReader.calculateBounds();
  }

  Future<void> readOsmToMemory(String filename) async {
    OsmReader osmReader = OsmReader(filename);
    await osmReader.readOsmFile((OsmData pbfData) async {
      await _analyze1Block(pbfData);
    });
    boundingBox = osmReader.boundingBox;
  }

  Future<void> analyze(BoundingBox? finalBoundingBox) async {
    /// nodes are done, remove superflous nodes to free memory
    int count = _nodeHolders.length;
    _nodeHolders.removeWhere((key, value) => value.pointOfInterest.tags.isEmpty);
    nodesWithoutTagsRemoved = count - _nodeHolders.length;

    await _mergeRelationsToWays();

    WayRepair wayRepair = WayRepair(maxGapMeter);
    for (var wayholder in _wayHoldersMerged) {
      // would be nice to find the tags which requires a closed area via the render rules but for now they seem too many. Lets define a set of rules here.
      // See https://wiki.openstreetmap.org/wiki/Key:area
      if (wayholder.hasTag("building") ||
          wayholder.hasTag("landuse") ||
          wayholder.hasTag("leisure") ||
          wayholder.hasTag("natural") ||
          wayholder.hasTagValue("indoor", "corridor")) {
        wayRepair.repairClosed(wayholder, finalBoundingBox);
      } else {
        wayRepair.repairOpen(wayholder);
      }
    }
    List<Wayholder> wayholders =
        (await ways)
            .where((test) => test.hasTagValue("natural", "coastline"))
            //            .where((test) => test.closedOuters.isEmpty)
            //            .where((test) => test.openOuters.isEmpty)
            .toList();
    if (wayholders.isNotEmpty) {
      // Coastline is hardly connected. Try to connect the items now.
      Wayholder mergedWayholder = wayholders.first.cloneWith();
      wayholders.first.mergedWithOtherWay = true;
      wayholders.skip(1).forEach((coast) {
        mergedWayholder.innerWrite.addAll(coast.innerRead);
        mergedWayholder.openOutersAddAll(coast.openOutersRead);
        mergedWayholder.closedOutersAddAll(coast.closedOutersRead);
        coast.mergedWithOtherWay = true;
      });
      int count = mergedWayholder.openOutersRead.length + mergedWayholder.closedOutersRead.length;
      int counts =
          mergedWayholder.openOutersRead.fold(0, (value, element) => value + element.length) +
          mergedWayholder.closedOutersRead.fold(0, (value, element) => value + element.length);
      _log.info("Connecting and repairing coastline: $count ways with $counts nodes");
      WayConnect wayConnect = WayConnect();
      wayConnect.connect(mergedWayholder);
      //_log.info("Repairing coastline");
      wayRepair.repairClosed(mergedWayholder, boundingBox);
      int count2 = mergedWayholder.openOutersRead.length + mergedWayholder.closedOutersRead.length;
      int counts2 =
          mergedWayholder.openOutersRead.fold(0, (value, element) => value + element.length) +
          mergedWayholder.closedOutersRead.fold(0, (value, element) => value + element.length);
      LargeDataSplitter largeDataSplitter = LargeDataSplitter();
      largeDataSplitter.split(_wayHoldersMerged, mergedWayholder);
      _log.info("Repairing coastline: reduced from $count to $count2 ways with $counts2 nodes");
    }
  }

  Future<void> removeSuperflous() async {
    // remove ways with less than 2 points (this is not a way)
    int count = _wayHolders.length + _wayHoldersMerged.length;
    for (var entry in Map.from(_wayHolders).entries) {
      Wayholder wayholder = await entry.value.get();
      // if (wayholder.innerRead.isEmpty && wayholder.openOutersRead.isEmpty && wayholder.closedOutersRead.isEmpty) {
      //   _wayHolders.remove(entry.key);
      // }
    }
    for (var wayholder in List.from(_wayHoldersMerged)) {
      // if (wayholder.innerRead.isEmpty && wayholder.openOutersRead.isEmpty && wayholder.closedOutersRead.isEmpty) {
      //   _wayHoldersMerged.remove(wayholder);
      // }
    }
    closedWaysWithLessNodesRemoved = count - _wayHolders.length - _wayHoldersMerged.length;

    count = _wayHolders.length + _wayHoldersMerged.length;
    for (var entry in Map.from(_wayHolders).entries) {
      Wayholder wayholder = await entry.value.get();
      if (wayholder.innerRead.isEmpty && wayholder.openOutersRead.isEmpty && wayholder.closedOutersRead.isEmpty) {
        _wayHolders.remove(entry.key);
      } else {
        assert(wayholder.closedOutersRead.isNotEmpty || wayholder.openOutersRead.isNotEmpty, "way must have at least one outer $wayholder");
      }
    }
    for (var wayholder in List.from(_wayHoldersMerged)) {
      if (wayholder.innerRead.isEmpty && wayholder.openOutersRead.isEmpty && wayholder.closedOutersRead.isEmpty) {
        _wayHoldersMerged.remove(wayholder);
      } else {
        assert(wayholder.closedOutersRead.isNotEmpty || wayholder.openOutersRead.isNotEmpty, "way must have at least one outer $wayholder");
      }
    }
    waysWithoutNodesRemoved = count - _wayHolders.length - _wayHoldersMerged.length;

    count = _wayHolders.length;
    //    _wayHolders.removeWhere((id, Wayholder test) => test.mergedWithOtherWay);
    for (var entry in Map.from(_wayHolders).entries) {
      var id = entry.key;
      var wayHolder = await entry.value.get();
      if (wayHolder.mergedWithOtherWay) {
        _wayHolders.remove(id);
      }
    }
    waysMergedCount = count - _wayHolders.length;
  }

  Future<void> _analyze1Block(OsmData blockData) async {
    for (var osmNode in blockData.nodes) {
      PointOfInterest? pointOfInterest = converter.createNode(osmNode);
      if (pointOfInterest != null) _nodeHolders[osmNode.id] = _PoiHolder(pointOfInterest);
    }
    for (var osmWay in blockData.ways) {
      List<ILatLong> latLongs = [];
      for (var ref in osmWay.refs) {
        if (nodeNotFound.contains(ref)) {
          continue;
        }
        PointOfInterest? pointOfInterest = _searchPoi(ref);
        if (pointOfInterest != null) {
          latLongs.add(pointOfInterest.position);
        }
      }
      if (latLongs.length >= 2) {
        Way? way = converter.createWay(osmWay, [latLongs]);
        if (way != null) {
          assert(!_wayHolders.containsKey(osmWay.id));
          _wayHolders[osmWay.id] = WayholderUnion(Wayholder.fromWay(way));
        }
      }
    }
    for (var osmRelation in blockData.relations) {
      _relationReferences(osmRelation);
      relations[osmRelation.id] = osmRelation;
    }
  }

  void statistics() {
    // remove nodes that do not have any tags.
    _log.info("Removed $nodesWithoutTagsRemoved nodes because of no tags");

    _log.info("Removed $waysWithoutNodesRemoved ways because less than 2 nodes");
    _log.info("Removed $waysMergedCount ways because they have been merged to other ways");
    _log.info("Removed $closedWaysWithLessNodesRemoved closed ways because they have less than or equals 2 nodes");

    _log.info("Removed $nodesFiltered pois and $waysFiltered ways because they are out of boundary");

    _log.info("${nodeNotFound.length} nodes not found, ${wayNotFound.length} ways not found");
    _log.info("Total poi count: ${_nodeHolders.length}, total way count: ${_wayHolders.length}, total relation-way count: ${waysMerged.length}");
  }

  Future<void> _mergeRelationsToWays() async {
    WayConnect wayConnect = WayConnect();
    for (var entry in relations.entries) {
      var relation = entry.value;
      List<Wayholder> outers = [];
      List<Wayholder> inners = [];
      ILatLong? labelPosition;
      // search for outer and inner ways and for possible label position
      for (var member in relation.members) {
        if (member.role == "label") {
          PointOfInterest? pointOfInterest = _searchPoi(member.memberId);
          if (pointOfInterest != null) {
            labelPosition = pointOfInterest.position;
          }
        } else if (member.role == "outer" && member.memberType == MemberType.way) {
          Wayholder? wayHolder = await _searchWayHolder(member.memberId);
          if (wayHolder != null) {
            outers.add(wayHolder);
          }
        } else if (member.role == "inner" && member.memberType == MemberType.way) {
          Wayholder? wayHolder = await _searchWayHolder(member.memberId);
          if (wayHolder != null) {
            inners.add(wayHolder);
          }
        }
      }
      if (outers.isNotEmpty || inners.isNotEmpty) {
        Way? mergedWay = converter.createMergedWay(relation);
        if (mergedWay == null) {
          return;
        }
        Wayholder mergedWayholder = Wayholder.fromWay(mergedWay);

        for (Wayholder innerWayholder in inners) {
          assert(innerWayholder.innerRead.isEmpty);
          // more often than not the inner ways are NOT closed ways
          assert(innerWayholder.openOutersRead.isEmpty || innerWayholder.openOutersRead.length == 1);
          assert(innerWayholder.closedOutersRead.isEmpty || innerWayholder.closedOutersRead.length == 1);
          if (innerWayholder.closedOutersRead.isNotEmpty) mergedWayholder.innerWrite.add(innerWayholder.closedOutersRead.first.clone());
          if (innerWayholder.openOutersRead.isNotEmpty) mergedWayholder.innerWrite.add(innerWayholder.openOutersRead.first.clone());
          innerWayholder.mergedWithOtherWay = true;
        }
        if (labelPosition != null) {
          mergedWayholder.labelPosition = labelPosition;
        }
        // assertions to make sure the outer wayholders are as they should be
        for (Wayholder outerWayholder in outers) {
          assert(outerWayholder.innerRead.isEmpty);
          assert(outerWayholder.openOutersRead.length + outerWayholder.closedOutersRead.length == 1, outerWayholder.toStringWithoutNames());
          if (outerWayholder.closedOutersRead.isNotEmpty) mergedWayholder.closedOutersWrite.add(outerWayholder.closedOutersRead.first.clone());
          if (outerWayholder.openOutersRead.isNotEmpty) mergedWayholder.openOutersWrite.add(outerWayholder.openOutersRead.first.clone());
          outerWayholder.mergedWithOtherWay = true;
        }
        if (mergedWayholder.hasTagValue("name", "Balaton")) {
          print("found merged wayholder balaton $mergedWayholder");
        }
        wayConnect.connect(mergedWayholder);
        if (mergedWayholder.closedOutersRead.isNotEmpty || mergedWayholder.openOutersRead.isNotEmpty) {
          _wayHoldersMerged.add(mergedWayholder);
        }
      }
    }
  }

  void _relationReferences(OsmRelation osmRelation) {
    for (var member in osmRelation.members) {
      switch (member.memberType) {
        case MemberType.node:
          //          PointOfInterest? pointOfInterest = findPoi(member.memberId);
          break;
        case MemberType.way:
          //Way? way = findWay(member.memberId);
          break;
        case MemberType.relation:
          OsmRelation? relation = relations[member.memberId];
          if (relation == null) {
            // print(
            //     "Relation for $member in relation ${osmRelation.id} not found");
            //++noWayRefFound;
            //notFound.add(member);
            continue;
          }
          break;
      }
    }
  }

  PointOfInterest? _searchPoi(int id) {
    _PoiHolder? poiHolder = _nodeHolders[id];
    if (poiHolder != null) {
      poiHolder.useCount++;
      return poiHolder.pointOfInterest;
    }
    if (nodeNotFound.contains(id)) {
      return null;
    }
    //print("Poi for $ref in way $osmWay not found");
    nodeNotFound.add(id);
    return null;
  }

  Future<Wayholder?> _searchWayHolder(int id) async {
    Wayholder? wayHolder = await _wayHolders[id]?.get();
    if (wayHolder != null) {
      return wayHolder;
    }
    if (wayNotFound.contains(id)) {
      return null;
    }
    // print(
    //     "Way for $member in relation ${osmRelation.id} ${role} not found");
    wayNotFound.add(id);
    return null;
  }

  void clear() {
    _nodeHolders.clear();
    _wayHolders.clear();
    _wayHoldersMerged.clear();
    relations.clear();
    nodeNotFound.clear();
    wayNotFound.clear();
    WayholderUnion.dispose();
  }

  Future<void> filterByBoundingBox(BoundingBox boundingBox) async {
    int count = _nodeHolders.length;
    _nodeHolders.removeWhere((id, test) => !boundingBox.containsLatLong(test.pointOfInterest.position));
    nodesFiltered = count - _nodeHolders.length;

    count = _wayHoldersMerged.length;
    _wayHoldersMerged.removeWhere(
      (test) =>
          !boundingBox.intersects(test.boundingBoxCached) &&
          !boundingBox.containsBoundingBox(test.boundingBoxCached) &&
          !test.boundingBoxCached.containsBoundingBox(boundingBox),
    );
    for (Wayholder wayHolder in _wayHoldersMerged) {
      wayHolder.innerWrite.removeWhere(
        (test) =>
            !boundingBox.intersects(test.boundingBox) &&
            !boundingBox.containsBoundingBox(test.boundingBox) &&
            !test.boundingBox.containsBoundingBox(boundingBox),
      );
      wayHolder.closedOutersWrite.removeWhere(
        (test) =>
            !boundingBox.intersects(test.boundingBox) &&
            !boundingBox.containsBoundingBox(test.boundingBox) &&
            !test.boundingBox.containsBoundingBox(boundingBox),
      );
      wayHolder.openOutersWrite.removeWhere(
        (test) =>
            !boundingBox.intersects(test.boundingBox) &&
            !boundingBox.containsBoundingBox(test.boundingBox) &&
            !test.boundingBox.containsBoundingBox(boundingBox),
      );
      wayHolder.moveInnerToOuter();
    }
    count = count - _wayHoldersMerged.length;
    for (var entry in Map.from(_wayHolders).entries) {
      var id = entry.key;
      Wayholder wayHolder = await entry.value.get();
      if (!boundingBox.intersects(wayHolder.boundingBoxCached) &&
          !boundingBox.containsBoundingBox(wayHolder.boundingBoxCached) &&
          !wayHolder.boundingBoxCached.containsBoundingBox(boundingBox)) {
        _wayHolders.remove(id);
        ++count;
      }
      wayHolder.innerWrite.removeWhere(
        (test) =>
            !boundingBox.intersects(test.boundingBox) &&
            !boundingBox.containsBoundingBox(test.boundingBox) &&
            !test.boundingBox.containsBoundingBox(boundingBox),
      );
      wayHolder.closedOutersWrite.removeWhere(
        (test) =>
            !boundingBox.intersects(test.boundingBox) &&
            !boundingBox.containsBoundingBox(test.boundingBox) &&
            !test.boundingBox.containsBoundingBox(boundingBox),
      );
      wayHolder.openOutersWrite.removeWhere(
        (test) =>
            !boundingBox.intersects(test.boundingBox) &&
            !boundingBox.containsBoundingBox(test.boundingBox) &&
            !test.boundingBox.containsBoundingBox(boundingBox),
      );
      wayHolder.moveInnerToOuter();
    }
    waysFiltered = count;
  }
}

//////////////////////////////////////////////////////////////////////////////

class _PoiHolder {
  final PointOfInterest pointOfInterest;

  int useCount = 0;

  _PoiHolder(this.pointOfInterest);
}

//////////////////////////////////////////////////////////////////////////////

class PbfAnalyzerConverter {
  PointOfInterest? createNode(OsmNode osmNode) {
    List<Tag> tags = Tag.from(osmNode.tags);
    int layer = findLayer(tags);
    modifyNodeTags(osmNode, tags);
    // even with no tags the node may belong to a relation, so keep it
    // convert and round the latlongs to 6 digits after the decimal point. This
    // helps determining if ways are closed.
    LatLong latLong = LatLong(_roundDouble(osmNode.latitude, 6), _roundDouble(osmNode.longitude, 6));
    PointOfInterest pointOfInterest = PointOfInterest(layer, tags, latLong);
    return pointOfInterest;
  }

  Way? createWay(OsmWay osmWay, List<List<ILatLong>> latLongs) {
    List<Tag> tags = Tag.from(osmWay.tags);
    int layer = findLayer(tags);
    modifyWayTags(osmWay, tags);
    // even with no tags the way may belong to a relation, so keep it
    ILatLong? labelPosition;
    Way way = Way(layer, tags, latLongs, labelPosition);
    return way;
  }

  Way? createMergedWay(OsmRelation relation) {
    List<Tag> tags = Tag.from(relation.tags);
    int layer = findLayer(tags);
    modifyRelationTags(relation, tags);
    // topmost structure, if we have no tags, we cannot render anything
    if (tags.isEmpty) return null;
    ILatLong? labelPosition;
    Way way = Way(layer, tags, [], labelPosition);
    return way;
  }

  double _roundDouble(double value, int places) {
    num mod = math.pow(10.0, places);
    return ((value * mod).round().toDouble() / mod);
  }

  void modifyNodeTags(OsmNode node, List<Tag> tags) {}

  void modifyWayTags(OsmWay way, List<Tag> tags) {}

  void modifyRelationTags(OsmRelation relation, List<Tag> tags) {}

  int findLayer(List<Tag> tags) {
    Tag? layerTag = tags.firstWhereOrNull((test) => test.key == "layer" && test.value != null);
    int layer = 0;
    if (layerTag != null) {
      layer = int.tryParse(layerTag.value!) ?? 0;
      tags.remove(layerTag);
    }
    // layers from -5 to 10 are allowed, will be stored as 0..15 in the file (4 bit)
    if (layer < -5) layer = -5;
    if (layer > 10) layer = 10;
    return layer;
  }
}

//////////////////////////////////////////////////////////////////////////////

class WayholderUnion {
  Wayholder? _wayholder;

  _Temp? _temp;

  static String? _filename;

  static SinkWithCounter? _sinkWithCounter;

  static ReadbufferFile? _readbufferFile;

  static int _count = 0;

  WayholderUnion(this._wayholder) {
    ++_count;
    if (_count < 10000) {
      return;
    }
    if (_wayholder!.sumCount() > 1000000) {
      // do not send large wayholders to file
      return;
    }
    _toFile();
  }

  void _toFile() {
    assert(_wayholder != null);
    if (_temp == null) {
      CacheFile cacheFile = CacheFile();
      Uint8List uint8list = cacheFile.toFile(_wayholder!);
      if (uint8list.length > 10000000) {
        print("Lenght: ${uint8list.length} for ${_wayholder!.toString()}");
      }
      _filename ??= "temp_${DateTime.timestamp().millisecondsSinceEpoch}.bin";
      _sinkWithCounter ??= SinkWithCounter(File(_filename!).openWrite());
      int pos = _sinkWithCounter!.written;
      _sinkWithCounter!.add(uint8list);
      _temp = _Temp(pos: pos, length: uint8list.length);
    }
    _wayholder = null;
    --_count;
  }

  Future<Wayholder> _fromFile() async {
    assert(_temp != null);
    _readbufferFile ??= ReadbufferFile(_filename!, capacity: 10);
    await _sinkWithCounter!.flush();
    Readbuffer readbuffer = await _readbufferFile!.readFromFileAt(_temp!.pos, _temp!.length);
    Uint8List uint8list = readbuffer.getBuffer(0, _temp!.length);
    CacheFile cacheFile = CacheFile();
    assert(uint8list.length == _temp!.length);
    _wayholder = cacheFile.fromFile(uint8list);
    ++_count;
    return _wayholder!;
  }

  Future<Wayholder> get() async {
    if (_wayholder != null) return _wayholder!;
    return _fromFile();
  }

  static void dispose() {
    _readbufferFile?.dispose();
    _readbufferFile = null;
    _sinkWithCounter?.close().then((a) {
      if (_filename != null) {
        try {
          File(_filename!).deleteSync();
        } catch (_) {
          // do nothing
        } finally {
          _filename = null;
        }
      }
    });
    _sinkWithCounter = null;
    _count = 0;
  }
}

//////////////////////////////////////////////////////////////////////////////

class _Temp {
  final int pos;

  final int length;

  _Temp({required this.pos, required this.length});
}
