import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/src/mapfile/writebuffer.dart';

import '../../core.dart';
import '../../datastore.dart';
import '../model/tag.dart';
import 'mapfile_helper.dart';
import 'mapfile_writer.dart';

/// Holds one poi and its tags
class Poiholder {
  final bool debugFile;

  final PointOfInterest poi;

  List<Tagholder> tagholders = [];

  String? featureName;

  String? featureHouseNumber;

  int? featureElevation;

  Poiholder(this.debugFile, this.poi, List<Tagholder> tagholders) {
    tagholders = _analyzeTags(poi.tags, tagholders);
  }

  List<Tagholder> _analyzeTags(List<Tag> tags, List<Tagholder> tagsArray) {
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

  void _writePoiSignature(Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("***POIStart${poi.hashCode}***"
          .padRight(MapfileHelper.SIGNATURE_LENGTH_POI, " "));
    }
  }

  /// can be done when the tags are sorted
  Writebuffer writePoidata(double tileLatitude, double tileLongitude) {
    Writebuffer writebuffer = Writebuffer();
    _writePoiSignature(writebuffer);
    writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
        poi.position.latitude - tileLatitude));
    writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
        poi.position.longitude - tileLongitude));

    int specialByte = 0;
    // bit 1-4 represent the layer
    specialByte |= ((poi.layer + 5) & MapfileHelper.POI_LAYER_BITMASK) <<
        MapfileHelper.POI_LAYER_SHIFT;
    // bit 5-8 represent the number of tag IDs
    specialByte |=
        (tagholders.length & MapfileHelper.POI_NUMBER_OF_TAGS_BITMASK);
    writebuffer.appendInt1(specialByte);
    tagholders.forEach(
        (tagholder) => writebuffer.appendUnsignedInt(tagholder.index!));

    // get the feature bitmask (1 byte)
    int featureByte = 0;
    // bit 1-3 enable optional features
    if (featureName != null) featureByte |= MapfileHelper.POI_FEATURE_NAME;
    if (featureHouseNumber != null)
      featureByte |= MapfileHelper.POI_FEATURE_HOUSE_NUMBER;
    if (featureElevation != null)
      featureByte |= MapfileHelper.POI_FEATURE_ELEVATION;
    writebuffer.appendInt1(featureByte);
    if (featureName != null) {
      writebuffer.appendString(featureName!);
    }
    if (featureHouseNumber != null) {
      writebuffer.appendString(featureHouseNumber!);
    }
    if (featureElevation != null) {
      writebuffer.appendSignedInt(featureElevation!);
    }
    return writebuffer;
  }
}
