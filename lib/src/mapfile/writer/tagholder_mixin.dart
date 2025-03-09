import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';

import '../../../core.dart';
import '../mapfile_helper.dart';
import 'mapfile_writer.dart';

mixin TagholderMixin {
  List<Tagholder> tagholders = [];

  String? featureName;

  String? featureHouseNumber;

  int? featureElevation;

  String? featureRef;

  /**
   * The preferred language(s) separated with ',' for names as defined in ISO 639-1 or ISO 639-2 (may be null).
   */
  List<String> languagesPreference = [];

  Writebuffer writebufferTagvalues = Writebuffer();

  /// do not normalize these tags. admin_level for example has only a handful
  /// distinct values so it is a waste of time and space to normalize it
  static Set<String> DO_NOT_NORMALIZE = {"admin_level"};

  void analyzeTags(List<Tag> tags, List<Tagholder> tagsArray) {
    Set<String> names = {};
    String? original;
    String? fallback;
    for (Tag tag in tags) {
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
        if (languagesPreference.isNotEmpty &&
            !languagesPreference.contains(language)) continue;
        if (tag.value != null && tag.value!.isNotEmpty)
          names.add("${language}\b${tag.value!}");
        continue;
      }
      if (tag.key?.startsWith("official_name:") ?? false) {
        String language = tag.key!.substring(5);
        if (languagesPreference.isNotEmpty &&
            !languagesPreference.contains(language)) continue;
        if (tag.value != null && tag.value!.isNotEmpty)
          names.add("${language}\b${tag.value!}");
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
          writebufferTagvalues.appendInt4(int.parse(tag.value!));
          tag = Tag(tag.key, "%i");
        } else if (double.tryParse(tag.value!) != null) {
          writebufferTagvalues.appendFloat4(double.parse(tag.value!));
          tag = Tag(tag.key, "%f");
        }
      }
      Tagholder? tagholder = tagsArray.firstWhereOrNull(
          (test) => test.tag.key == tag.key && test.tag.value == tag.value);
      if (tagholder == null) {
        tagholder = Tagholder(tag);
        tagsArray.add(tagholder);
      } else {
        tagholder.count++;
      }
      tagholders.add(tagholder);
    }

    // originalname should be at first position, fallbackname only used if originalname is null
    featureName = original ?? fallback;
    if (names.isNotEmpty) {
      if (featureName != null) {
        featureName = featureName! + "\r" + names.join("\r");
      } else {
        featureName = names.join("\r");
      }
    }
    if (tagholders.length > 15) {
      tagholders.forEach((test) => print("${test.tag.key}=${test.tag.value}"));
      throw Exception("more than 15 tags are not supported");
    }
  }

  void writeTags(Writebuffer writebuffer) {
    tagholders.forEach(
        (tagholder) => writebuffer.appendUnsignedInt(tagholder.index!));
    writebuffer.appendWritebuffer(this.writebufferTagvalues);
  }
}
