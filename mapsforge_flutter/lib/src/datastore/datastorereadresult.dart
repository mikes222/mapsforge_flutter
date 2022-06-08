import 'pointofinterest.dart';
import 'poiwaybundle.dart';
import 'way.dart';

/// An immutable container for the data returned from a MapDataStore.
class DatastoreReadResult {
  /// True if the read area is completely covered by water, false otherwise.
  bool isWater = false;

  /// The read POIs.
  final List<PointOfInterest> pointOfInterests;

  /// The read ways.
  final List<Way> ways;

  DatastoreReadResult({required this.pointOfInterests, required this.ways});

  void add(PoiWayBundle poiWayBundle) {
    this.pointOfInterests.addAll(poiWayBundle.pois);
    this.ways.addAll(poiWayBundle.ways);
  }

  /// Adds other MapReadResult by combining pois and ways. Optionally, deduplication can
  /// be requested (much more expensive).
  ///
  /// @param other       the MapReadResult to add to this.
  /// @param deduplicate true if check for duplicates is required.
  void addDeduplicate(DatastoreReadResult other, bool deduplicate) {
    if (deduplicate) {
      for (PointOfInterest poi in other.pointOfInterests) {
        if (!this.pointOfInterests.contains(poi)) {
          this.pointOfInterests.add(poi);
        }
      }
      for (Way way in other.ways) {
        if (!this.ways.contains(way)) {
          this.ways.add(way);
        }
      }
    } else {
      this.pointOfInterests.addAll(other.pointOfInterests);
      this.ways.addAll(other.ways);
    }
  }

  @override
  String toString() {
    return 'MapReadResult{isWater: $isWater, pointOfInterests: $pointOfInterests, ways: $ways}';
  }
}
