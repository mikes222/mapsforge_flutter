import '../model/boundingbox.dart';
import '../model/latlong.dart';
import '../model/tag.dart';
import '../model/zoomlevel_range.dart';

/// Contains the immutable metadata of a map file.
///
/// @see org.mapsforge.map.reader.MapFile#getMapFileInfo()
class MapHeaderInfo {
  /**
   * The bounding box of the map file.
   */
  final BoundingBox boundingBox;

  /**
   * The comment field of the map file (may be null).
   */
  final String? comment;

  /**
   * The created by field of the map file (may be null).
   */
  final String? createdBy;

  /**
   * True if the map file includes debug information, false otherwise.
   */
  final bool debugFile;

  /**
   * The size of the map file, measured in bytes.
   */
  final int? fileSize;

  /**
   * The file version number of the map file.
   */
  final int? fileVersion;

  /**
   * The preferred language(s) separated with ',' for names as defined in ISO 639-1 or ISO 639-2 (may be null).
   */
  final String? languagesPreference;

  /**
   * The date of the map data in milliseconds since January 1, 1970.
   */
  final int? mapDate;

  /**
   * The number of sub-files in the map file.
   */
  final int? numberOfSubFiles;

  /**
   * The POI tags.
   */
  final List<Tag> poiTags;

  /**
   * The name of the projection used in the map file.
   */
  final String? projectionName;

  /**
   * The map start position from the file header (may be null).
   */
  final LatLong? startPosition;

  /**
   * The map start zoom level from the file header (may be null).
   */
  final int? startZoomLevel;

  /**
   * The size of the tiles in pixels.
   */
  final int tilePixelSize;

  /**
   * The way tags.
   */
  final List<Tag> wayTags;

  final ZoomlevelRange zoomlevelRange;

  const MapHeaderInfo({
    required this.boundingBox,
    this.comment,
    this.createdBy,
    this.debugFile = false,
    this.fileSize,
    this.fileVersion,
    this.languagesPreference,
    this.mapDate,
    this.numberOfSubFiles,
    this.poiTags = const [],
    this.projectionName,
    this.startPosition,
    this.startZoomLevel,
    this.tilePixelSize = 256,
    this.wayTags = const [],
    required this.zoomlevelRange,
  });

  @override
  String toString() {
    return 'MapHeaderInfo{boundingBox: $boundingBox, comment: $comment, createdBy: $createdBy, debugFile: $debugFile, fileSize: $fileSize, fileVersion: $fileVersion, languagesPreference: $languagesPreference, mapDate: $mapDate, numberOfSubFiles: $numberOfSubFiles, poiTags-length: ${poiTags.length}, projectionName: $projectionName, startPosition: $startPosition, startZoomLevel: $startZoomLevel, wayTags-length: ${wayTags.length}, zoomlevelRange: $zoomlevelRange}';
  }
}
