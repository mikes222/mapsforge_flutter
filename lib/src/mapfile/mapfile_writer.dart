import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfile.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfile_header_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/subfileparameter.dart';
import 'package:mapsforge_flutter/src/mapfile/writebuffer.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';

import 'mapfile_helper.dart';

/// see https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md
class MapfileWriter {
  void write(
      String filename, MapFile mapfile, List<Tag> poiTags, List<Tag> wayTags) {
    File file = new File(filename);
    IOSink sink = file.openWrite();
    MapfileHeaderWriter mapfileHeaderWriter =
        MapfileHeaderWriter(mapfile.getMapHeaderInfo());
    mapfileHeaderWriter.write(sink);
    //_writePoidata(mapfile, pois, tileLatitude, tileLongitude, poiTags);
//    _writeWayProperties(mapfile, ways, wayTags);
    Writebuffer writebuffer = Writebuffer();
    _writeTags(writebuffer, poiTags);
    _writeTags(writebuffer, wayTags);
    _writeSubFileParameters(sink, mapfile.getMapFileInfo().subFileParameters);
    sink.close();
  }

  void _writeSubFileParameters(
      IOSink sink, Map<int, SubFileParameter> subFileParameters) {
    Writebuffer writebuffer = Writebuffer();
    writebuffer.appendInt1(subFileParameters.length);

    subFileParameters.forEach((int key, SubFileParameter value) {
      _writeSubFileParameter(value);
    });
  }

  void _writeSubFileParameter(SubFileParameter subFileParameter) {
    Writebuffer writebuffer = Writebuffer();
    writebuffer.appendInt1(subFileParameter.baseZoomLevel);
    writebuffer.appendInt1(subFileParameter.zoomLevelMin);
    writebuffer.appendInt1(subFileParameter.zoomLevelMax);
    // 8 byte start address
    writebuffer.appendInt8(subFileParameter.startAddress);
    // size of the sub-file as 8-byte LONG
    writebuffer.appendInt8(subFileParameter.subFileSize);
  }

  void _writeTags(Writebuffer writebuffer, List<Tag> tags) {
    writebuffer.appendInt2(tags.length);
    for (Tag tag in tags) {
      String value = "${tag.key}=${tag.value}";
      writebuffer.appendString(value);
    }
  }

  /**
   * Processes the block signature, if present.
   *
   * @return true if the block signature could be processed successfully, false otherwise.
   */
  void _writeHeaderSignature(MapFile mapFile, Writebuffer writeBuffer) {
    if (mapFile.getMapHeaderInfo().debugFile) {
      writeBuffer.appendString(
          "###TileStart".padRight(MapFile.SIGNATURE_LENGTH_BLOCK, " "));
    }
  }

  void _writeIndexHeaderSignature(MapFile mapFile, Writebuffer writeBuffer) {
    if (mapFile.getMapHeaderInfo().debugFile) {
      writeBuffer.appendString("+++IndexStart+++");
    }
  }

  void _writePoiSignature(MapFile mapFile, Writebuffer writeBuffer) {
    if (mapFile.getMapHeaderInfo().debugFile) {
      writeBuffer.appendString(
          "***POIStart".padRight(MapfileHelper.SIGNATURE_LENGTH_POI, " "));
    }
  }

  void _writeWaySignature(MapFile mapFile, Writebuffer writeBuffer) {
    if (mapFile.getMapHeaderInfo().debugFile) {
      writeBuffer.appendString(
          "---WayStart".padRight(MapfileHelper.SIGNATURE_LENGTH_WAY, " "));
    }
  }

  void _writePoidata(MapFile mapFile, List<PointOfInterest> pois,
      double tileLatitude, double tileLongitude, List<Tag> tagsArray) {
    Writebuffer writebuffer = Writebuffer();
    _writePoiSignature(mapFile, writebuffer);
    for (PointOfInterest poi in pois) {
      writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
          poi.position.latitude - tileLatitude));
      writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
          poi.position.longitude - tileLongitude));
      int specialByte = 0;
      // bit 1-4 represent the layer
      specialByte |= (poi.layer & MapfileHelper.POI_LAYER_BITMASK) <<
          MapfileHelper.POI_LAYER_SHIFT;
      // bit 5-8 represent the number of tag IDs
      specialByte |=
          (poi.tags.length & MapfileHelper.POI_NUMBER_OF_TAGS_BITMASK);
      writebuffer.appendInt1(specialByte);
      _calculateTags(writebuffer, poi.tags, tagsArray);

      // get the feature bitmask (1 byte)
      int featureByte = 0;
      // bit 1-3 enable optional features
      bool featureName = poi.hasTag(MapfileHelper.TAG_KEY_NAME);
      if (featureName) featureByte |= MapfileHelper.POI_FEATURE_NAME;
      bool featureHouseNumber = poi.hasTag(MapfileHelper.TAG_KEY_HOUSE_NUMBER);
      if (featureHouseNumber)
        featureByte |= MapfileHelper.POI_FEATURE_HOUSE_NUMBER;
      bool featureElevation = poi.hasTag(MapfileHelper.TAG_KEY_ELE);
      if (featureElevation) featureByte |= MapfileHelper.POI_FEATURE_ELEVATION;
      writebuffer.appendInt1(featureByte);

      // check if the POI has a name
      if (featureName) {
        writebuffer.appendString(poi.getTag(MapfileHelper.TAG_KEY_NAME)!);
      }

      // check if the POI has a house number
      if (featureHouseNumber) {
        writebuffer
            .appendString(poi.getTag(MapfileHelper.TAG_KEY_HOUSE_NUMBER)!);
      }

      // check if the POI has an elevation
      if (featureElevation) {
        writebuffer
            .appendSignedInt(int.parse(poi.getTag(MapfileHelper.TAG_KEY_ELE)!));
      }
    }
  }

  void _calculateTags(
      Writebuffer writebuffer, List<Tag> tags, List<Tag> tagsArray) {
    for (Tag tag in tags) {
      Tag? tag2 = tagsArray.firstWhereOrNull((test) => test.key == tag.key);
      if (tag2 == null) {
        writebuffer.appendUnsignedInt(tagsArray.length);
        tagsArray.add(tag);
      } else {
        int tagId = tagsArray.indexWhere((test) => test.key == tag.key);
        writebuffer.appendUnsignedInt(tagId);
      }
    }
  }

  void _writeWayProperties(
      MapFile mapFile, List<Way> ways, List<Tag> tagsArray) {
    Writebuffer writebuffer = Writebuffer();
    _writeWaySignature(mapFile, writebuffer);
    // get the size of the way (VBE-U)
    int wayDataSize = ways.length;
    writebuffer.appendUnsignedInt(wayDataSize);
    for (Way way in ways) {
      /// A tile on zoom level z is made up of exactly 16 sub tiles on zoom level z+2
      // for each sub tile (row-wise, left to right):
      // 1 bit that represents a flag whether the way is relevant for the sub tile
      // Special case: coastline ways must always have all 16 bits set.
      int tileBitmask = 0;
      writebuffer.appendInt2(tileBitmask);

      int specialByte = 0;
      // bit 1-4 represent the layer
      specialByte |= (way.layer & MapfileHelper.POI_LAYER_BITMASK) <<
          MapfileHelper.POI_LAYER_SHIFT;
      // bit 5-8 represent the number of tag IDs
      specialByte |=
          (way.tags.length & MapfileHelper.POI_NUMBER_OF_TAGS_BITMASK);
      writebuffer.appendInt1(specialByte);
      _calculateTags(writebuffer, way.tags, tagsArray);

      // get the feature bitmask (1 byte)
      int featureByte = 0;
      // bit 1-3 enable optional features
      bool featureName = way.hasTag(MapfileHelper.TAG_KEY_NAME);
      if (featureName) featureByte |= MapfileHelper.POI_FEATURE_NAME;
      bool featureHouseNumber = way.hasTag(MapfileHelper.TAG_KEY_HOUSE_NUMBER);
      if (featureHouseNumber)
        featureByte |= MapfileHelper.POI_FEATURE_HOUSE_NUMBER;
      bool featureRef = way.hasTag(MapfileHelper.TAG_KEY_REF);
      if (featureRef) featureByte |= MapfileHelper.WAY_FEATURE_REF;
      bool featureLabelPosition = way.labelPosition != null;
      if (featureLabelPosition)
        featureByte |= MapfileHelper.WAY_FEATURE_LABEL_POSITION;
      // number of way data blocks or false if we have only 1
      bool featureWayDataBlocksByte = way.latLongs.length > 1;
      bool featureWayDoubleDeltaEncoding = true;

      writebuffer.appendInt1(featureByte);

      // check if the POI has a name
      if (featureName) {
        writebuffer.appendString(way.getTag(MapfileHelper.TAG_KEY_NAME)!);
      }

      // check if the POI has a house number
      if (featureHouseNumber) {
        writebuffer
            .appendString(way.getTag(MapfileHelper.TAG_KEY_HOUSE_NUMBER)!);
      }

      // check if the way has a reference
      if (featureRef) {
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
        _writeDoubleDeltaEncoding(writebuffer, way);
      else
        _writeSingleDeltaEncoding(writebuffer, way);
    }
  }

  /// Way data block
  void _writeSingleDeltaEncoding(Writebuffer writebuffer, Way way) {
    double tileLatitude = 0;
    double tileLongitude = 0;
    double previousSingleDeltaLatitude = 0;
    double previousSingleDeltaLongitude = 0;
    for (List<ILatLong> waySegment in way.latLongs) {
      int numberOfWayNodes = waySegment.length;
      writebuffer.appendUnsignedInt(numberOfWayNodes);
      writebuffer.appendUnsignedInt(waySegment.length);
      for (ILatLong coordinate in waySegment) {
        writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
            coordinate.latitude - tileLatitude));
        writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
            coordinate.longitude - tileLongitude));
      }
    }
  }

  /// Way data block
  void _writeDoubleDeltaEncoding(Writebuffer writebuffer, Way way) {
    double tileLatitude = 0;
    double tileLongitude = 0;
    double previousSingleDeltaLatitude = 0;
    double previousSingleDeltaLongitude = 0;
    for (List<ILatLong> waySegment in way.latLongs) {
      int numberOfWayNodes = waySegment.length;
      writebuffer.appendUnsignedInt(numberOfWayNodes);
      writebuffer.appendUnsignedInt(waySegment.length);
      for (ILatLong coordinate in waySegment) {
        writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
            coordinate.latitude - tileLatitude));
        writebuffer.appendSignedInt(LatLongUtils.degreesToMicrodegrees(
            coordinate.longitude - tileLongitude));
      }
    }
  }

  void _writeTileHeader(MapFile mapFile, Writebuffer writebuffer,
      SubFileParameter subfileParameter) {
    _writeHeaderSignature(mapFile, writebuffer);
    // the offset to the first way in the block
    int firstWayOffset = 0;

    int rows =
        subfileParameter.zoomLevelMax - subfileParameter.zoomLevelMin + 1;
    for (int row = 0; row < rows; ++row) {
      int queryZoomLevel = subfileParameter.zoomLevelMin + row;
      // number of pois on the query zoom level
      // todo find the pois/ways on the query zoom level
      int poisOnQueryZoomLevel = 0;
      int waysOnQueryZoomLevel = 0;
      _writeZoomtable(poisOnQueryZoomLevel, waysOnQueryZoomLevel, writebuffer);
    }
    writebuffer.appendUnsignedInt(firstWayOffset - writebuffer.length);
  }

  void writeBlock(
      MapFile mapFile,
      SubFileParameter subfileParameter,
      Writebuffer writebuffer,
      List<PointOfInterest> pois,
      List<Way> ways,
      double tileLatitude,
      double tileLongitude,
      List<Tag> tagsArray) {
    _writeTileHeader(mapFile, writebuffer, subfileParameter);
    _writePoidata(mapFile, pois, tileLatitude, tileLongitude, tagsArray);
    _writeWayProperties(mapFile, ways, tagsArray);
  }

  void _writeZoomtable(int poisOnQueryZoomLevel, int waysOnQueryZoomLevel,
      Writebuffer writebuffer) {
    writebuffer.appendUnsignedInt(poisOnQueryZoomLevel);
    writebuffer.appendUnsignedInt(waysOnQueryZoomLevel);
  }

  /// Note: to calculate how many tile index entries there will be, use the formulae at [http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames] to find out how many tiles will be covered by the bounding box at the base zoom level of the sub file
  void _writeTileIndexEntry(
      Writebuffer writebuffer, bool coveredByWater, int offset) {
    int indexEntry = 0;
    if (coveredByWater) indexEntry = indexEntry |= 0x8000000000;

    // 2.-40. bit (mask: 0x7f ff ff ff ff): 39 bit offset of the tile in the sub file as 5-bytes LONG (optional debug information and index size is also counted; byte order is BigEndian i.e. most significant byte first)
    // If the tile is empty offset(tile,,i,,) = offset(tile,,i+1,,)
    indexEntry = indexEntry |= offset;
    writebuffer.appendInt5(indexEntry);
  }
}

//////////////////////////////////////////////////////////////////////////////
