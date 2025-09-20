import 'package:mapsforge_flutter_core/model.dart';

/// A container for the data returned from a `Datastore`.
class DatastoreBundle {
  /// True if the read area is completely covered by water, false otherwise.
  bool isWater = false;

  /// The read POIs.
  final List<PointOfInterest> pointOfInterests;

  /// The read ways.
  final List<Way> ways;

  /// Creates a new `DatastoreBundle`.
  DatastoreBundle({required this.pointOfInterests, required this.ways});

  /// Adds the content of another `DatastoreBundle` to this one.
  void add(DatastoreBundle poiWayBundle) {
    pointOfInterests.addAll(poiWayBundle.pointOfInterests);
    ways.addAll(poiWayBundle.ways);
  }

  /// Adds the content of another `DatastoreBundle` to this one, with an option
  /// to deduplicate the elements.
  ///
  /// If [deduplicate] is true, this method will check for duplicates before
  /// adding elements, which is more expensive.
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
