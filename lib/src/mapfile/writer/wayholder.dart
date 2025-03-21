import 'package:mapsforge_flutter/src/mapfile/writer/tagholder_mixin.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';

import '../../../core.dart';
import '../../../datastore.dart';
import '../mapfile_helper.dart';
import 'mapfile_writer.dart';

/// Holds one way and its tags
class Wayholder with TagholderMixin {
  Way way;

  int tileBitmask = 0xffff;

  /// PBF supports relations with multiple outer ways. Mapfile requires to
  /// store this outer ways as additional Way data blocks and split it into
  /// several ways - all with the same way properties - when reading the file.
  List<List<ILatLong>> otherOuters = [];

  bool mergedWithOtherWay = false;

  Wayholder(this.way) {}

  Wayholder cloneWith({Way? way, List<List<ILatLong>>? otherOuters}) {
    Wayholder result = Wayholder(way ?? this.way);
    result.otherOuters = otherOuters ?? this.otherOuters;
    result.tileBitmask = this.tileBitmask;
    result.tagholders = this.tagholders;
    result.featureElevation = this.featureElevation;
    result.featureHouseNumber = this.featureHouseNumber;
    result.featureName = this.featureName;
    result.featureRef = this.featureRef;
    result.mergedWithOtherWay = this.mergedWithOtherWay;
    result.languagesPreference = this.languagesPreference;
    result.tagholders = this.tagholders;
    return result;
  }

  /// A tile on zoom level <i>z</i> has exactly 16 sub tiles on zoom level <i>z+2</i>. For each of these 16 sub tiles
  /// it is analyzed if the given way needs to be included. The result is represented as a 16 bit short value. Each bit
  /// represents one of the 16 sub tiles. A bit is set to 1 if the sub tile needs to include the way. Representation is
  /// row-wise.
  ///
  /// @param geometry           the geometry which is analyzed
  /// @param tile               the tile which is split into 16 sub tiles
  /// @param enlargementInMeter amount of pixels that is used to enlarge the bounding box of the way and the tiles in the mapping
  ///                           process
  /// @return a 16 bit short value that represents the information which of the sub tiles needs to include the way
  void _computeBitmask(Way way, Tile tile, final int enlargementInMeter) {
    List<Tile> subtiles = tile.getGrandchilds();

    tileBitmask = 0;
    int tileCounter = 1 << 15;
    BoundingBox boundingBox = way.getBoundingBox();
    for (Tile subtile in subtiles) {
      if (subtile.getBoundingBox().intersects(boundingBox) ||
          subtile.getBoundingBox().containsBoundingBox(boundingBox) ||
          boundingBox.containsBoundingBox(subtile.getBoundingBox())) {
        tileBitmask |= tileCounter;
      }
      // print(
      //     "$tile -> $subtile 0x${tileBitmask.toRadixString(16)} $tileCounter");
      tileCounter = tileCounter >> 1;
    }
  }

  void analyze(List<Tagholder> tagholders, String? languagesPreference) {
    if (languagesPreference != null) super.languagesPreference.addAll(languagesPreference.split(","));
    analyzeTags(way.tags, tagholders);
  }

  /// can be done when the tags are sorted
  Writebuffer writeWaydata(bool debugFile, Tile tile, double tileLatitude, double tileLongitude) {
    _computeBitmask(way, tile, 0);
    Writebuffer writebuffer3 = Writebuffer();
    _writeWaySignature(debugFile, writebuffer3);
    Writebuffer writebuffer = _writeWayPropertyAndWayData(way, tileLatitude, tileLongitude);
    // get the size of the way (VBE-U)
    writebuffer3.appendUnsignedInt(writebuffer.length);
    writebuffer3.appendWritebuffer(writebuffer);
    return writebuffer3;
  }

  void _writeWaySignature(bool debugFile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("---WayStart${way.hashCode}---".padRight(MapfileHelper.SIGNATURE_LENGTH_WAY, " "));
    }
  }

  Writebuffer _writeWayPropertyAndWayData(Way way, double tileLatitude, double tileLongitude) {
    assert(way.latLongs.isNotEmpty);

    Writebuffer writebuffer = Writebuffer();

    /// A tile on zoom level z is made up of exactly 16 sub tiles on zoom level z+2
    // for each sub tile (row-wise, left to right):
    // 1 bit that represents a flag whether the way is relevant for the sub tile
    // Special case: coastline ways must always have all 16 bits set.
    writebuffer.appendUInt2(tileBitmask);

    int specialByte = 0;
    // bit 1-4 represent the layer
    specialByte |= ((way.layer + 5) & MapfileHelper.POI_LAYER_BITMASK) << MapfileHelper.POI_LAYER_SHIFT;
    // bit 5-8 represent the number of tag IDs
    specialByte |= (tagholders.length & MapfileHelper.POI_NUMBER_OF_TAGS_BITMASK);
    writebuffer.appendInt1(specialByte);
    writeTags(writebuffer);

    // get the feature bitmask (1 byte)
    int featureByte = 0;
    // bit 1-3 enable optional features
    if (featureName != null) featureByte |= MapfileHelper.POI_FEATURE_NAME;
    if (featureHouseNumber != null) featureByte |= MapfileHelper.POI_FEATURE_HOUSE_NUMBER;
    if (featureRef != null) featureByte |= MapfileHelper.WAY_FEATURE_REF;
    bool featureLabelPosition = way.labelPosition != null;
    if (featureLabelPosition) featureByte |= MapfileHelper.WAY_FEATURE_LABEL_POSITION;
    // number of way data blocks or false if we have only 1
    bool featureWayDataBlocksByte = otherOuters.isNotEmpty;
    if (featureWayDataBlocksByte) featureByte |= MapfileHelper.WAY_FEATURE_DATA_BLOCKS_BYTE;

    Writebuffer singleWritebuffer = Writebuffer();
    _writeSingleDeltaEncoding(singleWritebuffer, way.latLongs, tileLatitude, tileLongitude);
    otherOuters.forEach((List<ILatLong> outer) {
      _writeSingleDeltaEncoding(singleWritebuffer, [outer], tileLatitude, tileLongitude);
    });

    Writebuffer doubleWritebuffer = Writebuffer();
    _writeDoubleDeltaEncoding(doubleWritebuffer, way.latLongs, tileLatitude, tileLongitude);
    otherOuters.forEach((List<ILatLong> outer) {
      _writeDoubleDeltaEncoding(doubleWritebuffer, [outer], tileLatitude, tileLongitude);
    });

    bool featureWayDoubleDeltaEncoding = doubleWritebuffer.length < singleWritebuffer.length;
    if (featureWayDoubleDeltaEncoding) featureByte |= MapfileHelper.WAY_FEATURE_DOUBLE_DELTA_ENCODING;

    writebuffer.appendInt1(featureByte);

    if (featureName != null) {
      writebuffer.appendString(featureName!);
    }
    if (featureHouseNumber != null) {
      writebuffer.appendString(featureHouseNumber!);
    }
    if (featureRef != null) {
      writebuffer.appendString(featureRef!);
    }

    if (featureLabelPosition) {
      writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(way.labelPosition!.latitude - way.latLongs[0][0].latitude));
      writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(way.labelPosition!.longitude - way.latLongs[0][0].longitude));
    }

    if (featureWayDataBlocksByte) {
      writebuffer.appendUnsignedInt(otherOuters.length + 1);
    }

    if (featureWayDoubleDeltaEncoding)
      writebuffer.appendWritebuffer(doubleWritebuffer);
    else
      writebuffer.appendWritebuffer(singleWritebuffer);
    return writebuffer;
  }

  /// Way data block
  void _writeSingleDeltaEncoding(Writebuffer writebuffer, List<List<ILatLong>> latLongs, double tileLatitude, double tileLongitude) {
    // amount of following way coordinate blocks (see docu)
    writebuffer.appendUnsignedInt(latLongs.length);
    for (List<ILatLong> waySegment in latLongs) {
      assert(waySegment.length <= 32767, "${waySegment.length} too much for $this");
      // amount of way nodes of this way (see docu)
      writebuffer.appendUnsignedInt(waySegment.length);
      bool first = true;
      double previousLatitude = 0;
      double previousLongitude = 0;
      for (ILatLong coordinate in waySegment) {
        if (first) {
          previousLatitude = coordinate.latitude - tileLatitude;
          previousLongitude = coordinate.longitude - tileLongitude;
          writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(previousLatitude));
          writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(previousLongitude));
          first = false;
        } else {
          double currentLatitude = coordinate.latitude - tileLatitude;
          double currentLongitude = coordinate.longitude - tileLongitude;

          writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(currentLatitude - previousLatitude));
          writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(currentLongitude - previousLongitude));

          previousLatitude = currentLatitude;
          previousLongitude = currentLongitude;
        }
      }
    }
  }

  /// Way data block
  void _writeDoubleDeltaEncoding(Writebuffer writebuffer, latLongs, double tileLatitude, double tileLongitude) {
    // amount of following way coordinate blocks (see docu)
    writebuffer.appendUnsignedInt(latLongs.length);
    for (List<ILatLong> waySegment in latLongs) {
      assert(waySegment.length <= 32767, "${waySegment.length} too much for $this");
      // amount of way nodes of this way (see docu)
      writebuffer.appendUnsignedInt(waySegment.length);
      bool first = true;
      // I had to switch to int because I had rounding errors which summed up so that a closed waypoint was not recognized as closed anymore
      int previousLatitude = 0;
      int previousLongitude = 0;
      int previousLatitudeDelta = 0;
      int previousLongitudeDelta = 0;
      for (ILatLong coordinate in waySegment) {
        if (first) {
          previousLatitude = LatLongUtils.degreesToMicrodegrees(coordinate.latitude - tileLatitude);
          previousLongitude = LatLongUtils.degreesToMicrodegrees(coordinate.longitude - tileLongitude);
          writebuffer.appendSignedInt(previousLatitude);
          writebuffer.appendSignedInt(previousLongitude);
          first = false;
        } else {
          int currentLatitude = LatLongUtils.degreesToMicrodegrees(coordinate.latitude - tileLatitude);
          int currentLongitude = LatLongUtils.degreesToMicrodegrees(coordinate.longitude - tileLongitude);

          int deltaLatitude = currentLatitude - previousLatitude;
          int deltaLongitude = currentLongitude - previousLongitude;

          writebuffer.appendSignedInt(deltaLatitude - previousLatitudeDelta);
          writebuffer.appendSignedInt(deltaLongitude - previousLongitudeDelta);

          previousLatitude = currentLatitude;
          previousLongitude = currentLongitude;

          previousLatitudeDelta = deltaLatitude;
          previousLongitudeDelta = deltaLongitude;
        }
      }
    }
  }

  @override
  String toString() {
    return 'Wayholder{tileBitmask: 0x${tileBitmask.toRadixString(16)}, otherOuters: ${otherOuters.length}, mergedWithOtherWay: $mergedWithOtherWay}, way $way';
  }
}
