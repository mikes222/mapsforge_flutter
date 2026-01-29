import 'dart:collection';

import 'package:logging/logging.dart';
import 'package:mapfile_converter/filter/large_data_splitter.dart';
import 'package:mapfile_converter/filter/way_connect.dart';
import 'package:mapfile_converter/modifiers/default_osm_primitive_converter.dart';
import 'package:mapfile_converter/modifiers/wayholder_id_file_collection.dart';
import 'package:mapfile_converter/osm/osm_data.dart';
import 'package:mapfile_converter/pbf/pbf_reader.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

import '../filter/way_repair.dart';

/// Reads data from a pbf file and converts it to PointOfInterest and Way objects
/// so that they are usable in mapsforge. By implementing your own version of
/// [PbfAnalyzerConverter] you can control the behavior of the conversion from
/// OSM data to PointOfInterest and Way objects.
class PbfAnalyzer {
  static final _log = Logger('PbfAnalyzer');

  final HashMap<int, int> _positions = HashMap();

  late final IPoiholderCollection _nodeHolders;

  late final WayholderIdFileCollection _wayHolders;

  final List<OsmRelation> _relations = [];

  final List<Wayholder> _wayHoldersMerged = [];

  final DefaultOsmPrimitiveConverter converter;

  final bool quiet;

  BoundingBox? boundingBox;

  BoundingBox? finalBoundingBox;

  int totalNodeCount = 0;

  int totalWayCount = 0;

  int totalRelationCount = 0;

  /// The nodes which were not found in the pbf file.
  Set<int> nodeNotFound = {};

  /// Total number of nodes which were not found in the pbf file. Each unsuccessful search counts even if we search for the same node multiple times
  int _nodeNotFoundCount = 0;

  /// number of nodes removed because they have no tags
  int nodesWithoutTagsRemoved = 0;

  /// number of ways removed because they have no tags
  /// todo
  int waysWithoutTagsRemoved = 0;

  /// wayholders removed because they have no ways
  int waysWithoutWaysRemoved = 0;

  /// ways removed because we have too less nodes
  int waysTooLessNodesRemoved = 0;

  /// number of ways merged to other ways
  int waysMergedCount = 0;

  /// number of pois removed because they are out of boundary
  int nodesFiltered = 0;

  /// number of ways removed because they are out of boundary
  int waysFiltered = 0;

  int nextTimestamp = 0;

  IPoiholderCollection get nodes => _nodeHolders;

  WayholderIdFileCollection get ways => _wayHolders;

  List<Wayholder> get waysMerged => _wayHoldersMerged;

  List<OsmRelation> get relations => _relations;

  PbfAnalyzer._({required this.converter, this.quiet = false, this.finalBoundingBox, int spillBatchSize = 10000}) {
    _wayHolders = WayholderIdFileCollection(filename: "analyzer_ways_${HolderCollectionFactory.randomId}.tmp", spillBatchSize: spillBatchSize);
    _nodeHolders = HolderCollectionFactory().createPoiholderCollection("analyzer");
  }

  static Future<PbfAnalyzer> readSource(
    DefaultOsmPrimitiveConverter converter, {
    BoundingBox? finalBoundingBox,
    bool quiet = false,
    int spillBatchSize = 10000,
    required IPbfReader pbfReader,
    required int length,
  }) async {
    PbfAnalyzer pbfAnalyzer = PbfAnalyzer._(converter: converter, quiet: quiet, finalBoundingBox: finalBoundingBox, spillBatchSize: spillBatchSize);
    await pbfAnalyzer.readToMemory(length, pbfReader);
    return pbfAnalyzer;
  }

  Future<void> readToMemory(int sourceLength, IPbfReader pbfReader) async {
    nextTimestamp = DateTime.now().millisecondsSinceEpoch + 1000 * 60 * 2;

    List<Future> futures = [];
    while (true) {
      OsmData? pbfData = await pbfReader.readNextBlobData();
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

  Future<void> analyze(double maxGapMeter) async {
    /// nodes are done, remove superflous nodes to free memory
    int count = _nodeHolders.length;
    //_nodeHolders.removeWhere((nodeholder) => nodeholder.tagholderCollection.isEmpty);
    WayConnect wayConnect = WayConnect();
    await mergeRelationsToWays(wayConnect);
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
    int count = _wayHolders.length + _wayHoldersMerged.length;
    _wayHoldersMerged.removeWhere((wayholder) => wayholder.innerIsEmpty() && wayholder.openOutersIsEmpty() && wayholder.closedOutersIsEmpty());
    waysWithoutWaysRemoved = count - _wayHolders.length - _wayHoldersMerged.length;

    count = _wayHolders.length;
    await _wayHolders.removeAllMergedWithOtherWay();
    waysMergedCount = count - _wayHolders.length;
  }

  Future<void> _analyze1Block(OsmData blockData) async {
    if (!quiet && nextTimestamp < DateTime.now().millisecondsSinceEpoch) {
      _log.info("Read nodes: ${_positions.length}, ways: ${_wayHolders.length}, relations: ${_relations.length}");
      nextTimestamp = DateTime.now().millisecondsSinceEpoch + 1000 * 60 * 2;
    }
    for (var osmNode in blockData.nodes) {
      ++totalNodeCount;
      final ll = osmNode.latLong;
      final int latMicro;
      final int lonMicro;
      if (ll is MicroLatLong) {
        latMicro = ll.latitudeMicrodegrees;
        lonMicro = ll.longitudeMicrodegrees;
      } else if (ll is NanoLatLong) {
        latMicro = _nanoToMicrodegrees(ll.latitudeNanodegrees);
        lonMicro = _nanoToMicrodegrees(ll.longitudeNanodegrees);
      } else {
        latMicro = LatLongUtils.degreesToMicrodegrees(ll.latitude);
        lonMicro = LatLongUtils.degreesToMicrodegrees(ll.longitude);
      }
      _positions[osmNode.id] = _packMicroDegrees(latMicro, lonMicro);
      // do not store a node without tags, we cannot render anything
      if (osmNode.tags.isEmpty) {
        ++nodesWithoutTagsRemoved;
        continue;
      }
      Poiholder poiholder = converter.createNodeholder(osmNode);
      if (poiholder.tagholderCollection.isEmpty) {
        ++nodesWithoutTagsRemoved;
        continue;
      }
      if (finalBoundingBox != null) {
        if (!finalBoundingBox!.containsLatLong(poiholder.position)) {
          ++nodesFiltered;
          continue;
        }
      }
      _nodeHolders.add(poiholder);
    }
    if (!quiet && nextTimestamp < DateTime.now().millisecondsSinceEpoch) {
      _log.info("Read nodes: ${_positions.length}, ways: ${_wayHolders.length}, relations: ${_relations.length}");
      nextTimestamp = DateTime.now().millisecondsSinceEpoch + 1000 * 60 * 2;
    }
    for (OsmWay osmWay in blockData.ways) {
      ++totalWayCount;
      List<ILatLong> latLongs = [];
      for (var ref in osmWay.refs) {
        ILatLong? position = _searchPosition(ref);
        if (position != null) {
          latLongs.add(position);
        }
      }
      if (latLongs.length < 2) {
        ++waysTooLessNodesRemoved;
        continue;
      }

      Wayholder wayholder = converter.createWayholder(osmWay);
      Waypath waypath = Waypath(path: latLongs);
      if (waypath.isClosedWay()) {
        wayholder.closedOutersAdd(waypath);
      } else {
        wayholder.openOutersAdd(waypath);
      }
      // We need to merge the ways to see if they are closed. Do not remove them now.
      // if (finalBoundingBox != null) {
      //   if (!finalBoundingBox!.containsBoundingBox(wayholder.boundingBoxCached) && !finalBoundingBox!.intersects(wayholder.boundingBoxCached)) {
      //     ++waysFiltered;
      //     continue;
      //   }
      // }
      _wayHolders.add(osmWay.id, wayholder);
    }
    if (!quiet && nextTimestamp < DateTime.now().millisecondsSinceEpoch) {
      _log.info("Read nodes: ${_positions.length}, ways: ${_wayHolders.length}, relations: ${_relations.length}");
      nextTimestamp = DateTime.now().millisecondsSinceEpoch + 1000 * 60 * 2;
    }
    for (OsmRelation osmRelation in blockData.relations) {
      ++totalRelationCount;
      // we dont need all roles, remove what we do not need to save memory
      osmRelation.members.removeWhere((test) => test.role != "label" && test.role != "outer" && test.role != "inner");
      _relations.add(osmRelation);
    }
  }

  void statistics() {
    _log.info("Total nodes: $totalNodeCount, total ways: $totalWayCount, total relations: $totalRelationCount");
    // remove nodes that do not have any tags.
    if (nodesWithoutTagsRemoved > 0) _log.info("Removed $nodesWithoutTagsRemoved nodes because of no tags");

    if (waysTooLessNodesRemoved > 0) _log.info("Removed $waysTooLessNodesRemoved ways because too less nodes");
    if (waysWithoutWaysRemoved > 0) _log.info("Removed $waysWithoutWaysRemoved ways because they are empty");
    if (waysMergedCount > 0) _log.info("Removed $waysMergedCount ways because they have been merged to other ways");

    if (nodesFiltered + waysFiltered > 0) _log.info("Removed $nodesFiltered pois and $waysFiltered ways because they are out of boundary");

    if (_nodeNotFoundCount + _wayHolders.wayNotFound.length > 0) {
      _log.info("${nodeNotFound.length} ($_nodeNotFoundCount) nodes not found, ${_wayHolders.wayNotFound.length} ways not found");
    }
    _log.info("Remaining total pois: ${_nodeHolders.length}, total ways: ${_wayHolders.length}, total relations: ${waysMerged.length}");
  }

  Future<void> mergeRelationsToWays(WayConnect? wayConnect) async {
    Map<int, Wayholder> toChange = {};
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
        wayConnect?.connect(mergedWay);
        if (mergedWay.closedOutersIsNotEmpty() || mergedWay.openOutersIsNotEmpty()) {
          _wayHoldersMerged.add(mergedWay);
        }
      }
    }
    for (var entry in toChange.entries) {
      _wayHolders.change(entry.key, entry.value);
    }
    _relations.clear();
  }

  ILatLong? _searchPosition(int id) {
    final packed = _positions[id];
    if (packed != null) {
      return _unpackMicroDegrees(packed);
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

  int _packMicroDegrees(int latMicro, int lonMicro) {
    return (latMicro.toUnsigned(32) << 32) | lonMicro.toUnsigned(32);
  }

  ILatLong _unpackMicroDegrees(int packed) {
    final latMicro = (packed >> 32).toSigned(32);
    final lonMicro = (packed & 0xFFFFFFFF).toSigned(32);
    return MicroLatLong(latMicro, lonMicro);
  }

  int _nanoToMicrodegrees(int nanoDegrees) {
    // Round to nearest microdegree using integer math (nano / 1000).
    // Dart's integer division truncates toward zero.
    return nanoDegrees >= 0 ? (nanoDegrees + 500) ~/ 1000 : (nanoDegrees - 500) ~/ 1000;
  }

  Future<void> clear() async {
    _positions.clear();
    await _nodeHolders.dispose();
    await _wayHolders.dispose();
    _wayHoldersMerged.clear();
    _relations.clear();
    nodeNotFound.clear();
  }

  Future<void> filterByBoundingBox(BoundingBox boundingBox) async {
    int count = _nodeHolders.length;
    await _nodeHolders.removeWhere((nodeHolder) => !boundingBox.containsLatLong(nodeHolder.position));
    nodesFiltered += count - _nodeHolders.length;

    count = _wayHoldersMerged.length;
    _wayHoldersMerged.removeWhere((test) => !boundingBox.intersects(test.boundingBoxCached));
    for (Wayholder wayHolder in _wayHoldersMerged) {
      wayHolder.innerWrite.removeWhere((test) => !boundingBox.intersects(test.boundingBox));
      wayHolder.closedOutersWrite.removeWhere((test) => !boundingBox.intersects(test.boundingBox));
      wayHolder.openOutersWrite.removeWhere((test) => !boundingBox.intersects(test.boundingBox));
      wayHolder.moveInnerToOuter();
    }
    count = count - _wayHoldersMerged.length;
    List<int> toRemove = [];
    Map<int, Wayholder> toChange = {};
    await _wayHolders.forEach((key, wayholder) {
      if (!boundingBox.intersects(wayholder.boundingBoxCached)) {
        toRemove.add(key);
        ++count;
        return;
      }
      int c = wayholder.pathCount();
      wayholder.innerWrite.removeWhere((test) => !boundingBox.intersects(test.boundingBox));
      wayholder.closedOutersWrite.removeWhere((test) => !boundingBox.intersects(test.boundingBox));
      wayholder.openOutersWrite.removeWhere((test) => !boundingBox.intersects(test.boundingBox));
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
