import 'package:mapfile_converter/modifiers/default_osm_primitive_converter.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

/// Removes tags from node/ways according to the rules. If no tags remains the correspondig node/way will be discarded
class CustomOsmPrimitiveConverter extends DefaultOsmPrimitiveConverter {
  final Map<String, ValueInfo> allowedNodeTags;

  final Map<String, ValueInfo> allowedWayTags;

  final Map<String, ValueInfo> negativeNodeTags;

  final Map<String, ValueInfo> negativeWayTags;

  final Set<String> keys;

  CustomOsmPrimitiveConverter({
    required this.allowedNodeTags,
    required this.allowedWayTags,
    required this.negativeNodeTags,
    required this.negativeWayTags,
    required this.keys,
  }) {
    keys.add("layer");
    if (keys.contains("name")) {
      keys.add("int_name");
      keys.add("official_name");
      keys.add("loc_name");
    }
    // allowedWayTags.forEach((key, value) {
    //   print("allowedWays: ${key} $value");
    // });
  }

  @override
  void modifyNodeTags(Map<String, String> tags) {
    tags.removeWhere((key, value) {
      // keep what we need for the rendertheme
      if (keys.contains(key)) return false;
      if (keys.contains("name") && key.startsWith("name:")) return false;
      if (keys.contains("name") && key.startsWith("official_name:")) return false;
      ValueInfo? valueInfo = allowedNodeTags[key];
      if (valueInfo != null) {
        if (valueInfo.values.contains("*")) return false;
        if (valueInfo.values.contains(value)) return false;
      }
      valueInfo = negativeNodeTags[key];
      if (valueInfo != null) {
        return false;
        // if (valueInfo.values.contains("*")) return false;
        // if (valueInfo.values.contains(test.value)) return false;
      }
      return true;
    });
  }

  @override
  void modifyWayTags(Map<String, String> tags) {
    tags.removeWhere((key, value) {
      //if (TagholderModel.isMapfileWayTag(key)) return false;
      // keep what we need for the rendertheme
      if (keys.contains(key)) return false;
      if (keys.contains("name") && key.startsWith("name:")) return false;
      if (keys.contains("name") && key.startsWith("official_name:")) return false;
      ValueInfo? valueInfo = allowedWayTags[key];
      if (valueInfo != null) {
        if (valueInfo.values.contains("*")) return false;
        if (valueInfo.values.contains(value)) return false;
      }
      valueInfo = negativeWayTags[key];
      if (valueInfo != null) {
        return false;
        // if (valueInfo.values.contains("*")) return false;
        // if (valueInfo.values.contains(test.value)) return false;
      }
      return true;
    });
  }

  @override
  void modifyRelationTags(Map<String, String> tags) {
    tags.removeWhere((key, value) {
      //if (TagholderModel.isMapfileWayTag(key)) return false;
      // keep what we need for the rendertheme
      if (keys.contains(key)) return false;
      if (keys.contains("name") && key.startsWith("name:")) return false;
      if (keys.contains("name") && key.startsWith("official_name:")) return false;
      ValueInfo? valueInfo = allowedWayTags[key];
      if (valueInfo != null) {
        if (valueInfo.values.contains("*")) return false;
        if (valueInfo.values.contains(value)) return false;
      }
      valueInfo = negativeWayTags[key];
      if (valueInfo != null) {
        return false;
        // if (valueInfo.values.contains("*")) return false;
        // if (valueInfo.values.contains(test.value)) return false;
      }
      return true;
    });
  }
}
