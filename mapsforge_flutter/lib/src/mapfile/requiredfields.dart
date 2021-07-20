import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';

import 'mapfileinfobuilder.dart';
import '../model/boundingbox.dart';
import '../model/tag.dart';
import '../utils/latlongutils.dart';
import 'readbuffer.dart';

class RequiredFields {
  /**
   * Magic byte at the beginning of a valid binary map file.
   */
  static final String BINARY_OSM_MAGIC_BYTE = "mapsforge binary OSM";

  /**
   * Maximum size of the file header in bytes.
   */
  static final int HEADER_SIZE_MAX = 1000000;

  /**
   * Minimum size of the file header in bytes.
   */
  static final int HEADER_SIZE_MIN = 70;

  /**
   * The name of the Mercator projection as stored in the file header.
   */
  static final String MERCATOR = "Mercator";

  /**
   * Lowest version of the map file format supported by this implementation.
   */
  static final int SUPPORTED_FILE_VERSION_MIN = 3;

  /**
   * Highest version of the map file format supported by this implementation.
   */
  static final int SUPPORTED_FILE_VERSION_MAX = 5;

  static void readBoundingBox(
      Readbuffer readBuffer, MapFileInfoBuilder mapFileInfoBuilder) {
    double minLatitude =
        LatLongUtils.microdegreesToDegrees(readBuffer.readInt());
    double minLongitude =
        LatLongUtils.microdegreesToDegrees(readBuffer.readInt());
    double maxLatitude =
        LatLongUtils.microdegreesToDegrees(readBuffer.readInt());
    double maxLongitude =
        LatLongUtils.microdegreesToDegrees(readBuffer.readInt());

    mapFileInfoBuilder.boundingBox =
        new BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
  }

  static void readFileSize(Readbuffer readBuffer, int fileSize,
      MapFileInfoBuilder mapFileInfoBuilder) {
    // get and check the file size (8 bytes)
    int headerFileSize = readBuffer.readLong();
    if (headerFileSize != fileSize) {
      throw new Exception(
          "invalid file size: $headerFileSize, expected $fileSize bytes instead");
    }
    mapFileInfoBuilder.fileSize = fileSize;
  }

  static void readFileVersion(
      Readbuffer readBuffer, MapFileInfoBuilder mapFileInfoBuilder) {
    // get and check the file version (4 bytes)
    int fileVersion = readBuffer.readInt();
    if (fileVersion < SUPPORTED_FILE_VERSION_MIN ||
        fileVersion > SUPPORTED_FILE_VERSION_MAX) {
      throw new Exception("unsupported file version: $fileVersion");
    }
    mapFileInfoBuilder.fileVersion = fileVersion;
  }

  static Future<Readbuffer> readMagicByte(
      ReadbufferSource readBufferMaster) async {
    // read the the magic byte and the file header size into the buffer
    int magicByteLength = BINARY_OSM_MAGIC_BYTE.length;

    Readbuffer readBuffer = (await (readBufferMaster.readFromFile(
        length: magicByteLength + 4, offset: 0)));

    // get and check the magic byte
    String magicByte = readBuffer.readUTF8EncodedString2(magicByteLength);

    if (BINARY_OSM_MAGIC_BYTE != (magicByte)) {
      throw new Exception("invalid magic byte: $magicByte");
    }
    return readBuffer;
  }

  static void readMapDate(
      Readbuffer readBuffer, MapFileInfoBuilder mapFileInfoBuilder) {
// get and check the the map date (8 bytes)
    int mapDate = readBuffer.readLong();
// is the map date before 2010-01-10 ?
    if (mapDate < 1200000000000) {
      throw new Exception("invalid map date: $mapDate");
    }
    mapFileInfoBuilder.mapDate = mapDate;
  }

  static void readPoiTags(
      Readbuffer readBuffer, MapFileInfoBuilder mapFileInfoBuilder) {
// get and check the number of POI tags (2 bytes)
    int numberOfPoiTags = readBuffer.readShort();
    if (numberOfPoiTags < 0) {
      throw new Exception("invalid number of POI tags: $numberOfPoiTags");
    }

    List<Tag> poiTags = [];
    for (int currentTagId = 0; currentTagId < numberOfPoiTags; ++currentTagId) {
// get and check the POI tag
      String tag = readBuffer.readUTF8EncodedString();
      if (tag == null) {
        throw new Exception("POI tag must not be null: $currentTagId");
      }
      poiTags.add(Tag.fromTag(tag));
    }
    mapFileInfoBuilder.poiTags = poiTags;
  }

  static void readProjectionName(
      Readbuffer readBuffer, MapFileInfoBuilder mapFileInfoBuilder) {
// get and check the projection name
    String projectionName = readBuffer.readUTF8EncodedString();
    if (MERCATOR != projectionName) {
      throw new Exception("unsupported projection: $projectionName");
    }
    mapFileInfoBuilder.projectionName = projectionName;
  }

  static void readTilePixelSize(
      Readbuffer readBuffer, MapFileInfoBuilder mapFileInfoBuilder) {
// get and check the tile pixel size (2 bytes)
    int tilePixelSize = readBuffer.readShort();
// if (tilePixelSize != Tile.TILE_SIZE) {
// return new FileOpenResult("unsupported tile pixel size: " + tilePixelSize);
// }
    mapFileInfoBuilder.tilePixelSize = tilePixelSize;
  }

  static void readWayTags(
      Readbuffer readBuffer, MapFileInfoBuilder mapFileInfoBuilder) {
// get and check the number of way tags (2 bytes)
    int numberOfWayTags = readBuffer.readShort();
    if (numberOfWayTags < 0) {
      throw new Exception("invalid number of way tags: $numberOfWayTags");
    }

    List<Tag> wayTags = [];

    for (int currentTagId = 0; currentTagId < numberOfWayTags; ++currentTagId) {
// get and check the way tag
      String tag = readBuffer.readUTF8EncodedString();
      if (tag == null) {
        throw new Exception("way tag must not be null: $currentTagId");
      }
      wayTags.add(new Tag.fromTag(tag));
    }
    mapFileInfoBuilder.wayTags = wayTags;
  }

  RequiredFields() {
    throw new Exception();
  }
}
