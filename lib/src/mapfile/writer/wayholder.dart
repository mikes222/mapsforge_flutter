import 'package:mapsforge_flutter/src/mapfile/writer/tagholer_mixin.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';

import '../../../core.dart';
import '../../../datastore.dart';
import '../mapfile_helper.dart';
import 'mapfile_writer.dart';

/// Holds one way and its tags
class Wayholder with TagholderMixin {
  final Way way;

  int tileBitmask = 0xffff;

  int otherZoomlevel = -1;

  Wayholder(this.way, List<Tagholder> tagholders) {
    this.tagholders = analyzeTags(way.tags, tagholders);
  }

  void setSubTileBitmap(int idx) {
    tileBitmask |= 1 << idx;
    //print("setSubTileBitmap $idx 0x${tileBitmask.toRadixString(16)} for $way");
  }

  void _writeWaySignature(bool debugFile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("---WayStart${way.hashCode}---"
          .padRight(MapfileHelper.SIGNATURE_LENGTH_WAY, " "));
    }
  }

  void usedFor(int otherZoomlevel) {
    if (this.otherZoomlevel < otherZoomlevel)
      this.otherZoomlevel = otherZoomlevel;
  }

  /// can be done when the tags are sorted
  Writebuffer writeWaydata(
      bool debugFile, double tileLatitude, double tileLongitude) {
    Writebuffer writebuffer3 = Writebuffer();
    _writeWaySignature(debugFile, writebuffer3);
    Writebuffer writebuffer =
        _writeWayPropertyAndWayData(way, tileLatitude, tileLongitude);
    // get the size of the way (VBE-U)
    writebuffer3.appendUnsignedInt(writebuffer.length);
    writebuffer3.appendWritebuffer(writebuffer);
    return writebuffer3;
  }

  Writebuffer _writeWayPropertyAndWayData(
      Way way, double tileLatitude, double tileLongitude) {
    assert(way.latLongs.isNotEmpty);

    Writebuffer writebuffer = Writebuffer();

    if (otherZoomlevel >= 0) {
      // todo not working for an unknown reason. I miss the ways for most zoomlevels.
      tileBitmask = 0xffff;
    }

    /// A tile on zoom level z is made up of exactly 16 sub tiles on zoom level z+2
    // for each sub tile (row-wise, left to right):
    // 1 bit that represents a flag whether the way is relevant for the sub tile
    // Special case: coastline ways must always have all 16 bits set.
    writebuffer.appendInt2(tileBitmask);

    int specialByte = 0;
    // bit 1-4 represent the layer
    specialByte |= ((way.layer + 5) & MapfileHelper.POI_LAYER_BITMASK) <<
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
    if (featureRef != null) featureByte |= MapfileHelper.WAY_FEATURE_REF;
    bool featureLabelPosition = way.labelPosition != null;
    if (featureLabelPosition)
      featureByte |= MapfileHelper.WAY_FEATURE_LABEL_POSITION;
    // number of way data blocks or false if we have only 1
    bool featureWayDataBlocksByte = false; //way.latLongs.length > 1;
    if (featureWayDataBlocksByte)
      featureByte |= MapfileHelper.WAY_FEATURE_DATA_BLOCKS_BYTE;

    Writebuffer singleWritebuffer =
        _writeSingleDeltaEncoding(way, tileLatitude, tileLongitude);
    Writebuffer doubleWritebuffer =
        _writeDoubleDeltaEncoding(way, tileLatitude, tileLongitude);
    bool featureWayDoubleDeltaEncoding =
        doubleWritebuffer.length < singleWritebuffer.length;
    if (featureWayDoubleDeltaEncoding)
      featureByte |= MapfileHelper.WAY_FEATURE_DOUBLE_DELTA_ENCODING;

    writebuffer.appendInt1(featureByte);

    // check if the POI has a name
    if (featureName != null) {
      writebuffer.appendString(way.getTag(MapfileHelper.TAG_KEY_NAME)!);
    }

    // check if the POI has a house number
    if (featureHouseNumber != null) {
      writebuffer.appendString(way.getTag(MapfileHelper.TAG_KEY_HOUSE_NUMBER)!);
    }

    // check if the way has a reference
    if (featureRef != null) {
      writebuffer.appendString(way.getTag(MapfileHelper.TAG_KEY_REF)!);
    }

    if (featureLabelPosition) {
      writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
          way.labelPosition!.latitude - way.latLongs[0][0].latitude));
      writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
          way.labelPosition!.longitude - way.latLongs[0][0].longitude));
    }

    if (featureWayDataBlocksByte) {
      writebuffer.appendUnsignedInt(way.latLongs.length);
    }

    if (featureWayDoubleDeltaEncoding)
      writebuffer.appendWritebuffer(doubleWritebuffer);
    else
      writebuffer.appendWritebuffer(singleWritebuffer);
    return writebuffer;
  }

  /// Way data block
  Writebuffer _writeSingleDeltaEncoding(
      Way way, double tileLatitude, double tileLongitude) {
    Writebuffer writebuffer = Writebuffer();
    writebuffer.appendUnsignedInt(way.latLongs.length);
    for (List<ILatLong> waySegment in way.latLongs) {
      writebuffer.appendUnsignedInt(waySegment.length);
      bool first = true;
      double previousLatitude = 0;
      double previousLongitude = 0;
      for (ILatLong coordinate in waySegment) {
        if (first) {
          previousLatitude = coordinate.latitude - tileLatitude;
          previousLongitude = coordinate.longitude - tileLongitude;
          writebuffer.appendSignedInt(
              LatLongUtils.degreesToMicrodegrees(previousLatitude));
          writebuffer.appendSignedInt(
              LatLongUtils.degreesToMicrodegrees(previousLongitude));
          first = false;
        } else {
          double currentLatitude = coordinate.latitude - tileLatitude;
          double currentLongitude = coordinate.longitude - tileLongitude;

          writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
              currentLatitude - previousLatitude));
          writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
              currentLongitude - previousLongitude));

          previousLatitude = currentLatitude;
          previousLongitude = currentLongitude;
        }
      }
    }
    return writebuffer;
  }

  /// Way data block
  Writebuffer _writeDoubleDeltaEncoding(
      Way way, double tileLatitude, double tileLongitude) {
    Writebuffer writebuffer = Writebuffer();
    writebuffer.appendUnsignedInt(way.latLongs.length);
    for (List<ILatLong> waySegment in way.latLongs) {
      writebuffer.appendUnsignedInt(waySegment.length);
      bool first = true;
      double previousLatitude = 0;
      double previousLongitude = 0;
      double previousLatitudeDelta = 0;
      double previousLongitudeDelta = 0;
      for (ILatLong coordinate in waySegment) {
        if (first) {
          previousLatitude = coordinate.latitude - tileLatitude;
          previousLongitude = coordinate.longitude - tileLongitude;
          writebuffer.appendSignedInt(
              LatLongUtils.degreesToMicrodegrees(previousLatitude));
          writebuffer.appendSignedInt(
              LatLongUtils.degreesToMicrodegrees(previousLongitude));
          first = false;
        } else {
          double currentLatitude = coordinate.latitude - tileLatitude;
          double currentLongitude = coordinate.longitude - tileLongitude;

          double deltaLatitude = currentLatitude - previousLatitude;
          double deltaLongitude = currentLongitude - previousLongitude;

          writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
              deltaLatitude - previousLatitudeDelta));
          writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
              deltaLongitude - previousLongitudeDelta));

          previousLatitude = currentLatitude;
          previousLongitude = currentLongitude;

          previousLatitudeDelta = deltaLatitude;
          previousLongitudeDelta = deltaLongitude;
        }
      }
    }
    return writebuffer;
  }
}
