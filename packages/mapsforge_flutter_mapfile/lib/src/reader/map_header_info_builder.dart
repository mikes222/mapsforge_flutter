import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/src/model/map_header_optional_fields.dart';

import '../model/map_header_info.dart';

/// A builder that reads the header of a map file and constructs a [MapHeaderInfo] object.
///
/// This class follows the builder pattern: it reads data from the file into its
/// internal fields and then uses the `build()` method to create the final immutable
/// [MapHeaderInfo] object.
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

    /// Builds the immutable [MapHeaderInfo] object from the parsed data.
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
      zoomlevelRange: zoomlevelMin == null || zoomlevelMax == null ? const ZoomlevelRange.standard() : ZoomlevelRange(zoomlevelMin!, zoomlevelMax!),
      comment: optionalFields?.comment,
      createdBy: optionalFields?.createdBy,
      debugFile: optionalFields?.isDebugFile ?? false,
      tilePixelSize: tilePixelSize ?? 256,
      languagesPreference: optionalFields?.languagesPreference,
      startPosition: optionalFields?.startPosition,
      startZoomLevel: optionalFields?.startZoomLevel,
    );
  }

    /// Reads the entire map file header from the given [readbuffer].
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

    /// Reads and validates the file format version.
  void readFileVersion(Readbuffer readbuffer) {
    // get and check the file version (4 bytes)
    int fileVersion = readbuffer.readInt();
    if (fileVersion < SUPPORTED_FILE_VERSION_MIN || fileVersion > SUPPORTED_FILE_VERSION_MAX) {
      throw Exception("unsupported file version: $fileVersion");
    }
    this.fileVersion = fileVersion;
  }

    /// Reads and validates the file size against the value in the header.
  void readFileSize(Readbuffer readbuffer, int fileSize) {
    // get and check the file size (8 bytes)
    int headerFileSize = readbuffer.readLong();
    if (headerFileSize != fileSize) {
      throw Exception("invalid file size: $headerFileSize, expected $fileSize bytes instead");
    }
    this.fileSize = fileSize;
  }

    /// Reads and validates the map creation date.
  void readMapDate(Readbuffer readbuffer) {
    // get and check the the map date (8 bytes)
    int mapDate = readbuffer.readLong();
    // is the map date before 2010-01-10 ?
    if (mapDate < 1200000000000) {
      throw Exception("invalid map date: $mapDate");
    }
    this.mapDate = mapDate;
  }

    /// Reads the geographical bounding box of the map data.
  void readBoundingBox(Readbuffer readbuffer) {
    double minLatitude = LatLongUtils.microdegreesToDegrees(readbuffer.readInt());
    double minLongitude = LatLongUtils.microdegreesToDegrees(readbuffer.readInt());
    double maxLatitude = LatLongUtils.microdegreesToDegrees(readbuffer.readInt());
    double maxLongitude = LatLongUtils.microdegreesToDegrees(readbuffer.readInt());

    boundingBox = BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
  }

    /// Reads the tile size in pixels.
  void readTilePixelSize(Readbuffer readbuffer) {
    // get and check the tile pixel size (2 bytes)
    int tilePixelSize = readbuffer.readShort();
    // if (tilePixelSize != Tile.TILE_SIZE) {
    // return new FileOpenResult("unsupported tile pixel size: " + tilePixelSize);
    // }
    this.tilePixelSize = tilePixelSize;
  }

    /// Reads and validates the projection name (must be 'Mercator').
  void readProjectionName(Readbuffer readbuffer) {
    // get and check the projection name
    String projectionName = readbuffer.readUTF8EncodedString();
    if (MERCATOR != projectionName) {
      throw Exception("unsupported projection: $projectionName");
    }
    this.projectionName = projectionName;
  }

    /// Reads the list of predefined POI tags.
  void readPoiTags(Readbuffer readbuffer) {
    // get and check the number of POI tags (2 bytes)
    int numberOfPoiTags = readbuffer.readShort();
    if (numberOfPoiTags < 0) {
      throw Exception("invalid number of POI tags: $numberOfPoiTags");
    }

    List<Tag> poiTags = [];
    for (int currentTagId = 0; currentTagId < numberOfPoiTags; ++currentTagId) {
      // get and check the POI tag
      String tag = readbuffer.readUTF8EncodedString();
      poiTags.add(Tag.fromTag(tag));
    }
    this.poiTags = poiTags;
  }

    /// Reads the list of predefined way tags.
  void readWayTags(Readbuffer readbuffer) {
    // get and check the number of way tags (2 bytes)
    int numberOfWayTags = readbuffer.readShort();
    if (numberOfWayTags < 0) {
      throw Exception("invalid number of way tags: $numberOfWayTags");
    }

    List<Tag> wayTags = [];

    for (int currentTagId = 0; currentTagId < numberOfWayTags; ++currentTagId) {
      // get and check the way tag
      String tag = readbuffer.readUTF8EncodedString();
      wayTags.add(Tag.fromTag(tag));
    }
    this.wayTags = wayTags;
  }

    /// Reads the optional header fields based on the feature flags.
  void readOptionalFieldsStatic(Readbuffer readBuffer) {
    MapHeaderOptionalFields optionalFields = MapHeaderOptionalFields(readBuffer.readByte());
    this.optionalFields = optionalFields;

    optionalFields.readOptionalFields(readBuffer);
  }
}
