import 'dart:math' as Math;

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';

import '../../core.dart';
import '../../pbf.dart';

/// Reads data from a pbf file and converts it to PointOfInterest and Way objects
/// so that they are usable in mapsforge. By implementing your own version of
/// [PbfAnalyzerConverter] you can control the behavior of the converstion from
/// OSM data to PointOfInterest and Way objects.
class PbfAnalyzer {
  Map<int, _PoiHolder> _nodeHolders = {};

  Map<int, _WayHolder> _wayHolders = {};

  List<_WayHolder> _wayHoldersMerged = [];

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

  List<Way> get ways => _wayHolders.values.map((e) => e.way).toList();

  List<Way> get waysMerged => _wayHolders.values.map((e) => e.way).toList();

  Future<void> analyze(
      ReadbufferSource readbufferSource, int sourceLength) async {
    PbfReader pbfReader = PbfReader();
    await pbfReader.open(readbufferSource);
    while (readbufferSource.getPosition() < sourceLength) {
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
        Way? way = converter.createWay(osmWay, latLongs);
        if (way != null) _wayHolders[osmWay.id] = _WayHolder(way);
      });
      blockData.relations.forEach((osmRelation) {
        List<Tag> tags = Tag.from(osmRelation.tags);
        converter.modifyRelationTags(osmRelation, tags);
        _relationReferences(osmRelation);
        relations[osmRelation.id] = osmRelation;
        //print("Relation ${osmRelation.id}: $memberType $member $tags");
      });
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
    _wayHolders.removeWhere((id, _WayHolder test) => test.way.latLongs.isEmpty);
    waysWithoutNodesRemoved = count - _wayHolders.length;

    count = _wayHolders.length;
    _wayHolders.removeWhere((id, _WayHolder test) => test.mergedWithOtherWay);
    waysMergedCount = count - _wayHolders.length;

    count = _nodeHolders.values.fold(0, (count, test) => count + test.useCount);

    boundingBox = pbfReader.calculateBounds();
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
  }

  void _mergeRelationsToWays() {
    relations.forEach((key, relation) {
      List<_WayHolder> outers = [];
      List<_WayHolder> inners = [];
      ILatLong? labelPosition = null;
      List<RoleType> otherType = [];
      relation.members.forEach((member) {
        if (member.role == RoleType.label) {
          PointOfInterest? pointOfInterest = _searchPoi(member.memberId);
          if (pointOfInterest != null) {
            labelPosition = pointOfInterest.position;
          }
        } else if (member.role == RoleType.outer &&
            member.memberType == MemberType.way) {
          _WayHolder? wayHolder = _searchWayHolder(member.memberId);
          if (wayHolder != null) {
            outers.add(wayHolder);
          }
        } else if (member.role == RoleType.inner &&
            member.memberType == MemberType.way) {
          _WayHolder? wayHolder = _searchWayHolder(member.memberId);
          if (wayHolder != null) {
            inners.add(wayHolder);
          }
        } else {
          otherType.add(member.role);
        }
      });
      if (outers.isNotEmpty || inners.isNotEmpty) {
        _WayHolder wayHolder = outers.firstOrNull ?? inners.firstOrNull!;
        List<Tag> tags = Tag.from(relation.tags);
        converter.modifyMergedTags(relation, wayHolder.way, tags);
        wayHolder = _WayHolder(Way(wayHolder.way.layer, tags, [], null));

        for (_WayHolder outer in outers) {
          //print("Adding $outer to $wayHolder");
          outer.way.latLongs.forEach((latlongs) {
            wayHolder.way.latLongs.add(latlongs);
          });
          outer.mergedWithOtherWay = true;
        }
        for (_WayHolder inner in inners) {
          //print("Adding $inner to $wayHolder");
          inner.way.latLongs.forEach((latlongs) {
            wayHolder.way.latLongs.add(latlongs);
          });
          inner.mergedWithOtherWay = true;
        }
        if (labelPosition != null) {
          Way way = Way(wayHolder.way.layer, wayHolder.way.tags,
              wayHolder.way.latLongs, labelPosition);
          wayHolder.way = way;
        }
        _wayHoldersMerged.add(wayHolder);
      }
    });
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

  _WayHolder? _searchWayHolder(int id) {
    _WayHolder? wayHolder = _wayHolders[id];
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
}

//////////////////////////////////////////////////////////////////////////////

class _PoiHolder {
  final PointOfInterest pointOfInterest;

  int useCount = 0;

  _PoiHolder(this.pointOfInterest);
}

//////////////////////////////////////////////////////////////////////////////

class _WayHolder {
  Way way;

  bool mergedWithOtherWay = false;

  _WayHolder(this.way);

  @override
  String toString() {
    return 'WayHolder{way: ${way.tags}, mergedWithOtherWay: $mergedWithOtherWay}';
  }
}

//////////////////////////////////////////////////////////////////////////////

class PbfAnalyzerConverter {
  PointOfInterest? createNode(OsmNode osmNode) {
    List<Tag> tags = Tag.from(osmNode.tags);
    int layer = findLayer(tags);
    modifyNodeTags(osmNode, tags);
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
    ILatLong? labelPosition = null;
    Way way = Way(layer, tags, latLongs, labelPosition);
    return way;
  }

  double _roundDouble(double value, int places) {
    num mod = Math.pow(10.0, places);
    return ((value * mod).round().toDouble() / mod);
  }

  void modifyNodeTags(OsmNode node, List<Tag> tags) {}

  void modifyWayTags(OsmWay way, List<Tag> tags) {}

  void modifyRelationTags(OsmRelation relation, List<Tag> tags) {}

  void modifyMergedTags(OsmRelation relation, Way way, List<Tag> tags) {}

  int findLayer(List<Tag> tags) {
    Tag? layerTag = tags
        .firstWhereOrNull((test) => test.key == "layer" && test.value != null);
    int layer = 0;
    if (layerTag != null) {
      layer = int.parse(layerTag.value!);
      tags.remove(layerTag);
    }
    // layers from -5 to 10 are allowed, will be stored as 0..15 in the file (4 bit)
    if (layer < -5) layer = -5;
    if (layer > 10) layer = 10;
    return layer;
  }
}
