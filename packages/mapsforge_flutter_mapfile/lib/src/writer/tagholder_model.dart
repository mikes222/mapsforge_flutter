import 'package:collection/collection.dart';
import 'package:mapsforge_flutter_mapfile/src/helper/mapfile_helper.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/tagholder.dart';

class TagholderModel {
  final List<Tagholder> poiTags = [];

  final List<Tagholder> wayTags = [];

  static final List<String> mapfilePoiTags = [
    MapfileHelper.TAG_KEY_NAME,
    "int_name",
    "official_name",
    "loc_name",
    "layer",
    MapfileHelper.TAG_KEY_HOUSE_NUMBER,
    MapfileHelper.TAG_KEY_ELE,
    //MapfileHelper.TAG_KEY_REF,
  ];

  static final List<String> mapfileWayTags = [
    MapfileHelper.TAG_KEY_NAME,
    "int_name",
    "official_name",
    "loc_name",
    "layer",
    MapfileHelper.TAG_KEY_HOUSE_NUMBER,
    //MapfileHelper.TAG_KEY_ELE,
    MapfileHelper.TAG_KEY_REF,
  ];

  static bool isMapfilePoiTag(String key) {
    if (key.startsWith("name:")) return true;
    if (key.startsWith("official_name:")) return true;
    return mapfilePoiTags.contains(key);
  }

  static bool isMapfileWayTag(String key) {
    if (key.startsWith("name:")) return true;
    if (key.startsWith("official_name:")) return true;
    return mapfileWayTags.contains(key);
  }

  Tagholder getPoiTag(String key, String value) {
    Tagholder? result = poiTags.firstWhereOrNull((test) => test.key == key && test.value == value);
    if (result != null) {
      return result;
    }
    result = Tagholder(key, value);
    poiTags.add(result);
    return result;
  }

  Tagholder getWayTag(String key, String value) {
    Tagholder? result = wayTags.firstWhereOrNull((test) => test.key == key && test.value == value);
    if (result != null) {
      return result;
    }
    result = Tagholder(key, value);
    wayTags.add(result);
    return result;
  }

  /// Mapfiles needs an index for each tag starting at 0 for the most-used tag.
  void setIndexes() {
    poiTags.removeWhere((test) => test.count == 0);
    poiTags.sort((a, b) => b.count.compareTo(a.count));
    poiTags
        .where((test) {
          if (isMapfilePoiTag(test.key)) return false;
          return true;
        })
        .forEachIndexed((index, tagholder) {
          tagholder.index = index;
          //print("set for poiTags $tagholder");
        });
    wayTags.removeWhere((test) => test.count == 0);
    wayTags.sort((a, b) => b.count.compareTo(a.count));
    wayTags
        .where((test) {
          if (isMapfileWayTag(test.key)) return false;
          return true;
        })
        .forEachIndexed((index, tagholder) {
          tagholder.index = index;
          //print("set for wayTags $tagholder");
        });
  }
}
