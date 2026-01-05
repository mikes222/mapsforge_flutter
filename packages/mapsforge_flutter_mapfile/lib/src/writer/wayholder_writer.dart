import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/helper/mapfile_helper.dart';

class WayholderWriter {
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
  int _computeBitmask(Wayholder wayholder, Tile tile) {
    List<Tile> subtiles = tile.getGrandchilds();

    int tileBitmask = 0;
    int tileCounter = 1 << 15;
    BoundingBox boundingBox = wayholder.boundingBoxCached;
    for (Tile subtile in subtiles) {
      if (subtile.getBoundingBox().intersects(boundingBox) ||
          subtile.getBoundingBox().containsBoundingBox(boundingBox) ||
          boundingBox.containsBoundingBox(subtile.getBoundingBox())) {
        tileBitmask |= tileCounter;
      }
      tileCounter = tileCounter >> 1;
    }
    // if (tile.zoomLevel <= 4) {
    //   print("$tile 0x${tileBitmask.toRadixString(16)} for ${this.toStringWithoutNames()} $boundingBoxCached");
    //   _closedOuters.where((test) => test.length < 3).forEach((test) => print("  test in compute: $test ${test.path}"));
    // }
    return tileBitmask;
  }

  /// can be done when the tags are sorted
  void writeWaydata(
    Writebuffer writebuffer,
    Wayholder wayholder,
    bool debugFile,
    Tile tile,
    double tileLatitude,
    double tileLongitude,
    List<String> languagesPreferences,
    TagholderModel model,
  ) {
    int tileBitmask = _computeBitmask(wayholder, tile);
    _writeWaySignature(writebuffer, debugFile);
    Writebuffer writebuffer2 = Writebuffer();
    _writeWayPropertyAndWayData(writebuffer2, wayholder, tileLatitude, tileLongitude, tileBitmask, languagesPreferences, model);
    // get the size of the way (VBE-U)
    writebuffer.appendUnsignedInt(writebuffer2.length);
    writebuffer.appendWritebuffer(writebuffer2);
  }

  void _writeWaySignature(Writebuffer writebuffer, bool debugFile) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("---WayStart$hashCode---".padRight(MapfileHelper.SIGNATURE_LENGTH_WAY, " "));
    }
  }

  void _writeWayPropertyAndWayData(
    Writebuffer writebuffer,
    Wayholder wayholder,
    double tileLatitude,
    double tileLongitude,
    int tileBitmask,
    List<String> languagesPreferences,
    TagholderModel model,
  ) {
    String? featureHouseNumber = wayholder.tagholderCollection.extractHousenumber();
    //int? featureElevation = wayholder.tagholderCollection.extractElevation();
    String? featureRef = wayholder.tagholderCollection.extractRef();
    String? featureName = wayholder.tagholderCollection.extractName(languagesPreferences);
    int layer = wayholder.tagholderCollection.extractLayer();

    assert(layer >= -5, "layer=${layer}");
    assert(layer <= 10);

    /// A tile on zoom level z is made up of exactly 16 sub tiles on zoom level z+2
    // for each sub tile (row-wise, left to right):
    // 1 bit that represents a flag whether the way is relevant for the sub tile
    // Special case: coastline ways must always have all 16 bits set.
    writebuffer.appendUInt2(tileBitmask);
    Writebuffer writebufferTags = Writebuffer();
    int count = wayholder.tagholderCollection.writeWayTags(writebufferTags, model);

    int specialByte = 0;
    // bit 1-4 represent the layer
    specialByte |= ((layer + 5) & MapfileHelper.POI_LAYER_BITMASK) << MapfileHelper.POI_LAYER_SHIFT;
    // bit 5-8 represent the number of tag IDs
    specialByte |= (count & MapfileHelper.POI_NUMBER_OF_TAGS_BITMASK);
    writebuffer.appendInt1(specialByte);
    writebuffer.appendWritebuffer(writebufferTags);
    writebufferTags.clear();

    Waypath master = wayholder.extractMaster();

    // get the feature bitmask (1 byte)
    int featureByte = 0;
    // bit 1-3 enable optional features
    if (featureName != null) featureByte |= MapfileHelper.WAY_FEATURE_NAME;
    if (featureHouseNumber != null) featureByte |= MapfileHelper.WAY_FEATURE_HOUSE_NUMBER;
    if (featureRef != null) featureByte |= MapfileHelper.WAY_FEATURE_REF;
    bool featureLabelPosition = wayholder.labelPosition != null;
    if (featureLabelPosition) featureByte |= MapfileHelper.WAY_FEATURE_LABEL_POSITION;
    // number of way data blocks or false if we have only 1
    bool featureWayDataBlocksByte = wayholder.openOutersIsNotEmpty() | wayholder.closedOutersIsNotEmpty();
    if (featureWayDataBlocksByte) featureByte |= MapfileHelper.WAY_FEATURE_DATA_BLOCKS_BYTE;

    bool? expectDouble;
    // less than 10 coordinates? Use singe encoding
    int sum = wayholder.nodeCount();
    if (sum <= 30) {
      expectDouble = false;
    } else if (sum >= 100) {
      expectDouble = true;
    }
    Writebuffer singleWritebuffer = Writebuffer();
    if (expectDouble == null || !expectDouble) {
      _writeSingleDeltaEncoding(singleWritebuffer, [master, ...wayholder.innerRead], tileLatitude, tileLongitude);
      for (var action in wayholder.closedOutersRead) {
        _writeSingleDeltaEncoding(singleWritebuffer, [action], tileLatitude, tileLongitude);
      }
      for (var action in wayholder.openOutersRead) {
        _writeSingleDeltaEncoding(singleWritebuffer, [action], tileLatitude, tileLongitude);
      }
    }

    Writebuffer doubleWritebuffer = Writebuffer();
    if (expectDouble == null || expectDouble) {
      _writeDoubleDeltaEncoding(doubleWritebuffer, [master, ...wayholder.innerRead], tileLatitude, tileLongitude);
      for (var action in wayholder.closedOutersRead) {
        _writeDoubleDeltaEncoding(doubleWritebuffer, [action], tileLatitude, tileLongitude);
      }
      for (var action in wayholder.openOutersRead) {
        _writeDoubleDeltaEncoding(doubleWritebuffer, [action], tileLatitude, tileLongitude);
      }
    }

    bool featureWayDoubleDeltaEncoding = singleWritebuffer.length == 0
        ? true
        : doubleWritebuffer.length == 0
        ? false
        : doubleWritebuffer.length < singleWritebuffer.length;
    if (featureWayDoubleDeltaEncoding) featureByte |= MapfileHelper.WAY_FEATURE_DOUBLE_DELTA_ENCODING;

    writebuffer.appendInt1(featureByte);

    if (featureName != null) {
      writebuffer.appendString(featureName);
    }
    if (featureHouseNumber != null) {
      writebuffer.appendString(featureHouseNumber);
    }
    if (featureRef != null) {
      writebuffer.appendString(featureRef);
    }

    if (featureLabelPosition) {
      ILatLong first = master.first;
      writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(wayholder.labelPosition!.latitude - first.latitude));
      writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(wayholder.labelPosition!.longitude - first.longitude));
    }

    if (featureWayDataBlocksByte) {
      writebuffer.appendUnsignedInt(wayholder.closedOutersLength() + wayholder.openOutersLength() + 1);
    }

    if (featureWayDoubleDeltaEncoding) {
      writebuffer.appendWritebuffer(doubleWritebuffer);
    } else {
      writebuffer.appendWritebuffer(singleWritebuffer);
    }
  }

  /// Way data block
  void _writeSingleDeltaEncoding(Writebuffer writebuffer, List<Waypath> waypaths, double tileLatitude, double tileLongitude) {
    // amount of following way coordinate blocks (see docu)
    if (waypaths.isEmpty) return;
    assert(waypaths.length <= 32767, "${waypaths.length} too much");
    writebuffer.appendUnsignedInt(waypaths.length);
    for (Waypath waypath in waypaths) {
      assert(waypath.length >= 2, "${waypath.length} too little");
      assert(waypath.length <= 32767, "${waypath.length} too much");
      // amount of way nodes of this way (see docu)
      writebuffer.appendUnsignedInt(waypath.length);
      bool first = true;
      double previousLatitude = 0;
      double previousLongitude = 0;
      for (ILatLong coordinate in waypath.path) {
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
  void _writeDoubleDeltaEncoding(Writebuffer writebuffer, List<Waypath> waypaths, double tileLatitude, double tileLongitude) {
    // amount of following way coordinate blocks (see docu)
    if (waypaths.isEmpty) return;
    assert(waypaths.length <= 32767, "${waypaths.length} too much");
    writebuffer.appendUnsignedInt(waypaths.length);
    for (Waypath waypath in waypaths) {
      assert(waypath.length >= 2, "${waypath.length} too little");
      assert(waypath.length <= 32767, "${waypath.length} too much");
      // amount of way nodes of this way (see docu)
      writebuffer.appendUnsignedInt(waypath.length);
      bool first = true;
      // I had to switch to int because I had rounding errors which summed up so that a closed waypoint was not recognized as closed anymore
      int previousLatitude = 0;
      int previousLongitude = 0;
      int previousLatitudeDelta = 0;
      int previousLongitudeDelta = 0;
      for (ILatLong coordinate in waypath.path) {
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
}
