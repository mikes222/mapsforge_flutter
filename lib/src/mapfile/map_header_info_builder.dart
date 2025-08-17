import '../../core.dart';
import '../model/zoomlevel_range.dart';
import 'map_header_info.dart';
import 'map_header_optional_fields.dart';
import 'readbuffer.dart';

class MapHeaderInfoBuilder {
  /// Lowest version of the map file format supported by this implementation.
  final int SUPPORTED_FILE_VERSION_MIN = 3;

  /// Highest version of the map file format supported by this implementation.
  final int SUPPORTED_FILE_VERSION_MAX = 5;

  /// The name of the Mercator projection as stored in the file header.
  static final String MERCATOR = "Mercator";

  BoundingBox? boundingBox;
  int? fileSize;
  int? fileVersion;
  int? mapDate;
  int? numberOfSubFiles;
  MapHeaderOptionalFields? optionalFields;
  List<Tag>? poiTags;
  String? projectionName;
  int? tilePixelSize;
  List<Tag>? wayTags;
  int? zoomlevelMin;
  int? zoomlevelMax;

  MapHeaderInfo build() {
    return MapHeaderInfo(
        boundingBox: boundingBox!,
        fileSize: fileSize,
        fileVersion: fileVersion,
        mapDate: mapDate,
        numberOfSubFiles: numberOfSubFiles,
        poiTags: poiTags!,
        projectionName: projectionName,
        wayTags: wayTags!,
        zoomlevelRange: zoomlevelMin == null || zoomlevelMax == null
            ? const ZoomlevelRange.standard()
            : ZoomlevelRange(zoomlevelMin!, zoomlevelMax!),
        comment: optionalFields?.comment,
        createdBy: optionalFields?.createdBy,
        debugFile: optionalFields?.isDebugFile ?? false,
        tilePixelSize: tilePixelSize ?? 256,
        languagesPreference: optionalFields?.languagesPreference,
        startPosition: optionalFields?.startPosition,
        startZoomLevel: optionalFields?.startZoomLevel);
  }

  void read(Readbuffer readbuffer, int fileSize) {
    readFileVersion(readbuffer);

    readFileSize(readbuffer, fileSize);

    readMapDate(readbuffer);

    readBoundingBox(readbuffer);

    readTilePixelSize(readbuffer);

    readProjectionName(readbuffer);

    readOptionalFieldsStatic(readbuffer);

    readPoiTags(readbuffer);

    readWayTags(readbuffer);
  }

  void readFileVersion(Readbuffer readbuffer) {
    // get and check the file version (4 bytes)
    int fileVersion = readbuffer.readInt();
    if (fileVersion < SUPPORTED_FILE_VERSION_MIN ||
        fileVersion > SUPPORTED_FILE_VERSION_MAX) {
      throw new Exception("unsupported file version: $fileVersion");
    }
    this.fileVersion = fileVersion;
  }

  void readFileSize(Readbuffer readbuffer, int fileSize) {
    // get and check the file size (8 bytes)
    int headerFileSize = readbuffer.readLong();
    if (headerFileSize != fileSize) {
      throw new Exception(
          "invalid file size: $headerFileSize, expected $fileSize bytes instead");
    }
    this.fileSize = fileSize;
  }

  void readMapDate(Readbuffer readbuffer) {
// get and check the the map date (8 bytes)
    int mapDate = readbuffer.readLong();
// is the map date before 2010-01-10 ?
    if (mapDate < 1200000000000) {
      throw new Exception("invalid map date: $mapDate");
    }
    this.mapDate = mapDate;
  }

  void readBoundingBox(Readbuffer readbuffer) {
    double minLatitude =
        LatLongUtils.microdegreesToDegrees(readbuffer.readInt());
    double minLongitude =
        LatLongUtils.microdegreesToDegrees(readbuffer.readInt());
    double maxLatitude =
        LatLongUtils.microdegreesToDegrees(readbuffer.readInt());
    double maxLongitude =
        LatLongUtils.microdegreesToDegrees(readbuffer.readInt());

    this.boundingBox =
        BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
  }

  void readTilePixelSize(Readbuffer readbuffer) {
// get and check the tile pixel size (2 bytes)
    int tilePixelSize = readbuffer.readShort();
// if (tilePixelSize != Tile.TILE_SIZE) {
// return new FileOpenResult("unsupported tile pixel size: " + tilePixelSize);
// }
    this.tilePixelSize = tilePixelSize;
  }

  void readProjectionName(Readbuffer readbuffer) {
// get and check the projection name
    String projectionName = readbuffer.readUTF8EncodedString();
    if (MERCATOR != projectionName) {
      throw new Exception("unsupported projection: $projectionName");
    }
    this.projectionName = projectionName;
  }

  void readPoiTags(Readbuffer readbuffer) {
// get and check the number of POI tags (2 bytes)
    int numberOfPoiTags = readbuffer.readShort();
    if (numberOfPoiTags < 0) {
      throw new Exception("invalid number of POI tags: $numberOfPoiTags");
    }

    List<Tag> poiTags = [];
    for (int currentTagId = 0; currentTagId < numberOfPoiTags; ++currentTagId) {
// get and check the POI tag
      String tag = readbuffer.readUTF8EncodedString();
      poiTags.add(Tag.fromTag(tag));
    }
    this.poiTags = poiTags;
  }

  void readWayTags(Readbuffer readbuffer) {
// get and check the number of way tags (2 bytes)
    int numberOfWayTags = readbuffer.readShort();
    if (numberOfWayTags < 0) {
      throw new Exception("invalid number of way tags: $numberOfWayTags");
    }

    List<Tag> wayTags = [];

    for (int currentTagId = 0; currentTagId < numberOfWayTags; ++currentTagId) {
// get and check the way tag
      String tag = readbuffer.readUTF8EncodedString();
      wayTags.add(new Tag.fromTag(tag));
    }
    this.wayTags = wayTags;
  }

  void readOptionalFieldsStatic(Readbuffer readBuffer) {
    MapHeaderOptionalFields optionalFields =
        MapHeaderOptionalFields(readBuffer.readByte());
    this.optionalFields = optionalFields;

    optionalFields.readOptionalFields(readBuffer);
  }
}
