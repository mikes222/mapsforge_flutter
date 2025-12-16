import 'package:collection/collection.dart';
import 'package:mapfile_converter/osm/osm_nodeholder.dart';
import 'package:mapfile_converter/osm/osm_wayholder.dart';
import 'package:mapsforge_flutter_core/model.dart';

import '../osm/osm_data.dart';

class DefaultOsmPrimitiveConverter {
  OsmNodeholder createNodeholder(OsmNode osmNode) {
    TagCollection tagCollection = TagCollection.from(osmNode.tags);
    int layer = findLayer(tagCollection.tags);
    modifyNodeTags(osmNode, tagCollection.tags);
    // even with no tags the node may belong to a relation, so keep it
    // convert and round the latlongs to 6 digits after the decimal point. This
    // helps determining if ways are closed.
    LatLong latLong = LatLong(osmNode.latitude, osmNode.longitude);
    return OsmNodeholder(latLong: latLong, layer: layer, tagCollection: tagCollection);
  }

  PointOfInterest? createPoi(OsmNodeholder osmNode) {
    PointOfInterest pointOfInterest = PointOfInterest(osmNode.layer, osmNode.tagCollection, osmNode.latLong);
    return pointOfInterest;
  }

  OsmWayholder createWayholder(OsmWay osmWay) {
    TagCollection tagCollection = TagCollection.from(osmWay.tags);
    int layer = findLayer(tagCollection.tags);
    modifyWayTags(osmWay, tagCollection.tags);
    return OsmWayholder(layer: layer, tagCollection: tagCollection);
  }

  // Way? createWay(OsmWay osmWay, List<List<ILatLong>> latLongs) {
  //   List<Tag> tags = TagCollection.from(osmWay.tags).tags;
  //   int layer = findLayer(tags);
  //   modifyWayTags(osmWay, tags);
  //   // even with no tags the way may belong to a relation, so keep it
  //   ILatLong? labelPosition;
  //   Way way = Way(layer, tags, latLongs, labelPosition);
  //   return way;
  // }

  OsmWayholder? createMergedWayholder(OsmRelation osmRelation) {
    TagCollection tagCollection = TagCollection.from(osmRelation.tags);
    int layer = findLayer(tagCollection.tags);
    modifyRelationTags(osmRelation, tagCollection.tags);
    // topmost structure, if we have no tags, we cannot render anything
    if (tagCollection.isEmpty) return null;
    OsmWayholder wayholder = OsmWayholder(layer: layer, tagCollection: tagCollection);
    return wayholder;
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
