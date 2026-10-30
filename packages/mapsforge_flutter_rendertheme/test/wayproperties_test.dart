import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:test/test.dart';

void main() {
  final projection = PixelProjection(7);

  Way wayFromPixels(List<Mappoint> points) => Way(
    0,
    const [Tag('highway', 'primary')],
    [
      points
          .map((point) => projection.pixelToLatLong(point.x, point.y))
          .toList(),
    ],
    null,
  );

  group('WayProperties small geometry', () {
    for (final width in [4.99, 5.0, 5.01]) {
      test('default filter for a $width pixel open way', () {
        final way = wayFromPixels([
          const Mappoint(1024, 1024),
          Mappoint(1024 + width, 1024),
        ]);
        final properties = WayProperties(way, projection);

        expect(
          properties.getBoundaryAbsolute().getWidth(),
          closeTo(width, 1e-8),
        );
        expect(properties.getCoordinatesAbsolute().isEmpty, width <= 5);
      });

      test('keeps a $width pixel open way when requested', () {
        final way = wayFromPixels([
          const Mappoint(1024, 1024),
          Mappoint(1024 + width, 1024),
        ]);
        final properties = WayProperties(
          way,
          projection,
          keepSmallOpenWays: true,
        );

        expect(properties.getCoordinatesAbsolute().single, hasLength(2));
      });
    }

    test('a tall narrow way is not filtered', () {
      final way = wayFromPixels([
        const Mappoint(1024, 1024),
        const Mappoint(1025, 1030),
      ]);
      expect(
        WayProperties(way, projection).getCoordinatesAbsolute(),
        hasLength(1),
      );
    });

    test('keeping open ways does not keep tiny closed areas', () {
      final way = wayFromPixels([
        const Mappoint(1024, 1024),
        const Mappoint(1028, 1024),
        const Mappoint(1028, 1028),
        const Mappoint(1024, 1024),
      ]);
      for (final keep in [false, true]) {
        final properties = WayProperties(
          way,
          projection,
          keepSmallOpenWays: keep,
        );
        expect(properties.isClosedWay, isTrue);
        expect(properties.getCoordinatesAbsolute(), isEmpty);
      }
    });
  });

  group('WayProperties simplification', () {
    final points = List.generate(
      9,
      (i) => Mappoint(1024 + i * 4.0, 1024 + (i.isOdd ? 3.0 : 0)),
    );

    test('default tolerance is 5 pixels and preserves endpoints', () {
      final way = wayFromPixels(points);
      final properties = WayProperties(way, projection);
      final coordinates = properties.getCoordinatesAbsolute().single;

      expect(properties.simplificationTolerance, 5);
      expect(coordinates, hasLength(2));
      expect(
        coordinates.first,
        projection.latLonToPixel(way.latLongs.first.first),
      );
      expect(
        coordinates.last,
        projection.latLonToPixel(way.latLongs.first.last),
      );
    });

    test('1 pixel tolerance preserves visible bends', () {
      final way = wayFromPixels(points);
      final coordinates = WayProperties(
        way,
        projection,
        simplificationTolerance: 1,
      ).getCoordinatesAbsolute().single;

      expect(coordinates.length, greaterThan(2));
      expect(
        coordinates.first,
        projection.latLonToPixel(way.latLongs.first.first),
      );
      expect(
        coordinates.last,
        projection.latLonToPixel(way.latLongs.first.last),
      );
    });

    test('zero tolerance leaves every coordinate unchanged', () {
      final way = wayFromPixels(points);
      final coordinates = WayProperties(
        way,
        projection,
        simplificationTolerance: 0,
      ).getCoordinatesAbsolute().single;
      expect(
        coordinates,
        way.latLongs.first.map(projection.latLonToPixel).toList(),
      );
    });
  });
}
