import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';

import '../../../core.dart';
import '../../../datastore.dart';
import '../mapfile_helper.dart';
import 'mapfile_writer.dart';

/// Holds one way and its tags
class Wayholder {
  final bool debugFile;

  final Way way;

  List<Tagholder> tagholders = [];

  String? featureName;

  String? featureHouseNumber;

  int? featureElevation;

  String? featureRef;

  int tileBitmask = 0xffff;

  Wayholder(this.debugFile, this.way, List<Tagholder> tagholders) {
    this.tagholders = _analyzeTags(way.tags, tagholders);
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
      // only for ways:
      if (tag.key == MapfileHelper.TAG_KEY_REF) {
        featureRef = tag.value;
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

  void _writeWaySignature(Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("---WayStart${way.hashCode}---"
          .padRight(MapfileHelper.SIGNATURE_LENGTH_WAY, " "));
    }
  }

  /// can be done when the tags are sorted
  Writebuffer writeWaydata(double tileLatitude, double tileLongitude) {
    Writebuffer writebuffer3 = Writebuffer();
    _writeWaySignature(writebuffer3);
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
    tagholders.forEach(
        (tagholder) => writebuffer.appendUnsignedInt(tagholder.index!));

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
    bool featureWayDoubleDeltaEncoding = false;
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
      _writeDoubleDeltaEncoding(writebuffer, way, tileLatitude, tileLongitude);
    else
      _writeSingleDeltaEncoding(writebuffer, way, tileLatitude, tileLongitude);
    return writebuffer;
  }

  /// Way data block
  void _writeSingleDeltaEncoding(Writebuffer writebuffer, Way way,
      double tileLatitude, double tileLongitude) {
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
  }

  /// Way data block
  void _writeDoubleDeltaEncoding(Writebuffer writebuffer, Way way,
      double tileLatitude, double tileLongitude) {
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
  }
}
