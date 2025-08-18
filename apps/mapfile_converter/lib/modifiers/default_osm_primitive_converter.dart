import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dart_common/model.dart';

import '../osm/osm_data.dart';

class DefaultOsmPrimitiveConverter {
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
    num mod = pow(10.0, places);
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
