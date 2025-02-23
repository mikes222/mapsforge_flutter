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

  Writebuffer writebufferTagvalues = Writebuffer();

  /// do not normalize these tags. admin_level for example has only a handful
  /// distinct values so it is a waste of time and space to normalize it
  static Set<String> DO_NOT_NORMALIZE = {"admin_level"};

  List<Tagholder> analyzeTags(List<Tag> tags, List<Tagholder> tagsArray) {
    List<Tagholder> tagholders = [];
    for (Tag tag in tags) {
      if (tag.key == MapfileHelper.TAG_KEY_NAME) {
        featureName = tag.value;
        continue;
      }
      if (tag.key == MapfileHelper.TAG_KEY_HOUSE_NUMBER) {
        featureHouseNumber = tag.value;
        continue;
      }
      if (tag.key == MapfileHelper.TAG_KEY_ELE) {
        featureElevation = int.parse(tag.value!);
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
    return tagholders;
  }

  void writeTags(Writebuffer writebuffer) {
    tagholders.forEach(
        (tagholder) => writebuffer.appendUnsignedInt(tagholder.index!));
    writebuffer.appendWritebuffer(this.writebufferTagvalues);
  }
}
