import 'dart:math' as Math;

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';

import '../../core.dart';
import '../../pbf.dart';

/// Reads data from a pbf file and converts it to PointOfInterest and Way objects
/// so that they are usable in mapsforge. By implementing your own version of
/// [PbfAnalyzerConverter] you can control the behavior of the converstion from
/// OSM data to PointOfInterest and Way objects.
class PbfAnalyzer {
  Map<int, _PoiHolder> _nodeHolders = {};

  Map<int, Wayholder> _wayHolders = {};

  List<Wayholder> _wayHoldersMerged = [];

  Map<int, OsmRelation> relations = {};

  Set<int> nodeNotFound = {};

  Set<int> wayNotFound = {};

  int nodesWithoutTagsRemoved = 0;

  int waysWithoutNodesRemoved = 0;

  int waysMergedCount = 0;

  BoundingBox? boundingBox;

  PbfAnalyzerConverter converter = PbfAnalyzerConverter();

  List<PointOfInterest> get pois =>
      _nodeHolders.values.map((e) => e.pointOfInterest).toList();

  List<Wayholder> get ways => _wayHolders.values.map((e) => e).toList();

  List<Wayholder> get waysMerged => _wayHoldersMerged;

  Future<void> analyze(
      ReadbufferSource readbufferSource, int sourceLength) async {
    PbfReader pbfReader = PbfReader();
    await pbfReader.open(readbufferSource);
    while (readbufferSource.getPosition() < sourceLength) {
      await _analyze1Block(pbfReader, readbufferSource);
    }
    _mergeRelationsToWays();
    int count = _nodeHolders.length;
    _nodeHolders
        .removeWhere((key, value) => value.pointOfInterest.tags.isEmpty);
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
    _wayHoldersMerged.forEach((value) {
      if (value.way.latLongs.isEmpty) {
        value.way = Way(value.way.layer, value.way.tags, value.otherOuters,
            value.way.labelPosition);
        value.otherOuters = [];
      }
    });

    _wayHoldersMerged
        .removeWhere((Wayholder test) => test.way.latLongs.isEmpty);
    waysWithoutNodesRemoved = count - _wayHoldersMerged.length;

    count = _nodeHolders.values.fold(0, (count, test) => count + test.useCount);

    boundingBox = pbfReader.calculateBounds();
  }

  Future<void> _analyze1Block(
      PbfReader pbfReader, ReadbufferSource readbufferSource) async {
    PbfData blockData = await pbfReader.read(readbufferSource);
    //print(blockData);
    blockData.nodes.forEach((osmNode) {
      PointOfInterest? pointOfInterest = converter.createNode(osmNode);
      if (pointOfInterest != null)
        _nodeHolders[osmNode.id] = _PoiHolder(pointOfInterest);
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
    print("Removed ${nodesWithoutTagsRemoved} nodes because of no tags");

    print("Removed ${waysWithoutNodesRemoved} ways because less than 2 nodes");
    print(
        "Removed ${waysMergedCount} ways because they have been merged to other ways");

    print(
        "${nodeNotFound.length} nodes not found, ${wayNotFound.length} ways not found");
    print(
        "Total poi count: ${_nodeHolders.length}, total way count: ${_wayHolders.length}");
    // print(
    //     "Total way reference count: $count, no reference found: $noWayRefFound");

    // print("First 20 nodes:");
    // _nodeHolders.values.forEachIndexedWhile((idx, action) {
    //   print("  ${action.pointOfInterest}");
    //   if (idx >= 20) return false;
    //   return true;
    // });
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
        } else if (member.role == "outer" &&
            member.memberType == MemberType.way) {
          Wayholder? wayHolder = _searchWayHolder(member.memberId);
          if (wayHolder != null) {
            outers.add(wayHolder);
          }
        } else if (member.role == "inner" &&
            member.memberType == MemberType.way) {
          Wayholder? wayHolder = _searchWayHolder(member.memberId);
          if (wayHolder != null) {
            inners.add(wayHolder);
          }
        }
      });
      if (outers.isNotEmpty || inners.isNotEmpty) {
        Way? way = converter.createMergedWay(relation);
        if (way == null) return;
        Wayholder wayholder = Wayholder(way);
        bool debug = false;
        // if (wayholder.way.hasTagValue("natural", "water")) {
        //   print(
        //       "Found ${wayholder.way.toStringWithoutNames()} with ${outers.length} outers and ${inners.length} inners for relation ${relation.id}");
        //   outers.forEach((outer) {
        //     print("  ${outer.way.toStringWithoutNames()}");
        //   });
        //   debug = true;
        // }
        List<Wayholder> remainingOuters = [];

        for (Wayholder outerWayholder in outers) {
          // if (outerWayholder.mergedWithOtherWay) continue;
          assert(outerWayholder.way.latLongs.length == 1);
          bool appended =
              _appendLatLongs(relation, wayholder.way, outerWayholder.way);
          if (appended) {
            outerWayholder.mergedWithOtherWay = true;
            if (debug)
              print(
                  "appended ${outerWayholder.way.toStringWithoutNames()} to ${wayholder.way.toStringWithoutNames()}, closed: ${LatLongUtils.isClosedWay(wayholder.way.latLongs[0])}");
          } else {
            remainingOuters.add(outerWayholder);
            if (debug)
              print(
                  "NOT appended ${outerWayholder.way.toStringWithoutNames()} to ${wayholder.way.toStringWithoutNames()}");
          }
        }
        for (Wayholder inner in inners) {
          //print("Adding $inner to $wayHolder");
          inner.way.latLongs.forEach((latlongs) {
            wayholder.way.latLongs.add(latlongs);
          });
          inner.mergedWithOtherWay = true;
        }
        if (labelPosition != null) {
          Way way = Way(wayholder.way.layer, wayholder.way.tags,
              wayholder.way.latLongs, labelPosition);
          wayholder.way = way;
        }
        // try to append again
        int iterations = 0;
        while (true) {
          int count = remainingOuters.length;
          for (Wayholder remainingOuter in List.from(remainingOuters)) {
            bool appended =
                _appendLatLongs(relation, wayholder.way, remainingOuter.way);
            if (appended) {
              if (debug)
                print(
                    "later appended ${remainingOuter.way.toStringWithoutNames()} to ${wayholder.way.toStringWithoutNames()}, closed: ${LatLongUtils.isClosedWay(wayholder.way.latLongs[0])}");
              remainingOuters.remove(remainingOuter);
              remainingOuter.mergedWithOtherWay = true;
            }
          }
          if (remainingOuters.length == count) break;
          ++iterations;
          if (iterations % 10 == 0)
            print("$iterations iterations for $count outers");
        }
        // add the remaining outer ways. They use the same properties as the master way
        // but will be treated as separate ways when reading the mapfile
        for (Wayholder remainingOuter in List.from(remainingOuters)) {
          wayholder.otherOuters.add(remainingOuter.way.latLongs[0]);
          remainingOuter.mergedWithOtherWay = true;
        }
        _wayHoldersMerged.add(wayholder);
      }
    });
  }

  bool _appendLatLongs(OsmRelation osmRelation, Way master, Way other) {
    // do not add to closed ways
    if (master.latLongs.isNotEmpty &&
        LatLongUtils.isClosedWay(master.latLongs[0])) return false;

    if (master.latLongs.isEmpty) {
      master.latLongs.add([]..addAll(other.latLongs[0]));
      return true;
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
    if (LatLongUtils.isNear(latlongs.first, otherLatLongs.last)) {
      // add to the start of this list
      latlongs.removeAt(0);
      latlongs.insertAll(0, otherLatLongs);
      return true;
    } else if (LatLongUtils.isNear(latlongs.last, otherLatLongs.first)) {
      // add to end of this list
      latlongs.addAll(otherLatLongs.skip(1));
      return true;
    } else if (LatLongUtils.isNear(latlongs.first, otherLatLongs.first)) {
      // reversed order, add to start of the list in reversed order
      latlongs.removeAt(0);
      latlongs.insertAll(0, otherLatLongs.reversed);
      return true;
    } else if (LatLongUtils.isNear(latlongs.last, otherLatLongs.last)) {
      // reversed order, add to end of the list in reversed order
      latlongs.addAll(otherLatLongs.reversed.skip(1));
      return true;
    } else {
      return false;
    }
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
    LatLong latLong = LatLong(
        _roundDouble(osmNode.latitude, 6), _roundDouble(osmNode.longitude, 6));
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
    Tag? layerTag = tags
        .firstWhereOrNull((test) => test.key == "layer" && test.value != null);
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
