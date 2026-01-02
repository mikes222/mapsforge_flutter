import 'dart:collection';

import 'package:logging/logging.dart';
import 'package:mapfile_converter/modifiers/default_osm_primitive_converter.dart';
import 'package:mapfile_converter/modifiers/large_data_splitter.dart';
import 'package:mapfile_converter/modifiers/poiholder_file_collection.dart';
import 'package:mapfile_converter/modifiers/way_connect.dart';
import 'package:mapfile_converter/modifiers/wayholder_id_file_collection.dart';
import 'package:mapfile_converter/osm/osm_data.dart';
import 'package:mapfile_converter/pbf/pbf_reader.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

import '../modifiers/way_repair.dart';
import '../osm/osm_reader.dart';

/// Reads data from a pbf file and converts it to PointOfInterest and Way objects
/// so that they are usable in mapsforge. By implementing your own version of
/// [PbfAnalyzerConverter] you can control the behavior of the conversion from
/// OSM data to PointOfInterest and Way objects.
class PbfAnalyzer {
  final _log = Logger('PbfAnalyzer');

  final double maxGapMeter;

  final HashMap<int, ILatLong> _positions = HashMap();

  late final PoiholderFileCollection _nodeHolders;

  late final WayholderIdFileCollection _wayHolders;

  final List<Wayholder> _wayHoldersMerged = [];

  final bool quiet;

  final List<OsmRelation> _relations = [];

  Set<int> nodeNotFound = {};

  int _nodeNotFoundCount = 0;

  int nodesWithoutTagsRemoved = 0;

  int waysWithoutNodesRemoved = 0;

  int closedWaysWithLessNodesRemoved = 0;

  int waysMergedCount = 0;

  int nodesFiltered = 0;

  int waysFiltered = 0;

  BoundingBox? boundingBox;

  BoundingBox? finalBoundingBox;

  final DefaultOsmPrimitiveConverter converter;

  PoiholderFileCollection get nodes => _nodeHolders;

  WayholderIdFileCollection ways() => _wayHolders;

  List<Wayholder> get waysMerged => _wayHoldersMerged;

  PbfAnalyzer._({this.maxGapMeter = 200, required this.converter, this.quiet = false, this.finalBoundingBox}) {
    _wayHolders = WayholderIdFileCollection(filename: "analyzer_ways_${DateTime.timestamp().millisecondsSinceEpoch}.tmp");
    _nodeHolders = PoiholderFileCollection(filename: "analyzer_nodes_${DateTime.timestamp().millisecondsSinceEpoch}.tmp", spillBatchSize: 10000);
  }

  static Future<PbfAnalyzer> readFile(
    String filename,
    DefaultOsmPrimitiveConverter converter, {
    double maxGapMeter = 200,
    BoundingBox? finalBoundingBox,
    bool quiet = false,
  }) async {
    ReadbufferSource readbufferSource = createReadbufferSource(filename);
    PbfAnalyzer result = await readSource(readbufferSource, converter, maxGapMeter: maxGapMeter, finalBoundingBox: finalBoundingBox, quiet: quiet);
    readbufferSource.dispose();
    return result;
  }

  static Future<PbfAnalyzer> readSource(
    ReadbufferSource readbufferSource,
    DefaultOsmPrimitiveConverter converter, {
    double maxGapMeter = 200,
    BoundingBox? finalBoundingBox,
    bool quiet = false,
  }) async {
    int length = await readbufferSource.length();
    PbfAnalyzer pbfAnalyzer = PbfAnalyzer._(maxGapMeter: maxGapMeter, converter: converter, quiet: quiet, finalBoundingBox: finalBoundingBox);
    await pbfAnalyzer.readToMemory(readbufferSource, length);
    // analyze the whole area before filtering the bounding box, we want closed ways wherever possible
    await pbfAnalyzer.analyze();
    if (finalBoundingBox != null) {
      // we are filtering while importing, this is not necessary anymore
      //await pbfAnalyzer.filterByBoundingBox(finalBoundingBox);
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
    bool quiet = false,
  }) async {
    PbfAnalyzer pbfAnalyzer = PbfAnalyzer._(maxGapMeter: maxGapMeter, converter: converter, quiet: quiet, finalBoundingBox: finalBoundingBox);
    await pbfAnalyzer.readOsmToMemory(filename);
    // analyze the whole area before filtering the bounding box, we want closed ways wherever possible
    await pbfAnalyzer.analyze();
    if (finalBoundingBox != null) {
      // we are filtering while importing, this is not necessary anymore
      //await pbfAnalyzer.filterByBoundingBox(finalBoundingBox);
    }
    await pbfAnalyzer.removeSuperflous();
    return pbfAnalyzer;
  }

  Future<void> readToMemory(ReadbufferSource readbufferSource, int sourceLength) async {
    await readbufferSource.freeRessources();
    IPbfReader pbfReader = await IsolatePbfReader.create(readbufferSource: readbufferSource, sourceLength: sourceLength);
    List<int> positions = await pbfReader.getBlobPositions();
    List<Future> futures = [];
    for (int position in positions) {
      OsmData? pbfData = await pbfReader.readBlobData(position);
      if (pbfData == null) break;
      futures.add(_analyze1Block(pbfData));
      if (futures.length > 20) {
        await Future.wait(futures);
        futures.clear();
      }
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
    //_nodeHolders.removeWhere((nodeholder) => nodeholder.tagholderCollection.isEmpty);
    nodesWithoutTagsRemoved = count - _nodeHolders.length;

    await _mergeRelationsToWays();
    // we do not need the positions-map anymore
    _positions.clear();

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
    Map<int, Wayholder> wayholders = await _wayHolders.getAllCoastline();
    if (wayholders.isNotEmpty) {
      Map<int, Wayholder> toChange = {};
      // Coastline is hardly connected. Try to connect the items now.
      Wayholder mergedWayholder = wayholders.entries.first.value.cloneWith();
      if (!wayholders.entries.first.value.mergedWithOtherWay) {
        wayholders.entries.first.value.mergedWithOtherWay = true;
        toChange[wayholders.entries.first.key] = wayholders.entries.first.value;
      }
      wayholders.entries.skip(1).forEach((entry) {
        Wayholder coast = entry.value;
        mergedWayholder.innerAddAll(coast.innerRead.map((toElement) => toElement.clone()).toList());
        mergedWayholder.openOutersAddAll(coast.openOutersRead.map((toElement) => toElement.clone()).toList());
        mergedWayholder.closedOutersAddAll(coast.closedOutersRead.map((toElement) => toElement.clone()).toList());
        if (!coast.mergedWithOtherWay) {
          coast.mergedWithOtherWay = true;
          toChange[entry.key] = coast;
        }
      });
      int count = mergedWayholder.openOutersLength() + mergedWayholder.closedOutersLength();
      int counts =
          mergedWayholder.openOutersRead.fold(0, (value, element) => value + element.length) +
          mergedWayholder.closedOutersRead.fold(0, (value, element) => value + element.length);
      //_log.info("Connecting and repairing coastline: $count ways with $counts nodes");
      WayConnect wayConnect = WayConnect();
      wayConnect.connect(mergedWayholder);
      //_log.info("Repairing coastline");
      wayRepair.repairClosed(mergedWayholder, boundingBox);
      int count2 = mergedWayholder.openOutersLength() + mergedWayholder.closedOutersLength();
      int counts2 =
          mergedWayholder.openOutersRead.fold(0, (value, element) => value + element.length) +
          mergedWayholder.closedOutersRead.fold(0, (value, element) => value + element.length);
      LargeDataSplitter largeDataSplitter = LargeDataSplitter();
      largeDataSplitter.split(_wayHoldersMerged, mergedWayholder);
      if (count2 != count || counts2 != counts) {
        _log.info("Connecting and repairing coastline: from $count to $count2 ways and from $counts to $counts2 nodes");
      }
      for (var entry in toChange.entries) {
        _wayHolders.change(entry.key, entry.value);
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
    for (Wayholder wayholder in List.from(_wayHoldersMerged)) {
      if (wayholder.innerIsEmpty() && wayholder.openOutersIsEmpty() && wayholder.closedOutersIsEmpty()) {
        _wayHoldersMerged.remove(wayholder);
      } else {
        assert(wayholder.closedOutersIsNotEmpty() || wayholder.openOutersIsNotEmpty(), "way must have at least one outer $wayholder");
      }
    }
    waysWithoutNodesRemoved = count - _wayHolders.length - _wayHoldersMerged.length;

    count = _wayHolders.length;
    Map map = await _wayHolders.getAllMergedWithOtherWay();
    map.forEach((key, wayholder) {
      _wayHolders.remove(key);
    });
    // // for security reasons remove all wayholder which doe not have any ways
    // if (wayholder.innerIsEmpty() && wayholder.openOutersIsEmpty() && wayholder.closedOutersIsEmpty()) {
    //   toRemove.add(key);
    // } else {
    //   assert(wayholder.closedOutersIsNotEmpty() || wayholder.openOutersIsNotEmpty(), "way must have at least one outer $wayholder");
    // }
    waysMergedCount = count - _wayHolders.length;
  }

  Future<void> _analyze1Block(OsmData blockData) async {
    for (var osmNode in blockData.nodes) {
      _positions[osmNode.id] = osmNode.latLong;
      if (!quiet && _positions.length % 10000000 == 0) {
        _log.info("Pois read: ${_positions.length}");
      }
      // do not store a node without tags, we cannot render anything
      if (osmNode.tags.isEmpty) continue;
      Poiholder poiholder = converter.createNodeholder(osmNode);
      if (poiholder.tagholderCollection.isEmpty) continue;
      if (finalBoundingBox != null) {
        if (!finalBoundingBox!.containsLatLong(poiholder.position)) {
          ++nodesFiltered;
          continue;
        }
      }
      _nodeHolders.add(poiholder);
    }
    for (OsmWay osmWay in blockData.ways) {
      List<ILatLong> latLongs = [];
      for (var ref in osmWay.refs) {
        ILatLong? position = _searchPosition(ref);
        if (position != null) {
          latLongs.add(position);
        }
      }
      if (latLongs.length < 2) continue;

      Wayholder wayholder = converter.createWayholder(osmWay);
      Waypath waypath = Waypath(path: latLongs);
      if (waypath.isClosedWay()) {
        wayholder.closedOutersAdd(waypath);
      } else {
        wayholder.openOutersAdd(waypath);
      }
      if (finalBoundingBox != null) {
        if (!finalBoundingBox!.containsBoundingBox(wayholder.boundingBoxCached) && !finalBoundingBox!.intersects(wayholder.boundingBoxCached)) {
          ++waysFiltered;
          continue;
        }
      }
      _wayHolders.add(osmWay.id, wayholder);
      if (!quiet && _wayHolders.length % 1000000 == 0) {
        _log.info("Ways read: ${_wayHolders.length}");
      }
    }
    for (OsmRelation osmRelation in blockData.relations) {
      _relations.add(osmRelation);
      if (!quiet && _relations.length % 1000000 == 0) {
        _log.info("Relations read: ${_relations.length}");
      }
    }
  }

  void statistics() {
    // remove nodes that do not have any tags.
    if (nodesWithoutTagsRemoved > 0) _log.info("Removed $nodesWithoutTagsRemoved nodes because of no tags");

    if (waysWithoutNodesRemoved > 0) _log.info("Removed $waysWithoutNodesRemoved ways because less than 2 nodes");
    if (waysMergedCount > 0) _log.info("Removed $waysMergedCount ways because they have been merged to other ways");
    if (closedWaysWithLessNodesRemoved > 0) _log.info("Removed $closedWaysWithLessNodesRemoved closed ways because they have less than or equals 2 nodes");

    if (nodesFiltered + waysFiltered > 0) _log.info("Removed $nodesFiltered pois and $waysFiltered ways because they are out of boundary");

    _log.info("${nodeNotFound.length} ($_nodeNotFoundCount) nodes not found, ${_wayHolders.wayNotFound.length} ways not found");
    _log.info("Total poi count: ${_nodeHolders.length}, total way count: ${_wayHolders.length}, total relation-way count: ${waysMerged.length}");
  }

  Future<void> _mergeRelationsToWays() async {
    Map<int, Wayholder> toChange = {};
    WayConnect wayConnect = WayConnect();
    for (OsmRelation osmRelation in _relations) {
      Map<int, Wayholder> outers = {};
      Map<int, Wayholder> inners = {};
      ILatLong? labelPosition;
      // search for outer and inner ways and for possible label position
      for (var member in osmRelation.members) {
        if (member.role == "label") {
          ILatLong? position = _searchPosition(member.memberId);
          if (position != null) {
            labelPosition = position;
          }
        } else if (member.role == "outer" && member.memberType == MemberType.way) {
          Wayholder? wayHolder = await _wayHolders.tryGet(member.memberId);
          if (wayHolder != null) {
            outers[member.memberId] = wayHolder;
          }
        } else if (member.role == "inner" && member.memberType == MemberType.way) {
          Wayholder? wayHolder = await _wayHolders.tryGet(member.memberId);
          if (wayHolder != null) {
            inners[member.memberId] = wayHolder;
          }
        } else {
          //_log.warning("OsmRelation has an unknown member $member");
        }
      }
      if (outers.isNotEmpty || inners.isNotEmpty) {
        Wayholder? mergedWay = converter.createMergedWayholder(osmRelation);
        if (mergedWay == null) {
          continue;
        }
        if (labelPosition != null) {
          mergedWay.labelPosition = labelPosition;
        }
        for (var entry in inners.entries) {
          Wayholder innerWayholder = entry.value;
          assert(innerWayholder.innerIsEmpty());
          // more often than not the inner ways are NOT closed ways
          assert(innerWayholder.openOutersIsEmpty() || innerWayholder.openOutersLength() == 1);
          assert(innerWayholder.closedOutersIsEmpty() || innerWayholder.closedOutersLength() == 1);
          if (innerWayholder.closedOutersIsNotEmpty()) mergedWay.innerAdd(innerWayholder.closedOutersRead.first.clone());
          if (innerWayholder.openOutersIsNotEmpty()) mergedWay.innerAdd(innerWayholder.openOutersRead.first.clone());
          if (!innerWayholder.mergedWithOtherWay) {
            innerWayholder.mergedWithOtherWay = true;
            toChange[entry.key] = innerWayholder;
          }
        }
        // assertions to make sure the outer wayholders are as they should be
        for (var entry in outers.entries) {
          Wayholder outerWayholder = entry.value;
          assert(outerWayholder.innerIsEmpty());
          assert(outerWayholder.openOutersLength() + outerWayholder.closedOutersLength() == 1, outerWayholder.toStringWithoutNames());
          if (outerWayholder.closedOutersIsNotEmpty()) mergedWay.closedOutersAdd(outerWayholder.closedOutersRead.first.clone());
          if (outerWayholder.openOutersIsNotEmpty()) mergedWay.openOutersAdd(outerWayholder.openOutersRead.first.clone());
          if (!outerWayholder.mergedWithOtherWay) {
            outerWayholder.mergedWithOtherWay = true;
            toChange[entry.key] = outerWayholder;
          }
        }
        mergedWay.moveInnerToOuter();
        wayConnect.connect(mergedWay);
        if (mergedWay.closedOutersIsNotEmpty() || mergedWay.openOutersIsNotEmpty()) {
          _wayHoldersMerged.add(mergedWay);
        }
      }
    }
    for (var entry in toChange.entries) {
      _wayHolders.change(entry.key, entry.value);
    }
  }

  ILatLong? _searchPosition(int id) {
    ILatLong? position = _positions[id];
    if (position != null) {
      //nodeHolder.useCount++;
      return position;
    }
    ++_nodeNotFoundCount;
    if (nodeNotFound.contains(id)) {
      return null;
    }
    //print("Poi for $ref in way $osmWay not found");
    if (nodeNotFound.length < 10000) {
      nodeNotFound.add(id);
    }
    return null;
  }

  void clear() {
    _nodeHolders.dispose();
    _wayHolders.dispose();
    _wayHoldersMerged.clear();
    _relations.clear();
    nodeNotFound.clear();
  }

  Future<void> filterByBoundingBox(BoundingBox boundingBox) async {
    int count = _nodeHolders.length;
    await _nodeHolders.removeWhere((nodeHolder) => !boundingBox.containsLatLong(nodeHolder.position));
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
    List<int> toRemove = [];
    Map<int, Wayholder> toChange = {};
    await _wayHolders.forEach((key, wayholder) {
      if (!boundingBox.intersects(wayholder.boundingBoxCached) &&
          !boundingBox.containsBoundingBox(wayholder.boundingBoxCached) &&
          !wayholder.boundingBoxCached.containsBoundingBox(boundingBox)) {
        toRemove.add(key);
        ++count;
        return;
      }
      int c = wayholder.pathCount();
      wayholder.innerWrite.removeWhere(
        (test) =>
            !boundingBox.intersects(test.boundingBox) &&
            !boundingBox.containsBoundingBox(test.boundingBox) &&
            !test.boundingBox.containsBoundingBox(boundingBox),
      );
      wayholder.closedOutersWrite.removeWhere(
        (test) =>
            !boundingBox.intersects(test.boundingBox) &&
            !boundingBox.containsBoundingBox(test.boundingBox) &&
            !test.boundingBox.containsBoundingBox(boundingBox),
      );
      wayholder.openOutersWrite.removeWhere(
        (test) =>
            !boundingBox.intersects(test.boundingBox) &&
            !boundingBox.containsBoundingBox(test.boundingBox) &&
            !test.boundingBox.containsBoundingBox(boundingBox),
      );
      wayholder.moveInnerToOuter();
      if (c != wayholder.pathCount()) toChange[key] = wayholder;
    });
    for (var key in toRemove) {
      _wayHolders.remove(key);
    }
    for (var entry in toChange.entries) {
      _wayHolders.change(entry.key, entry.value);
    }
    waysFiltered = count;
  }
}

//////////////////////////////////////////////////////////////////////////////
