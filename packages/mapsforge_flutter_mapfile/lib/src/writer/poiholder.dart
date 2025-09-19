import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/helper/mapfile_helper.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/tagholder_mixin.dart';

/// A data holder for a single Point of Interest (POI) during the map file
/// writing process.
///
/// This class encapsulates a [PointOfInterest] and uses the [TagholderMixin]
/// to manage the analysis and serialization of its tags.
class Poiholder with TagholderMixin {
  final PointOfInterest poi;

  Poiholder(this.poi);

    /// Analyzes the tags of the POI, counting their occurrences and preparing them
  /// for serialization.
  void analyze(List<Tagholder> tagholders, String? languagesPreference) {
    if (languagesPreference != null) super.languagesPreference.addAll(languagesPreference.split(","));
    analyzeTags(poi.tags, tagholders);
  }

    /// Serializes the POI data to a [Writebuffer].
  ///
  /// This must be called after the tags have been analyzed and sorted.
  /// [debugFile] determines whether to include a debug signature.
  /// [tileLatitude] and [tileLongitude] are the base coordinates from which the
  /// POI's delta-encoded position is calculated.
  Writebuffer writePoidata(bool debugFile, double tileLatitude, double tileLongitude) {
    Writebuffer writebuffer = Writebuffer();
    _writePoiSignature(debugFile, writebuffer);
    writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(poi.position.latitude - tileLatitude));
    writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(poi.position.longitude - tileLongitude));

    int specialByte = 0;
    // bit 1-4 represent the layer
    specialByte |= ((poi.layer + 5) & MapfileHelper.POI_LAYER_BITMASK) << MapfileHelper.POI_LAYER_SHIFT;
    // bit 5-8 represent the number of tag IDs
    specialByte |= (tagholders.length & MapfileHelper.POI_NUMBER_OF_TAGS_BITMASK);
    writebuffer.appendInt1(specialByte);
    writeTags(writebuffer);

    // get the feature bitmask (1 byte)
    int featureByte = 0;
    // bit 1-3 enable optional features
    if (featureName != null) featureByte |= MapfileHelper.POI_FEATURE_NAME;
    if (featureHouseNumber != null) featureByte |= MapfileHelper.POI_FEATURE_HOUSE_NUMBER;
    if (featureElevation != null) featureByte |= MapfileHelper.POI_FEATURE_ELEVATION;
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
      writebuffer.appendStringWithoutLength("***POIStart${poi.hashCode}***".padRight(MapfileHelper.SIGNATURE_LENGTH_POI, " "));
    }
  }
}
