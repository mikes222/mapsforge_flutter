import 'package:mapsforge_flutter_core/model.dart';

/// Abstract base class for map data storage and retrieval.
///
/// This class defines the interface for accessing map data from various sources
/// such as files, databases, or network services. It provides methods for reading
/// different types of map data (labels, POIs, general map data) for individual
/// tiles or tile ranges.
///
/// Key responsibilities:
/// - Tile-based data access with single tile and area queries
/// - Separation of different data types (labels, POIs, general map data)
/// - Boundary checking and tile support validation
/// - Resource management through dispose pattern
abstract class Datastore {
  const Datastore();

  /// Releases resources held by the datastore.
  /// Should be called when the datastore is no longer needed.
  void dispose();

  /// Reads label data for a single tile.
  ///
  /// Labels include POIs and named ways (roads, buildings, etc.) that have
  /// text labels for display. Implementations may return additional data.
  ///
  /// [tile] The tile for which to retrieve label data
  /// Returns label data bundle or null if no data available
  Future<DatastoreBundle?> readLabelsSingle(Tile tile);

  /// Reads label data for a rectangular area defined by two corner tiles.
  ///
  /// Default implementations typically combine results from individual tiles,
  /// which may be inefficient for large areas.
  ///
  /// Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
  ///
  /// [upperLeft] Upper-left corner tile of the requested area
  /// [lowerRight] Lower-right corner tile of the requested area
  /// Returns combined label data for the area
  Future<DatastoreBundle?> readLabels(Tile upperLeft, Tile lowerRight);

  /// Reads complete map data for a single tile.
  ///
  /// Returns all available map data including ways, POIs, and other features.
  ///
  /// [tile] The tile for which to retrieve map data
  /// Returns complete map data bundle or null if no data available
  Future<DatastoreBundle?> readMapDataSingle(Tile tile);

  /// Reads complete map data for a rectangular area.
  ///
  /// Combines map data from all tiles within the specified area.
  /// Default implementations may be inefficient for large areas.
  ///
  /// Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
  ///
  /// [upperLeft] Upper-left corner tile of the requested area
  /// [lowerRight] Lower-right corner tile of the requested area
  /// Returns combined map data for the entire area
  Future<DatastoreBundle> readMapData(Tile upperLeft, Tile lowerRight);

  /// Reads Point of Interest (POI) data for a single tile.
  ///
  /// POIs include restaurants, shops, landmarks, and other point features.
  ///
  /// [tile] The tile for which to retrieve POI data
  /// Returns POI data bundle or null if no data available
  Future<DatastoreBundle?> readPoiDataSingle(Tile tile);

  /// Reads POI data for a rectangular area defined by corner tiles.
  ///
  /// Combines POI data from all tiles within the specified area.
  ///
  /// Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
  ///
  /// [upperLeft] Upper-left corner tile of the requested area
  /// [lowerRight] Lower-right corner tile of the requested area
  /// Returns combined POI data for the area
  Future<DatastoreBundle?> readPoiData(Tile upperLeft, Tile lowerRight);

  /// Checks if the datastore contains data for the specified tile.
  ///
  /// [tile] The tile to check for data availability
  /// Returns true if tile data is available, false otherwise
  Future<bool> supportsTile(Tile tile);

  /// Returns the geographic area covered by this datastore.
  ///
  /// Returns the bounding box defining the extent of available map data
  Future<BoundingBox> getBoundingBox();
}
