import 'package:mapsforge_flutter_mapfile/src/helper/mapfile_helper.dart';
import 'package:mapsforge_flutter_mapfile/src/model/tagholder.dart';

class TagholderModel {
  final List<Tagholder> _poiTags = [];

  final Map<int, int> _poiCounts = {};

  final Map<String, int> _poiTagIndex = {};

  final List<Tagholder> _wayTags = [];

  final Map<int, int> _wayCounts = {};

  final Map<String, int> _wayTagIndex = {};

  static final List<String> _mapfilePoiTags = [
    MapfileHelper.TAG_KEY_NAME,
    "int_name",
    "official_name",
    "loc_name",
    "layer",
    MapfileHelper.TAG_KEY_HOUSE_NUMBER,
    MapfileHelper.TAG_KEY_ELE,
    //MapfileHelper.TAG_KEY_REF,
  ];

  static final List<String> _mapfileWayTags = [
    MapfileHelper.TAG_KEY_NAME,
    "int_name",
    "official_name",
    "loc_name",
    "layer",
    MapfileHelper.TAG_KEY_HOUSE_NUMBER,
    //MapfileHelper.TAG_KEY_ELE,
    MapfileHelper.TAG_KEY_REF,
  ];

  List<Tagholder> get poiTags => _poiTags;

  List<Tagholder> get wayTags => _wayTags;

  static bool isMapfilePoiTag(String key) {
    if (key.startsWith("name:")) return true;
    if (key.startsWith("official_name:")) return true;
    return _mapfilePoiTags.contains(key);
  }

  static bool isMapfileWayTag(String key) {
    if (key.startsWith("name:")) return true;
    if (key.startsWith("official_name:")) return true;
    return _mapfileWayTags.contains(key);
  }

  static String _cacheKey(String key, String value) => '$key\u0000$value';

  int getPoiTagIndex(String key, String value) {
    final cacheKey = _cacheKey(key, value);
    final existingIndex = _poiTagIndex[cacheKey];
    if (existingIndex != null) {
      _poiCounts[existingIndex] = (_poiCounts[existingIndex] ?? 0) + 1;
      return existingIndex;
    }
    final index = _poiTags.length;
    final result = Tagholder(key, value);
    _poiTags.add(result);
    _poiTagIndex[cacheKey] = index;
    _poiCounts[index] = (_poiCounts[index] ?? 0) + 1;
    return index;
  }

  int getWayTagIndex(String key, String value) {
    final cacheKey = _cacheKey(key, value);
    final existingIndex = _wayTagIndex[cacheKey];
    if (existingIndex != null) {
      _wayCounts[existingIndex] = (_wayCounts[existingIndex] ?? 0) + 1;
      return existingIndex;
    }
    final index = _wayTags.length;
    final result = Tagholder(key, value);
    _wayTags.add(result);
    _wayTagIndex[cacheKey] = index;
    _wayCounts[index] = (_wayCounts[index] ?? 0) + 1;
    return index;
  }

  List<Tagholder> sortPoiTagholders() {
    List<Tagholder> result = List.from(_poiTags);
    result.sort((a, b) => a.index!.compareTo(b.index!));
    return result;
  }

  List<Tagholder> sortWayTagholders() {
    List<Tagholder> result = List.from(_wayTags);
    result.sort((a, b) => a.index!.compareTo(b.index!));
    return result;
  }

  Tagholder getPoiTagSorted(int index) {
    assert(index >= 0, "index must be >= 0 $index");
    assert(index < _poiTags.length, "index must be < _poiTags.length ${_poiTags.length} $index");
    return _poiTags[index];
  }

  Tagholder getWayTagSorted(int index) {
    assert(index >= 0, "index must be >= 0 $index");
    assert(index < _wayTags.length, "index must be < _wayTags.length ${_wayTags.length} $index");
    return _wayTags[index];
  }

  /// Mapfiles needs an index for each tag starting at 0 for the most-used tag.
  void setPoiIndexes() {
    var sortedKeys = _poiCounts.keys.toList(growable: false)..sort((k1, k2) => _poiCounts[k2]!.compareTo(_poiCounts[k1]!));
    int idx = 0;
    for (var index in sortedKeys) {
      Tagholder test = _poiTags.elementAt(index);
      test.index = idx;
      ++idx;
    }
  }

  /// Mapfiles needs an index for each tag starting at 0 for the most-used tag.
  void setWayIndexes() {
    var sortedKeys = _wayCounts.keys.toList(growable: false)..sort((k1, k2) => _wayCounts[k2]!.compareTo(_wayCounts[k1]!));
    int idx = 0;
    for (var index in sortedKeys) {
      Tagholder test = _wayTags.elementAt(index);
      test.index = idx;
      ++idx;
    }
  }

  void debug() {
    print("PoiTags: ${_poiTags.length}");
    int idx = 0;
    for (var test in _poiTags) {
      print("${test.key}=${test.value} index: ${test.index}, count: ${_poiCounts[idx]}");
      ++idx;
    }
    print("WayTags: ${_wayTags.length}");
    idx = 0;
    for (var test in _wayTags) {
      print("${test.key}=${test.value} index: ${test.index}, count: ${_wayCounts[idx]}");
      ++idx;
    }
  }
}
