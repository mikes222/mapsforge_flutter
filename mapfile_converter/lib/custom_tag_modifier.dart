import 'package:mapfile_converter/modifiers/pbf_analyzer.dart';
import 'package:mapfile_converter/osm/osm_data.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/special.dart';

class CustomTagModifier extends PbfAnalyzerConverter {
  final Map<String, ValueInfo> allowedNodeTags;

  final Map<String, ValueInfo> allowedWayTags;

  final Map<String, ValueInfo> negativeNodeTags;

  final Map<String, ValueInfo> negativeWayTags;

  final Set<String> keys;

  CustomTagModifier({
    required this.allowedNodeTags,
    required this.allowedWayTags,
    required this.negativeNodeTags,
    required this.negativeWayTags,
    required this.keys,
  });

  @override
  void modifyNodeTags(OsmNode node, List<Tag> tags) {
    tags.removeWhere((test) {
      if (keys.contains(test.key)) return false;
      if (test.key == "name") return false;
      if (test.key == "loc_name") return false;
      if (test.key == "int_name") return false;
      if (test.key == "official_name") return false;
      if (test.key!.startsWith("name:")) return false;
      if (test.key!.startsWith("official_name:")) return false;
      ValueInfo? valueInfo = allowedNodeTags[test.key];
      if (valueInfo != null) {
        if (valueInfo.values.contains("*")) return false;
        if (valueInfo.values.contains(test.value)) return false;
      }
      valueInfo = negativeNodeTags[test.key];
      if (valueInfo != null) {
        return false;
        // if (valueInfo.values.contains("*")) return false;
        // if (valueInfo.values.contains(test.value)) return false;
      }
      return true;
    });
  }

  @override
  void modifyWayTags(OsmWay way, List<Tag> tags) {
    tags.removeWhere((test) {
      if (keys.contains(test.key)) return false;
      if (test.key == "name") return false;
      if (test.key == "loc_name") return false;
      if (test.key == "int_name") return false;
      if (test.key == "official_name") return false;
      if (test.key!.startsWith("name:")) return false;
      if (test.key!.startsWith("official_name:")) return false;
      ValueInfo? valueInfo = allowedWayTags[test.key];
      if (valueInfo != null) {
        if (valueInfo.values.contains("*")) return false;
        if (valueInfo.values.contains(test.value)) return false;
      }
      valueInfo = negativeWayTags[test.key];
      if (valueInfo != null) {
        return false;
        // if (valueInfo.values.contains("*")) return false;
        // if (valueInfo.values.contains(test.value)) return false;
      }
      return true;
    });
  }

  @override
  void modifyRelationTags(OsmRelation relation, List<Tag> tags) {
    tags.removeWhere((test) {
      if (keys.contains(test.key)) return false;
      if (test.key == "name") return false;
      if (test.key == "loc_name") return false;
      if (test.key == "int_name") return false;
      if (test.key == "official_name") return false;
      if (test.key!.startsWith("name:")) return false;
      if (test.key!.startsWith("official_name:")) return false;
      ValueInfo? valueInfo = allowedWayTags[test.key];
      if (valueInfo != null) {
        if (valueInfo.values.contains("*")) return false;
        if (valueInfo.values.contains(test.value)) return false;
      }
      valueInfo = negativeWayTags[test.key];
      if (valueInfo != null) {
        return false;
        // if (valueInfo.values.contains("*")) return false;
        // if (valueInfo.values.contains(test.value)) return false;
      }
      return true;
    });
  }
}
