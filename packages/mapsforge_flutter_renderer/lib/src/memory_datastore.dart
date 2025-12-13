import 'package:mapsforge_flutter_core/model.dart';

/// In-memory datastore implementation for testing and dynamic tile generation.
///
/// This datastore holds all map data in memory using simple lists, making it
/// suitable for testing, prototyping, or scenarios where map data is generated
/// dynamically at runtime.
///
/// Key characteristics:
/// - Fast access to data (no I/O operations)
/// - Limited by available memory
/// - Supports adding POIs and ways programmatically
/// - Implements basic spatial filtering by tile boundaries
class MemoryDatastore extends Datastore {
  /// Collection of Points of Interest stored in memory.
  final List<PointOfInterest> pointOfInterests = [];

  /// Collection of ways (roads, paths, boundaries) stored in memory.
  final List<Way> ways = [];

  /// Clears all stored data from memory.
  @override
  void dispose() {
    pointOfInterests.clear();
    ways.clear();
  }

  @override
  Future<DatastoreBundle> readLabels(Tile upperLeft, Tile lowerRight) {
    // TODO: implement readLabels
    throw UnimplementedError();
  }

  @override
  Future<DatastoreBundle> readLabelsSingle(Tile tile) {
    // TODO: implement readLabelsSingle
    throw UnimplementedError();
  }

  @override
  Future<DatastoreBundle> readMapData(Tile upperLeft, Tile lowerRight) {
    // TODO: implement readMapData
    throw UnimplementedError();
  }

  /// Reads map data for a single tile by filtering stored data.
  ///
  /// Performs spatial filtering to return only POIs and ways that intersect
  /// with the tile's geographic boundaries.
  @override
  Future<DatastoreBundle> readMapDataSingle(Tile tile) {
    List<PointOfInterest> poiResults = pointOfInterests.where((poi) => tile.getBoundingBox().containsLatLong(poi.position)).toList();
    List<Way> wayResults = [];
    for (Way way in ways) {
      if (tile.getBoundingBox().intersectsArea(way.latLongs)) {
        wayResults.add(way);
      }
    }
    return Future.value(DatastoreBundle(pointOfInterests: poiResults, ways: wayResults));
  }

  @override
  Future<DatastoreBundle> readPoiData(Tile upperLeft, Tile lowerRight) {
    // TODO: implement readPoiData
    throw UnimplementedError();
  }

  @override
  Future<DatastoreBundle> readPoiDataSingle(Tile tile) {
    // TODO: implement readPoiDataSingle
    throw UnimplementedError();
  }

  /// Always returns true as memory datastore can generate tiles on demand.
  ///
  /// For label display, neighboring tiles may also be considered supported.
  @override
  Future<bool> supportsTile(Tile tile) {
    // you may want to show neighbouring tiles too in order to display labels.
    return Future.value(true);
    // Projection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
    // for (PointOfInterest poi in pointOfInterests) {
    //   if (projection.boundingBoxOfTile(tile).containsLatLong(poi.position)) return true;
    // }
    // for (Way way in ways) {
    //   for (List<ILatLong> list in way.latLongs) {
    //     for (ILatLong latLong in list) {
    //       if (projection.boundingBoxOfTile(tile).containsLatLong(latLong)) return true;
    //     }
    //   }
    // }
    // return false;
  }

  /// Adds a Point of Interest to the in-memory collection.
  ///
  /// [poi] The POI to add to the datastore
  void addPoi(PointOfInterest poi) {
    pointOfInterests.add(poi);
  }

  /// Adds a way to the in-memory collection.
  ///
  /// [way] The way (road, path, boundary) to add to the datastore
  void addWay(Way way) {
    ways.add(way);
  }

  @override
  String toString() {
    return 'MemoryDatastore{pointOfInterests: $pointOfInterests, ways: $ways}';
  }

  /// Returns the maximum possible bounding box as this datastore has no fixed bounds.
  @override
  Future<BoundingBox> getBoundingBox() {
    return Future.value(BoundingBox.max());
  }
}
