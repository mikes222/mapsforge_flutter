import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:mapfile_converter/large_data_splitter.dart';
import 'package:mapfile_converter/pbfreader/pbf_data.dart';
import 'package:mapfile_converter/pbfreader/pbf_reader.dart';
import 'package:mapfile_converter/pbfreader/way_connect.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/special.dart';

import '../custom_tag_modifier.dart';
import '../osm/osm_reader.dart';
import 'way_repair.dart';

/// Reads data from a pbf file and converts it to PointOfInterest and Way objects
/// so that they are usable in mapsforge. By implementing your own version of
/// [PbfAnalyzerConverter] you can control the behavior of the converstion from
/// OSM data to PointOfInterest and Way objects.
class PbfAnalyzer {
  final _log = Logger('PbfAnalyzer');

  final double maxGapMeter;

  final Map<int, _PoiHolder> _nodeHolders = {};

  final Map<int, Wayholder> _wayHolders = {};

  final List<Wayholder> _wayHoldersMerged = [];

  Map<int, OsmRelation> relations = {};

  Set<int> nodeNotFound = {};

  Set<int> wayNotFound = {};

  int nodesWithoutTagsRemoved = 0;

  int waysWithoutNodesRemoved = 0;

  int closedWaysWithLessNodesRemoved = 0;

  int waysMergedCount = 0;

  BoundingBox? boundingBox;

  PbfAnalyzerConverter converter = PbfAnalyzerConverter();

  List<PointOfInterest> get pois => _nodeHolders.values.map((e) => e.pointOfInterest).toList();

  List<Wayholder> get ways => _wayHolders.values.map((e) => e).toList();

  List<Wayholder> get waysMerged => _wayHoldersMerged;

  PbfAnalyzer({this.maxGapMeter = 200, required RuleAnalyzer ruleAnalyzer}) {
    converter = CustomTagModifier(
      allowedNodeTags: ruleAnalyzer.nodeValueinfos(),
      allowedWayTags: ruleAnalyzer.wayValueinfos(),
      negativeNodeTags: ruleAnalyzer.nodeNegativeValueinfos(),
      negativeWayTags: ruleAnalyzer.wayNegativeValueinfos(),
      keys: ruleAnalyzer.keys,
    );
  }

  static Future<PbfAnalyzer> readFile(String filename, RuleAnalyzer ruleAnalyzer, {double maxGapMeter = 200}) async {
    ReadbufferSource readbufferSource = ReadbufferFile(filename);
    PbfAnalyzer result = await readSource(readbufferSource, ruleAnalyzer, maxGapMeter: maxGapMeter);
    readbufferSource.dispose();
    return result;
  }

  static Future<PbfAnalyzer> readSource(ReadbufferSource readbufferSource, RuleAnalyzer ruleAnalyzer, {double maxGapMeter = 200}) async {
    int length = await readbufferSource.length();
    PbfAnalyzer pbfAnalyzer = PbfAnalyzer(maxGapMeter: maxGapMeter, ruleAnalyzer: ruleAnalyzer);
    await pbfAnalyzer.readToMemory(readbufferSource, length);
    await pbfAnalyzer.analyze();
    pbfAnalyzer.removeSuperflous();
    //    print("rule: ${ruleAnalyzer.closedWayValueinfos()}");
    //    print("rule neg: ${ruleAnalyzer.closedWayNegativeValueinfos()}");
    return pbfAnalyzer;
  }

  Future<void> readToMemory(ReadbufferSource readbufferSource, int sourceLength) async {
    PbfReader pbfReader = PbfReader();
    await pbfReader.open(readbufferSource);
    while (readbufferSource.getPosition() < sourceLength) {
      PbfData pbfData = await pbfReader.readBlobData(readbufferSource);
      await _analyze1Block(pbfData);
    }
    boundingBox = pbfReader.calculateBounds();
  }

  Future<void> readOsmToMemory(String filename) async {
    OsmReader osmReader = OsmReader(filename);
    await osmReader.readOsmFile((PbfData pbfData) async {
      await _analyze1Block(pbfData);
    });
    boundingBox = osmReader.boundingBox;
    await analyze();
    removeSuperflous();
  }

  Future<void> analyze() async {
    /// nodes are done, remove superflous nodes to free memory
    int count = _nodeHolders.length;
    _nodeHolders.removeWhere((key, value) => value.pointOfInterest.tags.isEmpty);
    nodesWithoutTagsRemoved = count - _nodeHolders.length;

    _mergeRelationsToWays();

    WayRepair wayRepair = WayRepair(maxGapMeter);
    for (var wayholder in _wayHoldersMerged) {
      // would be nice to find the tags which requires a closed area via the render rules but for now they seem too many. Lets define a set of rules here.
      // See https://wiki.openstreetmap.org/wiki/Key:area
      if (wayholder.hasTag("building") ||
          wayholder.hasTag("landuse") ||
          wayholder.hasTag("leisure") ||
          wayholder.hasTag("natural") ||
          wayholder.hasTagValue("indoor", "corridor")) {
        wayRepair.repairClosed(wayholder);
      } else {
        wayRepair.repairOpen(wayholder);
      }
    }
    List<Wayholder> wayholders =
        _wayHolders.values
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
      _log.info("Connecting and repairing coastline: $count ways");
      WayConnect wayConnect = WayConnect();
      wayConnect.connect(mergedWayholder);
      //_log.info("Repairing coastline");
      wayRepair.repairClosed(mergedWayholder);
      int count2 = mergedWayholder.openOutersRead.length + mergedWayholder.closedOutersRead.length;
      LargeDataSplitter largeDataSplitter = LargeDataSplitter();
      largeDataSplitter.split(_wayHoldersMerged, mergedWayholder);
      _log.info("Repairing coastline: reduced from $count to $count2 ways");
    }
  }

  void removeSuperflous() {
    // remove ways with less than 2 points (this is not a way)
    int count = _wayHolders.length;
    _wayHolders.forEach((key, Wayholder wayholder) {
      wayholder.closedOutersWrite.removeWhere((test) => test.length <= 2);
    });
    closedWaysWithLessNodesRemoved = count - _wayHolders.length;

    count = _wayHolders.length;
    _wayHolders.removeWhere((id, Wayholder test) => test.innerRead.isEmpty && test.openOutersRead.isEmpty && test.closedOutersRead.isEmpty);
    waysWithoutNodesRemoved = count - _wayHolders.length;

    count = _wayHolders.length;
    _wayHolders.removeWhere((id, Wayholder test) => test.mergedWithOtherWay);
    waysMergedCount = count - _wayHolders.length;
  }

  Future<void> _analyze1Block(PbfData blockData) async {
    for (var osmNode in blockData.nodes) {
      PointOfInterest? pointOfInterest = converter.createNode(osmNode);
      if (pointOfInterest != null) _nodeHolders[osmNode.id] = _PoiHolder(pointOfInterest);
    }
    for (var osmWay in blockData.ways) {
      List<List<ILatLong>> latLongs = [];
      latLongs.add([]);
      for (var ref in osmWay.refs) {
        if (nodeNotFound.contains(ref)) {
          continue;
        }
        PointOfInterest? pointOfInterest = _searchPoi(ref);
        if (pointOfInterest != null) {
          latLongs[0].add(pointOfInterest.position);
        }
      }
      if (latLongs[0].length >= 2) {
        Way? way = converter.createWay(osmWay, latLongs);
        if (way != null) {
          assert(!_wayHolders.containsKey(osmWay.id));
          _wayHolders[osmWay.id] = Wayholder.fromWay(way);
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

    _log.info("${nodeNotFound.length} nodes not found, ${wayNotFound.length} ways not found");
    _log.info("Total poi count: ${_nodeHolders.length}, total way count: ${_wayHolders.length}, total relation-way count: ${waysMerged.length}");
    // print(
    //     "Total way reference count: $count, no reference found: $noWayRefFound");
  }

  void _mergeRelationsToWays() {
    relations.forEach((key, relation) {
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
          Wayholder? wayHolder = _searchWayHolder(member.memberId);
          if (wayHolder != null) {
            outers.add(wayHolder);
          }
        } else if (member.role == "inner" && member.memberType == MemberType.way) {
          Wayholder? wayHolder = _searchWayHolder(member.memberId);
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
        bool debug = false;
        // if (mergedWay.hasTagValue("name", "Port de Fontvieille")) {
        //   debug = true;
        // }
        if (debug) {
          print("Found ${mergedWayholder.toStringWithoutNames()} with ${outers.length} outers and ${inners.length} inners for relation ${relation.id}");
          outers.forEach((outer) {
            print("  ${outer.toStringWithoutNames()}");
          });
        }

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
          assert(outerWayholder.openOutersRead.length + outerWayholder.closedOutersRead.length == 1);
        }
        // add closed ways
        for (Wayholder remainingOuterFirst in List.from(outers)) {
          if (remainingOuterFirst.closedOutersRead.isNotEmpty) {
            mergedWayholder.closedOutersAdd(remainingOuterFirst.closedOutersRead.first.clone());
            remainingOuterFirst.mergedWithOtherWay = true;
            outers.remove(remainingOuterFirst);
          }
        }
        // Append the remaining outers to each other
        int iterations = 0;
        while (true) {
          int count = outers.length;
          ++iterations;
          List<Wayholder> merged = [];
          for (Wayholder remainingOuterFirst in List.from(outers)) {
            if (remainingOuterFirst.closedOutersRead.isNotEmpty) {
              mergedWayholder.closedOutersAdd(remainingOuterFirst.closedOutersRead.first.clone());
              remainingOuterFirst.mergedWithOtherWay = true;
              outers.remove(remainingOuterFirst);
              merged.add(remainingOuterFirst);
              continue;
            }
            assert(remainingOuterFirst.openOutersRead.isNotEmpty, "First value should have at least one open way: $remainingOuterFirst");
            for (Wayholder remainingOuterSecond in List.from(outers)) {
              if (remainingOuterFirst == remainingOuterSecond) continue;
              if (merged.contains(remainingOuterFirst) || merged.contains(remainingOuterSecond)) {
                continue;
              }
              if (remainingOuterSecond.closedOutersRead.isNotEmpty) {
                mergedWayholder.closedOutersAdd(remainingOuterSecond.closedOutersRead.first.clone());
                remainingOuterSecond.mergedWithOtherWay = true;
                outers.remove(remainingOuterSecond);
                merged.add(remainingOuterSecond);
                continue;
              }
              bool appended = _appendLatLongs(relation, remainingOuterFirst.openOutersWrite.first, remainingOuterSecond.openOutersWrite.first);
              if (appended) {
                if (debug) {
                  print("outer appended ${remainingOuterSecond.toStringWithoutNames()} to ${remainingOuterFirst.toStringWithoutNames()}");
                }
                remainingOuterSecond.mergedWithOtherWay = true;
                outers.remove(remainingOuterSecond);
                merged.add(remainingOuterSecond);
                remainingOuterFirst.mayMoveToClosed(remainingOuterFirst.openOutersRead.first);
                // if (remainingOuterFirst.openOutersRead.first.isClosedWay()) {
                //   mergedWayholder.closedOutersAdd(remainingOuterFirst.openOutersRead.first.clone());
                //   remainingOuterFirst.openOutersRemove(remainingOuterFirst.openOutersRead.first);
                //   remainingOuterFirst.closedOutersAdd(remainingOuterFirst.openOutersRead.first);
                //   remainingOuterFirst.mergedWithOtherWay = true;
                //   outers.remove(remainingOuterFirst);
                //   merged.add(remainingOuterFirst);
                // }
                if (remainingOuterFirst.openOutersWrite.isEmpty) {
                  // seems it is now a closed way, skip to the next way
                  break;
                }
              }
            }
          }
          if (outers.length == count) break;
        }

        if (debug) {
          print("$iterations iterations needed to combine. ${outers.length} outers left");
        }
        // add the remaining outer ways. They use the same properties as the master way
        // but will be treated as separate ways when reading the mapfile
        for (Wayholder remainingOuter in outers) {
          assert(remainingOuter.closedOutersRead.isEmpty);
          //assert(!remainingOuter.openOutersRead.first.isClosedWay(), "Outer way is closed ${remainingOuter}");
          if (remainingOuter.openOutersRead.first.isClosedWay()) {
            mergedWayholder.closedOutersAdd(remainingOuter.openOutersRead.first.clone());
          } else {
            mergedWayholder.openOutersAdd(remainingOuter.openOutersRead.first.clone());
          }
          remainingOuter.mergedWithOtherWay = true;
          if (debug) {
            print(
              "  remaining: $remainingOuter with first: ${remainingOuter.openOutersRead.first} and last: ${remainingOuter.openOutersRead.last}, closed: ${remainingOuter.openOutersRead.first.isClosedWay()}",
            );
          }
        }
        if (mergedWayholder.closedOutersRead.isNotEmpty || mergedWayholder.openOutersRead.isNotEmpty) {
          _wayHoldersMerged.add(mergedWayholder);
        }
      }
    });
  }

  bool _appendLatLongs(OsmRelation osmRelation, Waypath master, Waypath other) {
    if (master.isEmpty) {
      master.addAll(other.path);
      return true;
    }
    assert(!master.isClosedWay());

    // int count = otherLatLongs.fold(
    //     0, (value, combine) => latlongs.contains(combine) ? ++value : value);
    // // return true because it is already merged
    // // if (count == otherLatLongs.length) return true;
    // if (count > 1)
    //   print(
    //       "${other.toStringWithoutNames()} has $count latlongs in common with ${master.toStringWithoutNames()}");
    return LatLongUtils.combine(master, other.path);
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

  Wayholder? _searchWayHolder(int id) {
    Wayholder? wayHolder = _wayHolders[id];
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
  }

  void filterByBoundingBox(BoundingBox boundingBox) {
    _nodeHolders.removeWhere((zoomlevel, test) => !boundingBox.containsLatLong(test.pointOfInterest.position));
    _wayHolders.removeWhere(
      (zoomlevel, test) =>
          !boundingBox.intersects(test.boundingBoxCached) &&
          !boundingBox.containsBoundingBox(test.boundingBoxCached) &&
          !test.boundingBoxCached.containsBoundingBox(boundingBox),
    );
    _wayHoldersMerged.removeWhere(
      (test) =>
          !boundingBox.intersects(test.boundingBoxCached) &&
          !boundingBox.containsBoundingBox(test.boundingBoxCached) &&
          !test.boundingBoxCached.containsBoundingBox(boundingBox),
    );
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
