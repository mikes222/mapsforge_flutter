import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/src/helper/mapfile_helper.dart';

/// A mixin that provides shared functionality for handling OpenStreetMap tags
/// during the map file writing process.
///
/// This includes logic for analyzing tags, extracting special features like names
/// and house numbers, and serializing the tag data to a [Writebuffer].
class TagholderMixin {
  List<Tagholder> tagholders = [];

  String? featureName;

  String? featureHouseNumber;

  int? featureElevation;

  String? featureRef;

  Uint8List? writebufferTagvalues;

  /// do not normalize these tags. admin_level for example has only a handful
  /// distinct values so it is a waste of time and space to normalize it
  static Set<String> DO_NOT_NORMALIZE = {"admin_level"};

  TagholderMixin clone() {
    TagholderMixin result = TagholderMixin();
    result.tagholders = List.from(tagholders);
    result.featureName = featureName;
    result.featureHouseNumber = featureHouseNumber;
    result.featureElevation = featureElevation;
    result.featureRef = featureRef;
    result.writebufferTagvalues = writebufferTagvalues;
    return result;
  }

  /// Analyzes a list of [tags], identifying special features and counting the
  /// occurrences of each tag.
  void analyzeTags(TagCollection tags, List<Tagholder> tagsArray, List<String> languagesPreference) {
    Set<String> names = {};
    String? original;
    String? fallback;
    Writebuffer writebuffer = Writebuffer();
    for (Tag tag in tags.tags) {
      if (tag.key == MapfileHelper.TAG_KEY_NAME) {
        if (tag.value != null && tag.value!.isNotEmpty) original = tag.value;
        continue;
      }
      if (tag.key == "loc_name") {
        if (tag.value != null && tag.value!.isNotEmpty) fallback = tag.value;
        continue;
      }
      if (tag.key == "int_name") {
        if (tag.value != null && tag.value!.isNotEmpty) fallback = tag.value;
        continue;
      }
      if (tag.key == "official_name") {
        if (tag.value != null && tag.value!.isNotEmpty) fallback = tag.value;
        continue;
      }
      if (tag.key?.startsWith("name:") ?? false) {
        String language = tag.key!.substring(5);
        if (languagesPreference.isNotEmpty && !languagesPreference.contains(language)) continue;
        if (tag.value != null && tag.value!.isNotEmpty) names.add("$language\b${tag.value!}");
        continue;
      }
      if (tag.key?.startsWith("official_name:") ?? false) {
        String language = tag.key!.substring(5);
        if (languagesPreference.isNotEmpty && !languagesPreference.contains(language)) continue;
        if (tag.value != null && tag.value!.isNotEmpty) names.add("$language\b${tag.value!}");
        continue;
      }
      if (tag.key == MapfileHelper.TAG_KEY_HOUSE_NUMBER) {
        featureHouseNumber = tag.value;
        continue;
      }
      if (tag.key == MapfileHelper.TAG_KEY_ELE) {
        try {
          featureElevation = int.parse(tag.value!);
        } catch (_) {
          try {
            featureElevation = double.parse(tag.value!).round();
          } catch (_) {
            // ignore the elevation which is neither a double nor an integer
          }
        }
        continue;
      }
      // only for ways:
      if (tag.key == MapfileHelper.TAG_KEY_REF) {
        featureRef = tag.value;
        continue;
      }
      // normalize tags
      if (tag.value != null && !DO_NOT_NORMALIZE.contains(tag.key)) {
        if (int.tryParse(tag.value!) != null) {
          writebuffer.appendInt4(int.parse(tag.value!));
          tag = Tag(tag.key, "%i");
        } else if (double.tryParse(tag.value!) != null) {
          writebuffer.appendFloat4(double.parse(tag.value!));
          tag = Tag(tag.key, "%f");
        }
      }
      Tagholder? tagholder = tagsArray.firstWhereOrNull((test) => test.tag.key == tag.key && test.tag.value == tag.value);
      if (tagholder == null) {
        tagholder = Tagholder(tag);
        tagsArray.add(tagholder);
      } else {
        tagholder.count++;
      }
      tagholders.add(tagholder);
    }
    writebufferTagvalues = writebuffer.getUint8List();

    // originalname should be at first position, fallbackname only used if originalname is null
    featureName = original ?? fallback;
    if (names.isNotEmpty) {
      if (featureName != null) {
        featureName = "${featureName!}\r${names.join("\r")}";
      } else {
        featureName = names.join("\r");
      }
    }
    if (tagholders.length > 15) {
      for (var test in tagholders) {
        print("${test.tag.key}=${test.tag.value}");
      }
      throw Exception("more than 15 tags are not supported");
    }
  }

  /// Writes the analyzed tag data to the given [writebuffer].
  void writeTags(Writebuffer writebuffer) {
    for (var tagholder in tagholders) {
      writebuffer.appendUnsignedInt(tagholder.index!);
    }
    writebuffer.appendUint8(writebufferTagvalues!);
  }
}

//////////////////////////////////////////////////////////////////////////////

class Tagholder {
  // how often is the tag used. We will use this for sorting tags
  int count = 0;

  // the index of the tag after sorting
  int? index;

  final Tag tag;

  Tagholder(this.tag);

  @override
  String toString() {
    return 'Tagholder{count: $count, index: $index, tag: $tag}';
  }
}
