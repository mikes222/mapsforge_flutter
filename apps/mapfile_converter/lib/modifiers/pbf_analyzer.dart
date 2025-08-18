import 'dart:io';
import 'dart:typed_data';

import 'package:dart_common/buffer.dart';
import 'package:dart_common/model.dart';
import 'package:dart_mapfile/mapfile.dart';
import 'package:logging/logging.dart';
import 'package:mapfile_converter/modifiers/cachefile.dart';
import 'package:mapfile_converter/modifiers/default_osm_primitive_converter.dart';
import 'package:mapfile_converter/modifiers/large_data_splitter.dart';
import 'package:mapfile_converter/modifiers/way_connect.dart';
import 'package:mapfile_converter/osm/osm_data.dart';
import 'package:mapfile_converter/pbf/pbf_reader.dart';

import '../modifiers/way_repair.dart';
import '../osm/osm_reader.dart';

/// Reads data from a pbf file and converts it to PointOfInterest and Way objects
/// so that they are usable in mapsforge. By implementing your own version of
/// [PbfAnalyzerConverter] you can control the behavior of the conversion from
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

  final DefaultOsmPrimitiveConverter converter;

  List<PointOfInterest> get pois => _nodeHolders.values.map((e) => e.pointOfInterest).toList();

  Future<List<Wayholder>> get ways async {
    List<Wayholder> result = [];
    for (var e in _wayHolders.values) {
      Wayholder wayholder = await e.get();
      result.add(wayholder);
    }
    return result;
  }

  Future<List<Wayholder>> get waysCoastline async {
    List<Wayholder> result = [];
    for (var e in _wayHolders.values) {
      if (e.coastLine) {
        Wayholder wayholder = await e.get();
        result.add(wayholder);
      }
    }
    return result;
  }

  List<Wayholder> get waysMerged => _wayHoldersMerged;

  PbfAnalyzer._({this.maxGapMeter = 200, required this.converter});

  static Future<PbfAnalyzer> readFile(
    String filename,
    DefaultOsmPrimitiveConverter converter, {
    double maxGapMeter = 200,
    BoundingBox? finalBoundingBox,
  }) async {
    ReadbufferSource readbufferSource = ReadbufferFile(filename);
    PbfAnalyzer result = await readSource(readbufferSource, converter, maxGapMeter: maxGapMeter, finalBoundingBox: finalBoundingBox);
    readbufferSource.dispose();
    return result;
  }

  static Future<PbfAnalyzer> readSource(
    ReadbufferSource readbufferSource,
    DefaultOsmPrimitiveConverter converter, {
    double maxGapMeter = 200,
    BoundingBox? finalBoundingBox,
  }) async {
    int length = await readbufferSource.length();
    PbfAnalyzer pbfAnalyzer = PbfAnalyzer._(maxGapMeter: maxGapMeter, converter: converter);
    await pbfAnalyzer.readToMemory(readbufferSource, length);
    // analyze the whole area before filtering the bounding box, we want closed ways wherever possible
    await pbfAnalyzer.analyze();
    if (finalBoundingBox != null) {
      await pbfAnalyzer.filterByBoundingBox(finalBoundingBox);
    }
    await pbfAnalyzer.removeSuperflous();
    //    print("rule: ${ruleAnalyzer.closedWayValueinfos()}");
    //    print("rule neg: ${ruleAnalyzer.closedWayNegativeValueinfos()}");
    return pbfAnalyzer;
  }

  static Future<PbfAnalyzer> readOsmFile(
    String filename,
    DefaultOsmPrimitiveConverter converter, {
    double maxGapMeter = 200,
    BoundingBox? finalBoundingBox,
  }) async {
    PbfAnalyzer pbfAnalyzer = PbfAnalyzer._(maxGapMeter: maxGapMeter, converter: converter);
    await pbfAnalyzer.readOsmToMemory(filename);
    // analyze the whole area before filtering the bounding box, we want closed ways wherever possible
    await pbfAnalyzer.analyze();
    if (finalBoundingBox != null) {
      await pbfAnalyzer.filterByBoundingBox(finalBoundingBox);
    }
    await pbfAnalyzer.removeSuperflous();
    return pbfAnalyzer;
  }

  Future<void> readToMemory(ReadbufferSource readbufferSource, int sourceLength) async {
    readbufferSource.freeRessources();
    IsolatePbfReader pbfReader = await IsolatePbfReader.create(readbufferSource: readbufferSource, sourceLength: sourceLength);
    List<Future> futures = [];
    while (true) {
      OsmData? pbfData = await pbfReader.readBlobData();
      if (pbfData == null) break;
      futures.add(_analyze1Block(pbfData));
    }
    await Future.wait(futures);
    boundingBox = await pbfReader.calculateBounds();
    pbfReader.dispose();
  }

  Future<void> readOsmToMemory(String filename) async {
    OsmReader osmReader = OsmReader(filename);
    await osmReader.readOsmFile((OsmData pbfData) async {
      await _analyze1Block(pbfData);
    });
    boundingBox = osmReader.boundingBox;
  }

  Future<void> analyze() async {
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
        wayRepair.repairClosed(wayholder, boundingBox);
      } else {
        wayRepair.repairOpen(wayholder);
      }
    }
    List<Wayholder> wayholders = await waysCoastline;
    //    wayholders = wayholders.where((test) => test.hasTagValue("natural", "coastline")).toList();
    if (wayholders.isNotEmpty) {
      // Coastline is hardly connected. Try to connect the items now.
      Wayholder mergedWayholder = wayholders.first.cloneWith();
      wayholders.first.mergedWithOtherWay = true;
      wayholders.skip(1).forEach((coast) {
        mergedWayholder.innerAddAll(coast.innerRead.map((toElement) => toElement.clone()).toList());
        mergedWayholder.openOutersAddAll(coast.openOutersRead.map((toElement) => toElement.clone()).toList());
        mergedWayholder.closedOutersAddAll(coast.closedOutersRead.map((toElement) => toElement.clone()).toList());
        coast.mergedWithOtherWay = true;
      });
      int count = mergedWayholder.openOutersRead.length + mergedWayholder.closedOutersRead.length;
      int counts =
          mergedWayholder.openOutersRead.fold(0, (value, element) => value + element.length) +
          mergedWayholder.closedOutersRead.fold(0, (value, element) => value + element.length);
      //_log.info("Connecting and repairing coastline: $count ways with $counts nodes");
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
      if (count2 != count || counts2 != counts) {
        _log.info("Connecting and repairing coastline: from $count to $count2 ways and from $counts to $counts2 nodes");
      }
    }
  }

  Future<void> removeSuperflous() async {
    // remove ways with less than 2 points (this is not a way)
    int count = _wayHolders.length + _wayHoldersMerged.length;
    //for (var entry in Map.from(_wayHolders).entries) {
    //Wayholder wayholder = await entry.value.get();
    // if (wayholder.innerRead.isEmpty && wayholder.openOutersRead.isEmpty && wayholder.closedOutersRead.isEmpty) {
    //   _wayHolders.remove(entry.key);
    // }
    //}
    //for (var wayholder in List.from(_wayHoldersMerged)) {
    // if (wayholder.innerRead.isEmpty && wayholder.openOutersRead.isEmpty && wayholder.closedOutersRead.isEmpty) {
    //   _wayHoldersMerged.remove(wayholder);
    // }
    //}
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
          assert(way.latLongs.isNotEmpty);
          assert(way.latLongs[0].length >= 2);
          _wayHolders[osmWay.id] = WayholderUnion(Wayholder.fromWay(way));
        }
      }
    }
    for (var osmRelation in blockData.relations) {
      assert(!relations.containsKey(osmRelation.id));
      relations[osmRelation.id] = osmRelation;
    }
  }

  void statistics() {
    // remove nodes that do not have any tags.
    if (nodesWithoutTagsRemoved > 0) _log.info("Removed $nodesWithoutTagsRemoved nodes because of no tags");

    if (waysWithoutNodesRemoved > 0) _log.info("Removed $waysWithoutNodesRemoved ways because less than 2 nodes");
    if (waysMergedCount > 0) _log.info("Removed $waysMergedCount ways because they have been merged to other ways");
    if (closedWaysWithLessNodesRemoved > 0) _log.info("Removed $closedWaysWithLessNodesRemoved closed ways because they have less than or equals 2 nodes");

    if (nodesFiltered + waysFiltered > 0) _log.info("Removed $nodesFiltered pois and $waysFiltered ways because they are out of boundary");

    _log.info("${nodeNotFound.length} nodes not found, ${wayNotFound.length} ways not found");
    _log.info("Total poi count: ${_nodeHolders.length}, total way count: ${_wayHolders.length}, total relation-way count: ${waysMerged.length}");
  }

  Future<void> _mergeRelationsToWays() async {
    WayConnect wayConnect = WayConnect();
    for (OsmRelation osmRelation in relations.values) {
      List<Wayholder> outers = [];
      List<Wayholder> inners = [];
      ILatLong? labelPosition;
      // search for outer and inner ways and for possible label position
      for (var member in osmRelation.members) {
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
        Way? mergedWay = converter.createMergedWay(osmRelation);
        if (mergedWay == null) {
          continue;
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
        wayConnect.connect(mergedWayholder);
        if (mergedWayholder.closedOutersRead.isNotEmpty || mergedWayholder.openOutersRead.isNotEmpty) {
          _wayHoldersMerged.add(mergedWayholder);
        }
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
        continue;
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

/// Holds one way in memory or holds a reference to one way in a temp-file
class WayholderUnion {
  Wayholder? _wayholder;

  _Temp? _temp;

  bool coastLine = false;

  static String? _filename;

  static SinkWithCounter? _sinkWithCounter;

  static ReadbufferFile? _readbufferFile;

  static int _count = 0;

  WayholderUnion(Wayholder wayholder) {
    ++_count;
    if (wayholder.hasTagValue("natural", "coastline")) {
      coastLine = true;
    }
    _wayholder = wayholder;

    if (_count < 5000) {
      return;
    }
    if (_wayholder!.nodeCount() <= 5) {
      // keep small ways in memory
      return;
    }
    if (_wayholder!.nodeCount() > 1000000) {
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
      _filename ??= "ways_${DateTime.timestamp().millisecondsSinceEpoch}.tmp";
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
    _readbufferFile ??= ReadbufferFile(_filename!);
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

/// Reference to a way in the tempfile
class _Temp {
  final int pos;

  final int length;

  _Temp({required this.pos, required this.length});
}
