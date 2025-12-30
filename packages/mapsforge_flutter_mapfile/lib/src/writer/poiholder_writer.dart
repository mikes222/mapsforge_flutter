import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/helper/mapfile_helper.dart';

class PoiholderWriter {
  /// Serializes the POI data to a [Writebuffer].
  ///
  /// This must be called after the tags have been analyzed and sorted.
  /// [debugFile] determines whether to include a debug signature.
  /// [tileLatitude] and [tileLongitude] are the base coordinates from which the
  /// POI's delta-encoded position is calculated.
  void writePoidata(
    Writebuffer writebuffer,
    Poiholder poiholder,
    bool debugFile,
    double tileLatitude,
    double tileLongitude,
    List<String> languagesPreferences,
  ) {
    _writePoiSignature(poiholder, debugFile, writebuffer);
    writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(poiholder.position.latitude - tileLatitude));
    writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(poiholder.position.longitude - tileLongitude));

    String? featureHouseNumber = poiholder.tagholderCollection.extractHousenumber();
    int? featureElevation = poiholder.tagholderCollection.extractElevation();
    //String? featureRef = poiholder.tagholderCollection.extractRef();
    String? featureName = poiholder.tagholderCollection.extractName(languagesPreferences);
    int layer = poiholder.tagholderCollection.extractLayer();
    Writebuffer writebufferTags = Writebuffer();
    int count = poiholder.tagholderCollection.writePoiTags(writebufferTags);

    int specialByte = 0;
    // bit 1-4 represent the layer
    specialByte |= ((layer + 5) & MapfileHelper.POI_LAYER_BITMASK) << MapfileHelper.POI_LAYER_SHIFT;
    // bit 5-8 represent the number of tag IDs
    specialByte |= (count & MapfileHelper.POI_NUMBER_OF_TAGS_BITMASK);
    writebuffer.appendInt1(specialByte);
    writebuffer.appendWritebuffer(writebufferTags);
    writebufferTags.clear();

    // get the feature bitmask (1 byte)
    int featureByte = 0;
    // bit 1-3 enable optional features
    if (featureName != null) featureByte |= MapfileHelper.POI_FEATURE_NAME;
    if (featureHouseNumber != null) featureByte |= MapfileHelper.POI_FEATURE_HOUSE_NUMBER;
    if (featureElevation != null) featureByte |= MapfileHelper.POI_FEATURE_ELEVATION;
    writebuffer.appendInt1(featureByte);
    if (featureName != null) {
      writebuffer.appendString(featureName);
    }
    if (featureHouseNumber != null) {
      writebuffer.appendString(featureHouseNumber);
    }
    if (featureElevation != null) {
      writebuffer.appendSignedInt(featureElevation);
    }
  }

  void _writePoiSignature(Poiholder poi, bool debugFile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("***POIStart${poi.hashCode}***".padRight(MapfileHelper.SIGNATURE_LENGTH_POI, " "));
    }
  }
}
