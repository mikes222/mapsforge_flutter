import 'package:mapsforge_flutter/src/mapfile/writer/tagholder_mixin.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';

import '../../../core.dart';
import '../../../datastore.dart';
import '../mapfile_helper.dart';
import 'mapfile_writer.dart';

/// Holds one poi and its tags
class Poiholder with TagholderMixin {
  final PointOfInterest poi;

  Poiholder(this.poi) {}

  void analyze(List<Tagholder> tagholders, String? languagesPreference) {
    if (languagesPreference != null)
      super.languagesPreference.addAll(languagesPreference.split(","));
    analyzeTags(poi.tags, tagholders);
  }

  /// can be done when the tags are sorted
  Writebuffer writePoidata(
      bool debugFile, double tileLatitude, double tileLongitude) {
    Writebuffer writebuffer = Writebuffer();
    _writePoiSignature(debugFile, writebuffer);
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
    writeTags(writebuffer);

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

  void _writePoiSignature(bool debugFile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("***POIStart${poi.hashCode}***"
          .padRight(MapfileHelper.SIGNATURE_LENGTH_POI, " "));
    }
  }
}
