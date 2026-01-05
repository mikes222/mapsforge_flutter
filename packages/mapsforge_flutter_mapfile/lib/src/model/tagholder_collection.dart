import 'package:collection/collection.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/helper/mapfile_helper.dart';

class TagholderCollection implements ITagCollection {
  /// do not normalize these tags. admin_level for example has only a handful
  /// distinct values so it is a waste of time and space to normalize it
  static const Set<String> DO_POI_NORMALIZE = {"ref"};

  static const Set<String> DO_WAY_NORMALIZE = {"ele"};

  final List<Tagholder> _tagholders;

  TagholderCollection._({required List<Tagholder> tagholders}) : _tagholders = tagholders;

  factory TagholderCollection.empty() {
    return TagholderCollection._(tagholders: []);
  }

  static TagholderCollection fromPoi(Map<String, String> tags) {
    List<Tagholder> tagholders = [];
    for (var entry in tags.entries) {
      Tagholder tagholder = Tagholder(entry.key, entry.value);
      tagholders.add(tagholder);
    }
    return TagholderCollection._(tagholders: tagholders);
  }

  static TagholderCollection fromWay(Map<String, String> tags) {
    List<Tagholder> tagholders = [];
    for (var entry in tags.entries) {
      Tagholder tagholder = Tagholder(entry.key, entry.value);
      tagholders.add(tagholder);
    }
    return TagholderCollection._(tagholders: tagholders);
  }

  static TagholderCollection fromCache(List<Tagholder> tagholders) {
    return TagholderCollection._(tagholders: tagholders);
  }

  List<Tagholder> get tagholders => _tagholders;

  bool get isEmpty {
    return _tagholders.isEmpty;
  }

  int get length {
    return _tagholders.length;
  }

  /// Returns true if this POI has a tag with the given [key].
  bool hasTag(String key) {
    return _tagholders.firstWhereOrNull((test) => test.key == key) != null;
  }

  /// Returns true if this POI has a tag with the given [key] and [value].
  bool hasTagValue(String key, String value) {
    return _tagholders.firstWhereOrNull((test) => test.key == key && test.value == value) != null;
  }

  Tagholder? get(String key) {
    return _tagholders.firstWhereOrNull((test) => test.key == key);
  }

  bool get isNotEmpty {
    return _tagholders.isNotEmpty;
  }

  void _remove(Tagholder tagholder) {
    _tagholders.remove(tagholder);
  }

  String? extractName(List<String> languagesPreferences) {
    Tagholder? tagholder = get(MapfileHelper.TAG_KEY_NAME);
    tagholder ??= get("int_name");
    tagholder ??= get("official_name");
    tagholder ??= get("loc_name");

    Set<String> names = {};
    for (Tagholder tagholder in List.from(_tagholders)) {
      if (tagholder.key.startsWith("name:")) {
        String language = tagholder.key.substring(5);
        if (languagesPreferences.isNotEmpty && !languagesPreferences.contains(language)) continue;
        names.add("$language\b${tagholder.value}");
        //_remove(tagholder);
        continue;
      }
      if (tagholder.key.startsWith("official_name:")) {
        String language = tagholder.key.substring(14);
        if (languagesPreferences.isNotEmpty && !languagesPreferences.contains(language)) continue;
        names.add("$language\b${tagholder.value}");
        //_remove(tagholder);
        continue;
      }
    }

    // _removeByKey(MapfileHelper.TAG_KEY_NAME);
    // _removeByKey("int_name");
    // _removeByKey("official_name");
    // _removeByKey("loc_name");

    if (names.isNotEmpty) {
      if (tagholder != null) {
        return "${tagholder.value}\r${names.join("\r")}";
      } else {
        return names.join("\r");
      }
    }
    return tagholder?.value;
  }

  int extractLayer() {
    for (Tagholder tagholder in _tagholders) {
      if (tagholder.key == "layer") {
        int layer = int.tryParse(tagholder.value) ?? 0;
        // layers from -5 to 10 are allowed, will be stored as 0..15 in the file (4 bit)
        if (layer < -5) layer = -5;
        if (layer > 10) layer = 10;
        //_remove(tagholder);
        return layer;
      }
    }
    return 0;
  }

  String? extractHousenumber() {
    Tagholder? tagholder = get(MapfileHelper.TAG_KEY_HOUSE_NUMBER);
    if (tagholder != null) {
      //_remove(tagholder);
      return tagholder.value;
    }
    return null;
  }

  int? extractElevation() {
    Tagholder? tagholder = get(MapfileHelper.TAG_KEY_ELE);
    if (tagholder != null) {
      //_remove(tagholder);
      try {
        return int.parse(tagholder.value);
      } catch (_) {
        try {
          return double.parse(tagholder.value).round();
        } catch (_) {
          // do nothing. The value is not a number.
        }
      }
    }
    return null;
  }

  // only for ways:
  String? extractRef() {
    Tagholder? tagholder = get(MapfileHelper.TAG_KEY_REF);
    if (tagholder != null) {
      //_remove(tagholder);
      return tagholder.value;
    }
    return null;
  }

  /// Returns a string representation of the given list of tags, excluding any
  /// name-related tags.
  String printTagsWithoutNames() {
    String result = '';
    for (var tag in _tagholders) {
      if (tag.key.startsWith("name:") || tag.key.startsWith("official_name") || tag.key.startsWith("alt_name") || tag.key.startsWith("int_name")) continue;
      if (result.isNotEmpty) result += ",";
      result += "${tag.key}=${tag.value}";
    }
    return result;
  }

  @override
  String? getTag(String key) {
    return _tagholders.firstWhereOrNull((test) => test.key == key)?.value;
  }

  @override
  bool matchesTagList(List<String> keys) {
    Tagholder? tag = _tagholders.firstWhereOrNull((element) => keys.contains(element.key));
    return tag != null;
  }

  @override
  bool valueMatchesTagList(List<String> values) {
    Tagholder? tag = _tagholders.firstWhereOrNull((element) => values.contains(element.value));
    return tag != null;
  }

  int writePoiTags(Writebuffer writebuffer, TagholderModel model) {
    Writebuffer writebuffer2 = Writebuffer();
    int count = 0;
    for (Tagholder tagholder in _tagholders) {
      if (TagholderModel.isMapfilePoiTag(tagholder.key)) continue;
      assert(tagholder.index != null, "tagholder.index must not be null $tagholder");
      ++count;
      Tagholder sorted = model.getPoiTagSorted(tagholder.index!);
      assert(sorted.key == tagholder.key);
      if (sorted.value == "%b") {
        writebuffer2.appendInt1(int.parse(tagholder.value));
      } else if (sorted.value == "%i") {
        writebuffer2.appendInt4(int.parse(tagholder.value));
      } else if (sorted.value == "%f") {
        writebuffer2.appendFloat4(double.parse(tagholder.value));
      } else if (sorted.value == "%s") {
        writebuffer2.appendString(tagholder.value);
      }
      writebuffer.appendUnsignedInt(sorted.index!);
    }
    writebuffer.appendUint8(writebuffer2.getUint8ListAndClear());

    if (count > 15) {
      for (var test in _tagholders) {
        print("${test.key}=${test.value}");
      }
      throw Exception("more than 15 tags are not supported");
    }
    return count;
  }

  int writeWayTags(Writebuffer writebuffer, TagholderModel model) {
    Writebuffer writebuffer2 = Writebuffer();
    int count = 0;
    for (Tagholder tagholder in _tagholders) {
      if (TagholderModel.isMapfileWayTag(tagholder.key)) continue;
      assert(tagholder.index != null, "tagholder.index must not be null $tagholder $count");
      ++count;
      Tagholder sorted = model.getWayTagSorted(tagholder.index!);
      assert(sorted.key == tagholder.key);
      if (sorted.value == "%b") {
        writebuffer2.appendInt1(int.parse(tagholder.value));
      } else if (sorted.value == "%i") {
        writebuffer2.appendInt4(int.parse(tagholder.value));
      } else if (sorted.value == "%f") {
        writebuffer2.appendFloat4(double.parse(tagholder.value));
      } else if (sorted.value == "%s") {
        writebuffer2.appendString(tagholder.value);
      }
      writebuffer.appendUnsignedInt(sorted.index!);
    }
    writebuffer.appendUint8(writebuffer2.getUint8ListAndClear());

    if (count > 15) {
      for (var test in _tagholders) {
        print("${test.key}=${test.value}");
      }
      throw Exception("more than 15 tags are not supported");
    }
    return count;
  }

  String _extractPoiValue(String key, String value) {
    if (DO_POI_NORMALIZE.contains(key)) {
      if (int.tryParse(value) != null) {
        int v = int.parse(value);
        if (v >= 0 && v < 256) {
          value = "%b";
        } else {
          value = "%i";
        }
      } else if (double.tryParse(value) != null) {
        value = "%f";
      } else {
        value = "%s";
      }
    }
    return value;
  }

  String _extractWayValue(String key, String value) {
    if (DO_WAY_NORMALIZE.contains(key)) {
      if (int.tryParse(value) != null) {
        int v = int.parse(value);
        if (v >= 0 && v < 256) {
          value = "%b";
        } else {
          value = "%i";
        }
      } else if (double.tryParse(value) != null) {
        value = "%f";
      } else {
        value = "%s";
      }
    }
    return value;
  }

  void connectPoiToModel(TagholderModel model) {
    for (Tagholder tagholder in _tagholders) {
      if (tagholder.index != null) continue;
      if (TagholderModel.isMapfilePoiTag(tagholder.key)) continue;
      String value = _extractPoiValue(tagholder.key, tagholder.value);
      tagholder.index = model.getPoiTagIndex(tagholder.key, value);
    }
  }

  void connectWayToModel(TagholderModel model) {
    for (Tagholder tagholder in _tagholders) {
      if (tagholder.index != null) continue;
      if (TagholderModel.isMapfileWayTag(tagholder.key)) continue;
      String value = _extractWayValue(tagholder.key, tagholder.value);
      tagholder.index = model.getWayTagIndex(tagholder.key, value);
    }
  }

  @override
  String toString() {
    return 'TagholderCollection{_tagholders: $_tagholders}';
  }
}
