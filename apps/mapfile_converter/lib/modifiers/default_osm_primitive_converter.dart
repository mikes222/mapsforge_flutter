import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

import '../osm/osm_data.dart';

class DefaultOsmPrimitiveConverter {
  DefaultOsmPrimitiveConverter();

  Poiholder createNodeholder(OsmNode osmNode) {
    modifyNodeTags(osmNode.tags);
    TagholderCollection tagholderCollection = TagholderCollection.fromPoi(osmNode.tags);
    // even with no tags the node may belong to a relation, so keep it
    // convert and round the latlongs to 6 digits after the decimal point. This
    // helps determining if ways are closed.
    LatLong latLong = LatLong(osmNode.latitude, osmNode.longitude);
    return Poiholder(position: latLong, tagholderCollection: tagholderCollection);
  }

  Wayholder createWayholder(OsmWay osmWay) {
    modifyWayTags(osmWay.tags);
    TagholderCollection tagholderCollection = TagholderCollection.fromWay(osmWay.tags);
    return Wayholder(tagholderCollection: tagholderCollection);
  }

  Wayholder? createMergedWayholder(OsmRelation osmRelation) {
    modifyRelationTags(osmRelation.tags);
    TagholderCollection tagholderCollection = TagholderCollection.fromWay(osmRelation.tags);
    // topmost structure, if we have no tags, we cannot render anything
    if (tagholderCollection.isEmpty) return null;
    Wayholder wayholder = Wayholder(tagholderCollection: tagholderCollection);
    return wayholder;
  }

  void modifyNodeTags(Map<String, String> tags) {}

  void modifyWayTags(Map<String, String> tags) {}

  void modifyRelationTags(Map<String, String> tags) {}
}
