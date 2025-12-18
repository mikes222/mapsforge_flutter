import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/src/helper/mapfile_helper.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/tagholder_mixin.dart';

class PoiholderWriter {
  /// Serializes the POI data to a [Writebuffer].
  ///
  /// This must be called after the tags have been analyzed and sorted.
  /// [debugFile] determines whether to include a debug signature.
  /// [tileLatitude] and [tileLongitude] are the base coordinates from which the
  /// POI's delta-encoded position is calculated.
  void writePoidata(Writebuffer writebuffer, Poiholder poiholder, bool debugFile, double tileLatitude, double tileLongitude) {
    _writePoiSignature(poiholder.poi, debugFile, writebuffer);
    writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(poiholder.poi.position.latitude - tileLatitude));
    writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(poiholder.poi.position.longitude - tileLongitude));

    TagholderMixin tagholder = poiholder.getTagholder();

    int specialByte = 0;
    // bit 1-4 represent the layer
    specialByte |= ((poiholder.poi.layer + 5) & MapfileHelper.POI_LAYER_BITMASK) << MapfileHelper.POI_LAYER_SHIFT;
    // bit 5-8 represent the number of tag IDs
    specialByte |= (tagholder.tagholders.length & MapfileHelper.POI_NUMBER_OF_TAGS_BITMASK);
    writebuffer.appendInt1(specialByte);
    tagholder.writeTags(writebuffer);

    // get the feature bitmask (1 byte)
    int featureByte = 0;
    // bit 1-3 enable optional features
    if (tagholder.featureName != null) featureByte |= MapfileHelper.POI_FEATURE_NAME;
    if (tagholder.featureHouseNumber != null) featureByte |= MapfileHelper.POI_FEATURE_HOUSE_NUMBER;
    if (tagholder.featureElevation != null) featureByte |= MapfileHelper.POI_FEATURE_ELEVATION;
    writebuffer.appendInt1(featureByte);
    if (tagholder.featureName != null) {
      writebuffer.appendString(tagholder.featureName!);
    }
    if (tagholder.featureHouseNumber != null) {
      writebuffer.appendString(tagholder.featureHouseNumber!);
    }
    if (tagholder.featureElevation != null) {
      writebuffer.appendSignedInt(tagholder.featureElevation!);
    }
  }

  void _writePoiSignature(PointOfInterest poi, bool debugFile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("***POIStart${poi.hashCode}***".padRight(MapfileHelper.SIGNATURE_LENGTH_POI, " "));
    }
  }
}
