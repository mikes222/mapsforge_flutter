import 'dart:math' as Math;

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:mapfile_converter/pbfreader/pbf_data.dart';
import 'package:mapfile_converter/pbfreader/pbf_reader.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/special.dart';

import '../custom_tag_modifier.dart';
import 'way_repair.dart';

/// Reads data from a pbf file and converts it to PointOfInterest and Way objects
/// so that they are usable in mapsforge. By implementing your own version of
/// [PbfAnalyzerConverter] you can control the behavior of the converstion from
/// OSM data to PointOfInterest and Way objects.
class PbfAnalyzer {
  final _log = new Logger('PbfAnalyzer');

  final Map<int, _PoiHolder> _nodeHolders = {};

  final Map<int, Wayholder> _wayHolders = {};

  final List<Wayholder> _wayHoldersMerged = [];

  Map<int, OsmRelation> relations = {};

  Set<int> nodeNotFound = {};

  Set<int> wayNotFound = {};

  int nodesWithoutTagsRemoved = 0;

  int waysWithoutNodesRemoved = 0;

  int waysMergedCount = 0;

  BoundingBox? boundingBox;

  PbfAnalyzerConverter converter = PbfAnalyzerConverter();

  List<PointOfInterest> get pois => _nodeHolders.values.map((e) => e.pointOfInterest).toList();

  List<Wayholder> get ways => _wayHolders.values.map((e) => e).toList();

  List<Wayholder> get waysMerged => _wayHoldersMerged;

  static Future<PbfAnalyzer> readFile(String filename, RuleAnalyzer ruleAnalyzer) async {
    ReadbufferSource readbufferSource = ReadbufferFile(filename);
    return readSource(readbufferSource, ruleAnalyzer);
  }

  static Future<PbfAnalyzer> readSource(ReadbufferSource readbufferSource, RuleAnalyzer ruleAnalyzer) async {
    int length = await readbufferSource.length();
    PbfAnalyzer pbfAnalyzer = PbfAnalyzer();
    pbfAnalyzer.converter = CustomTagModifier(
      allowedNodeTags: ruleAnalyzer.nodeValueinfos(),
      allowedWayTags: ruleAnalyzer.wayValueinfos(),
      negativeNodeTags: ruleAnalyzer.nodeNegativeValueinfos(),
      negativeWayTags: ruleAnalyzer.wayNegativeValueinfos(),
      keys: ruleAnalyzer.keys,
    );
    await pbfAnalyzer.analyze(readbufferSource, length);
    pbfAnalyzer.removeSuperflous();
    //    print("rule: ${ruleAnalyzer.closedWayValueinfos()}");
    //    print("rule neg: ${ruleAnalyzer.closedWayNegativeValueinfos()}");
    return pbfAnalyzer;
  }

  Future<void> analyze(ReadbufferSource readbufferSource, int sourceLength) async {
    PbfReader pbfReader = PbfReader();
    await pbfReader.open(readbufferSource);
    while (readbufferSource.getPosition() < sourceLength) {
      await _analyze1Block(pbfReader, readbufferSource);
    }
    _mergeRelationsToWays();

    _wayHoldersMerged.forEach((value) {
      if (value.way.latLongs.isEmpty) {
        value.way = Way(value.way.layer, value.way.tags, value.otherOuters, value.way.labelPosition);
        value.otherOuters = [];
      }
    });

    WayRepair wayRepair = WayRepair();
    for (var wayholder in _wayHoldersMerged) {
      // would be nice to find the tags which requires a closed area via the render rules but for now they seem too many. Lets define a set of rules here.
      if (wayholder.way.hasTagValue("natural", "water") ||
          wayholder.way.hasTagValue("natural", "land") ||
          wayholder.way.hasTagValue("natural", "meadow") ||
          wayholder.way.hasTagValue("natural", "wetland") ||
          wayholder.way.hasTagValue("landuse", "residential") ||
          wayholder.way.hasTagValue("landuse", "forest") ||
          wayholder.way.hasTagValue("landuse", "wood") ||
          wayholder.way.hasTagValue("landuse", "grassland")) {
        wayRepair.repairClosed(wayholder);
      } else {
        wayRepair.repairOpen(wayholder);
      }
    }

    boundingBox = pbfReader.calculateBounds();
  }

  void removeSuperflous() {
    int count = _nodeHolders.length;
    _nodeHolders.removeWhere((key, value) => value.pointOfInterest.tags.isEmpty);
    nodesWithoutTagsRemoved = count - _nodeHolders.length;

    // remove ways with less than 2 points (this is not a way)
    count = _wayHolders.length;
    _wayHolders.forEach((key, value) {
      value.way.latLongs.removeWhere((test) => test.length < 2);
    });
    _wayHolders.removeWhere((id, Wayholder test) => test.way.latLongs.isEmpty);
    waysWithoutNodesRemoved = count - _wayHolders.length;

    count = _wayHolders.length;
    _wayHolders.removeWhere((id, Wayholder test) => test.mergedWithOtherWay);
    waysMergedCount = count - _wayHolders.length;

    // remove ways with less than 2 points (this is not a way)
    count = _wayHoldersMerged.length;
    _wayHoldersMerged.forEach((value) {
      value.otherOuters.removeWhere((test) => test.length < 2);
    });
    _wayHoldersMerged.forEach((value) {
      value.way.latLongs.removeWhere((test) => test.length < 2);
    });

    _wayHoldersMerged.removeWhere((Wayholder test) => test.way.latLongs.isEmpty);
    waysWithoutNodesRemoved = count - _wayHoldersMerged.length;

    //    count = _nodeHolders.values.fold(0, (count, test) => count + test.useCount);
  }

  Future<void> _analyze1Block(PbfReader pbfReader, ReadbufferSource readbufferSource) async {
    PbfData blockData = await pbfReader.read(readbufferSource);
    //print(blockData);
    blockData.nodes.forEach((osmNode) {
      PointOfInterest? pointOfInterest = converter.createNode(osmNode);
      if (pointOfInterest != null) _nodeHolders[osmNode.id] = _PoiHolder(pointOfInterest);
    });
    blockData.ways.forEach((osmWay) {
      List<List<ILatLong>> latLongs = [];
      latLongs.add([]);
      osmWay.refs.forEach((ref) {
        if (nodeNotFound.contains(ref)) {
          return;
        }
        PointOfInterest? pointOfInterest = _searchPoi(ref);
        if (pointOfInterest != null) {
          latLongs[0].add(pointOfInterest.position);
        }
      });
      if (latLongs[0].length >= 2) {
        Way? way = converter.createWay(osmWay, latLongs);
        if (way != null) {
          assert(!_wayHolders.containsKey(osmWay.id));
          _wayHolders[osmWay.id] = Wayholder(way);
        }
      }
    });
    blockData.relations.forEach((osmRelation) {
      _relationReferences(osmRelation);
      relations[osmRelation.id] = osmRelation;
      //print("Relation ${osmRelation.id}: $memberType $member $tags");
    });
  }

  void statistics() {
    // remove nodes that do not have any tags.
    _log.info("Removed ${nodesWithoutTagsRemoved} nodes because of no tags");

    _log.info("Removed ${waysWithoutNodesRemoved} ways because less than 2 nodes");
    _log.info("Removed ${waysMergedCount} ways because they have been merged to other ways");

    _log.info("${nodeNotFound.length} nodes not found, ${wayNotFound.length} ways not found");
    _log.info("Total poi count: ${_nodeHolders.length}, total way count: ${_wayHolders.length}");
    // print(
    //     "Total way reference count: $count, no reference found: $noWayRefFound");
  }

  void _mergeRelationsToWays() {
    relations.forEach((key, relation) {
      List<Wayholder> outers = [];
      List<Wayholder> inners = [];
      ILatLong? labelPosition = null;
      // search for outer and inner ways and for possible label position
      relation.members.forEach((member) {
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
      });
      if (outers.isNotEmpty || inners.isNotEmpty) {
        Way? mergedWay = converter.createMergedWay(relation);
        if (mergedWay == null) return;
        bool debug = false;
        // if (mergedWay.hasTagValue("landuse", "forest")) {
        //   outers.forEach((outer) {
        //     if (outer.way.latLongs[0].first == LatLong(47.299339, 17.045369) || outer.way.latLongs[0].last == LatLong(47.299339, 17.045369)) debug = true;
        //   });
        // }
        if (debug) {
          print("Found ${mergedWay.toStringWithoutNames()} with ${outers.length} outers and ${inners.length} inners for relation ${relation.id}");
          outers.forEach((outer) {
            print("  ${outer.way.toStringWithoutNames()}");
          });
        }
        List<Wayholder> remainingOuters = [];

        for (Wayholder outerWayholder in outers) {
          assert(outerWayholder.way.latLongs.length == 1);
          if (mergedWay.latLongs.isEmpty) {
            mergedWay.latLongs.add([...outerWayholder.way.latLongs[0]]);
            outerWayholder.mergedWithOtherWay = true;
            if (debug) {
              print(
                "added ${outerWayholder.way.toStringWithoutNames()} to ${mergedWay.toStringWithoutNames()}, closed: ${LatLongUtils.isClosedWay(mergedWay.latLongs[0])}",
              );
            }
            continue;
          }
          bool appended = _appendLatLongs(relation, mergedWay, outerWayholder.way);
          if (appended) {
            outerWayholder.mergedWithOtherWay = true;
            if (debug) {
              print(
                "appended ${outerWayholder.way.toStringWithoutNames()} to ${mergedWay.toStringWithoutNames()}, closed: ${LatLongUtils.isClosedWay(mergedWay.latLongs[0])}",
              );
            }
          } else {
            remainingOuters.add(outerWayholder);
            if (debug) {
              print("NOT appended ${outerWayholder.way.toStringWithoutNames()} to ${mergedWay.toStringWithoutNames()}");
            }
          }
        }
        for (Wayholder inner in inners) {
          assert(inner.way.latLongs.length == 1);
          mergedWay.latLongs.add(inner.way.latLongs[0]);
          inner.mergedWithOtherWay = true;
        }
        if (labelPosition != null) {
          mergedWay = Way(mergedWay.layer, mergedWay.tags, mergedWay.latLongs, labelPosition);
        }
        // try to append to the master again
        int iterations = 0;
        while (true) {
          int count = remainingOuters.length;
          ++iterations;
          for (Wayholder remainingOuter in List.from(remainingOuters)) {
            if (LatLongUtils.isClosedWay(mergedWay.latLongs[0])) {
              break;
            }
            bool appended = _appendLatLongs(relation, mergedWay, remainingOuter.way);
            if (appended) {
              if (debug) {
                print(
                  "later appended ${remainingOuter.way.toStringWithoutNames()} to ${mergedWay.toStringWithoutNames()}, closed: ${LatLongUtils.isClosedWay(mergedWay.latLongs[0])}",
                );
              }
              remainingOuters.remove(remainingOuter);
              remainingOuter.mergedWithOtherWay = true;
            }
          }
          if (remainingOuters.length == count) break;
        }
        // now try to append the remaining outers to each other
        while (true) {
          int count = remainingOuters.length;
          ++iterations;
          List<Wayholder> merged = [];
          for (Wayholder remainingOuterFirst in List.from(remainingOuters)) {
            if (LatLongUtils.isClosedWay(remainingOuterFirst.way.latLongs[0])) {
              continue;
            }
            for (Wayholder remainingOuterSecond in List.from(remainingOuters)) {
              if (remainingOuterFirst == remainingOuterSecond) continue;
              if (merged.contains(remainingOuterFirst) || merged.contains(remainingOuterSecond)) {
                continue;
              }
              if (LatLongUtils.isClosedWay(remainingOuterSecond.way.latLongs[0])) {
                continue;
              }
              bool appended = _appendLatLongs(relation, remainingOuterFirst.way, remainingOuterSecond.way);
              if (appended) {
                if (debug) {
                  print("outer appended ${remainingOuterSecond.way.toStringWithoutNames()} to ${remainingOuterFirst.way.toStringWithoutNames()}");
                }
                bool ok = remainingOuters.remove(remainingOuterSecond);
                assert(ok);
                remainingOuterSecond.mergedWithOtherWay = true;
                merged.add(remainingOuterSecond);
              }
            }
          }
          if (remainingOuters.length == count) break;
        }

        if (debug) {
          print("$iterations iterations needed to combine. ${remainingOuters.length} outers left");
        }
        // add the remaining outer ways. They use the same properties as the master way
        // but will be treated as separate ways when reading the mapfile
        Wayholder mergedWayholder = Wayholder(mergedWay);
        for (Wayholder remainingOuter in remainingOuters) {
          assert(remainingOuter.way.latLongs.length == 1);
          mergedWayholder.otherOuters.add(List.from(remainingOuter.way.latLongs[0]));
          remainingOuter.mergedWithOtherWay = true;
          if (debug) {
            print(
              "  remaining: $remainingOuter with first: ${remainingOuter.way.latLongs[0].first} and last: ${remainingOuter.way.latLongs[0].last}, closed: ${LatLongUtils.isClosedWay(remainingOuter.way.latLongs[0])}",
            );
          }
        }
        _wayHoldersMerged.add(mergedWayholder);
      }
    });
  }

  bool _appendLatLongs(OsmRelation osmRelation, Way master, Way other) {
    // do not add to closed ways
    if (master.latLongs.isNotEmpty && LatLongUtils.isClosedWay(master.latLongs[0])) {
      return false;
    }

    List<ILatLong> latlongs = master.latLongs[0];
    List<ILatLong> otherLatLongs = other.latLongs[0];
    // int count = otherLatLongs.fold(
    //     0, (value, combine) => latlongs.contains(combine) ? ++value : value);
    // // return true because it is already merged
    // // if (count == otherLatLongs.length) return true;
    // if (count > 1)
    //   print(
    //       "${other.toStringWithoutNames()} has $count latlongs in common with ${master.toStringWithoutNames()}");
    return LatLongUtils.combine(latlongs, otherLatLongs);
  }

  void _relationReferences(OsmRelation osmRelation) {
    osmRelation.members.forEach((member) {
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
            return;
          }
          break;
      }
    });
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
  }

  void filterByBoundingBox(BoundingBox boundingBox) {
    _nodeHolders.removeWhere((zoomlevel, test) => !boundingBox.containsLatLong(test.pointOfInterest.position));
    _wayHolders.removeWhere((zoomlevel, test) => !boundingBox.intersects(test.way.getBoundingBox()));
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
    ILatLong? labelPosition = null;
    Way way = Way(layer, tags, latLongs, labelPosition);
    return way;
  }

  Way? createMergedWay(OsmRelation relation) {
    List<Tag> tags = Tag.from(relation.tags);
    int layer = findLayer(tags);
    modifyRelationTags(relation, tags);
    // topmost structure, if we have no tags, we cannot render anything
    if (tags.isEmpty) return null;
    ILatLong? labelPosition = null;
    Way way = Way(layer, tags, [], labelPosition);
    return way;
  }

  double _roundDouble(double value, int places) {
    num mod = Math.pow(10.0, places);
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
