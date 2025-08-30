import 'package:mapsforge_flutter_core/model.dart';

/// An immutable container for the data returned from a MapDataStore.
class DatastoreBundle {
  /// True if the read area is completely covered by water, false otherwise.
  bool isWater = false;

  /// The read POIs.
  final List<PointOfInterest> pointOfInterests;

  /// The read ways.
  final List<Way> ways;

  DatastoreBundle({required this.pointOfInterests, required this.ways});

  void add(DatastoreBundle poiWayBundle) {
    pointOfInterests.addAll(poiWayBundle.pointOfInterests);
    ways.addAll(poiWayBundle.ways);
  }

  /// Adds other MapReadResult by combining pois and ways. Optionally, deduplication can
  /// be requested (much more expensive).
  ///
  /// @param other       the MapReadResult to add to this.
  /// @param deduplicate true if check for duplicates is required.
  void addDeduplicate(DatastoreBundle other, bool deduplicate) {
    if (deduplicate) {
      for (PointOfInterest poi in other.pointOfInterests) {
        if (!pointOfInterests.contains(poi)) {
          pointOfInterests.add(poi);
        }
      }
      for (Way way in other.ways) {
        if (!ways.contains(way)) {
          ways.add(way);
        }
      }
    } else {
      pointOfInterests.addAll(other.pointOfInterests);
      ways.addAll(other.ways);
    }
  }

  @override
  String toString() {
    return 'MapReadResult{isWater: $isWater, pointOfInterests: $pointOfInterests, ways: $ways}';
  }
}
