import 'package:mapsforge_flutter_core/model.dart';
import 'package:test/test.dart';

void main() {
  group('DatastoreBundle.addDeduplicate', () {
    PointOfInterest poi(String value, double lat, double lon) =>
        PointOfInterest(1, TagCollection(tags: [Tag('amenity', value)]), LatLong(lat, lon));

    Way way(String value, double lat, double lon) => Way(1, [
          Tag('highway', value)
        ], [
          [LatLong(lat, lon), LatLong(lat + 0.001, lon + 0.001)],
        ], null);

    test('deduplicates content-equal POIs and Ways across distinct instances', () {
      final DatastoreBundle target = DatastoreBundle(pointOfInterests: [], ways: []);
      final DatastoreBundle source = DatastoreBundle(
        pointOfInterests: [poi('cafe', 52.0, 13.0), poi('cafe', 52.0, 13.0), poi('bar', 52.5, 13.5)],
        ways: [way('residential', 52.0, 13.0), way('residential', 52.0, 13.0), way('primary', 53.0, 14.0)],
      );

      target.addDeduplicate(source, true);

      // Two distinct POIs/Ways: 'cafe'+'bar' and 'residential'+'primary'.
      expect(target.pointOfInterests.length, 2);
      expect(target.ways.length, 2);
    });

    test('deduplicates against pre-existing content', () {
      final DatastoreBundle target = DatastoreBundle(
        pointOfInterests: [poi('cafe', 52.0, 13.0)],
        ways: [way('residential', 52.0, 13.0)],
      );
      final DatastoreBundle source = DatastoreBundle(
        pointOfInterests: [poi('cafe', 52.0, 13.0), poi('bar', 52.5, 13.5)],
        ways: [way('residential', 52.0, 13.0), way('primary', 53.0, 14.0)],
      );

      target.addDeduplicate(source, true);

      expect(target.pointOfInterests.length, 2);
      expect(target.ways.length, 2);
    });

    test('keeps insertion order of first occurrence', () {
      final DatastoreBundle target = DatastoreBundle(pointOfInterests: [], ways: []);
      final DatastoreBundle source = DatastoreBundle(
        pointOfInterests: [poi('bar', 52.5, 13.5), poi('cafe', 52.0, 13.0), poi('bar', 52.5, 13.5)],
        ways: [],
      );

      target.addDeduplicate(source, true);

      expect(target.pointOfInterests.length, 2);
      expect(target.pointOfInterests[0].tags.getTag('amenity'), 'bar');
      expect(target.pointOfInterests[1].tags.getTag('amenity'), 'cafe');
    });

    test('deduplicate=false adds everything including duplicates', () {
      final DatastoreBundle target = DatastoreBundle(pointOfInterests: [poi('cafe', 52.0, 13.0)], ways: []);
      final DatastoreBundle source = DatastoreBundle(
        pointOfInterests: [poi('cafe', 52.0, 13.0)],
        ways: [way('residential', 52.0, 13.0)],
      );

      target.addDeduplicate(source, false);

      expect(target.pointOfInterests.length, 2);
      expect(target.ways.length, 1);
    });
  });
}
