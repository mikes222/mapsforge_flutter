import 'package:mapsforge_flutter_core/model.dart';

/// Contains the high-level, immutable metadata of a map file.
///
/// This class holds the information stored in the map file header, such as the
/// bounding box, file version, creation date, and projection details.
class MapHeaderInfo {
    /// The geographical bounding box that this map file covers.
  final BoundingBox boundingBox;

    /// An optional comment string included in the map file.
  final String? comment;

    /// The name of the tool or person that created the map file.
  final String? createdBy;

    /// Whether the map file includes special debugging information.
  final bool debugFile;

    /// The total size of the map file in bytes.
  final int? fileSize;

    /// The version of the Mapsforge file format used.
  final int? fileVersion;

    /// A comma-separated list of preferred languages for labels, as defined in
  /// ISO 639-1 or ISO 639-2.
  final String? languagesPreference;

    /// The creation date of the map data, in milliseconds since the Unix epoch.
  final int? mapDate;

    /// The number of zoom-specific sub-files contained within this map file.
  final int? numberOfSubFiles;

    /// The list of predefined tags for Points of Interest (POIs).
  final List<Tag> poiTags;

    /// The name of the projection used in the map file (e.g., 'mercator').
  final String? projectionName;

    /// The recommended starting position (latitude/longitude) for the map view.
  final LatLong? startPosition;

    /// The recommended starting zoom level for the map view.
  final int? startZoomLevel;

    /// The size of the map tiles in pixels (e.g., 256 or 512).
  final int tilePixelSize;

    /// The list of predefined tags for ways (lines and polygons).
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
