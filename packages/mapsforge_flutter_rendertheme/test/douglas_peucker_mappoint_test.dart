import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/src/util/douglas_peucker_mappoint.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('DouglasPeuckerMappoint Optimizations', () {
    late DouglasPeuckerMappoint douglasPeucker;

    setUp(() {
      douglasPeucker = DouglasPeuckerMappoint();
    });

    group('Basic Functionality', () {
      test('should return original points when count <= 2', () {
        final points = [Mappoint(0.0, 0.0), Mappoint(1.0, 1.0)];

        final result = douglasPeucker.simplify(points, 0.1);
        expect(result.length, equals(2));
        expect(result, equals(points));
      });

      test('should handle single point', () {
        final points = [Mappoint(0.0, 0.0)];
        final result = douglasPeucker.simplify(points, 0.1);
        expect(result.length, equals(1));
        expect(result.first, equals(points.first));
      });

      test('should handle empty list', () {
        final points = <Mappoint>[];
        final result = douglasPeucker.simplify(points, 0.1);
        expect(result.isEmpty, isTrue);
      });
    });

    group('Line Simplification', () {
      test('should preserve straight line with collinear points', () {
        final points = [Mappoint(0.0, 0.0), Mappoint(1.0, 1.0), Mappoint(2.0, 2.0), Mappoint(3.0, 3.0)];

        final result = douglasPeucker.simplify(points, 0.1);
        expect(result.length, equals(2));
        expect(result.first, equals(points.first));
        expect(result.last, equals(points.last));
      });

      test('should preserve significant deviation points', () {
        final points = [
          Mappoint(0.0, 0.0),
          Mappoint(1.0, 0.0),
          Mappoint(1.0, 1.0), // Significant deviation
          Mappoint(2.0, 1.0),
          Mappoint(2.0, 0.0),
        ];

        final result = douglasPeucker.simplify(points, 0.1);
        expect(result.length, greaterThan(2));
        expect(result.first, equals(points.first));
        expect(result.last, equals(points.last));
      });

      test('should remove points within tolerance', () {
        final points = [
          Mappoint(0.0, 0.0),
          Mappoint(0.5, 0.01), // Small deviation
          Mappoint(1.0, 0.0),
        ];

        final result = douglasPeucker.simplify(points, 0.1);
        expect(result.length, equals(2));
        expect(result.first, equals(points.first));
        expect(result.last, equals(points.last));
      });
    });

    group('Performance Optimizations', () {
      test('should handle large datasets efficiently', () {
        // Create a complex path with 1000 points
        final points = <Mappoint>[];
        for (int i = 0; i < 1000; i++) {
          final x = i.toDouble();
          final y = (i % 10).toDouble() + (i % 3) * 0.1; // Some variation
          points.add(Mappoint(x, y));
        }

        final stopwatch = Stopwatch()..start();
        final result = douglasPeucker.simplify(points, 0.5);
        stopwatch.stop();

        expect(result.length, lessThan(points.length));
        expect(result.length, greaterThan(10)); // Should keep some points
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
      });

      test('should perform distance calculations efficiently', () {
        final points = <Mappoint>[];
        // Create zigzag pattern
        for (int i = 0; i < 100; i++) {
          points.add(Mappoint(i.toDouble(), (i % 2).toDouble()));
        }

        final stopwatch = Stopwatch()..start();
        final result = douglasPeucker.simplify(points, 0.1);
        stopwatch.stop();

        expect(result.length, greaterThan(2));
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('should handle repeated calculations efficiently', () {
        final points = [Mappoint(0.0, 0.0), Mappoint(1.0, 0.1), Mappoint(2.0, 0.0), Mappoint(3.0, 0.1), Mappoint(4.0, 0.0)];

        final stopwatch = Stopwatch()..start();

        // Perform multiple simplifications
        for (int i = 0; i < 1000; i++) {
          douglasPeucker.simplify(points, 0.05);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Edge Cases', () {
      test('should handle identical consecutive points', () {
        final points = [
          Mappoint(0.0, 0.0),
          Mappoint(0.0, 0.0), // Duplicate
          Mappoint(1.0, 1.0),
          Mappoint(1.0, 1.0), // Duplicate
          Mappoint(2.0, 0.0),
        ];

        final result = douglasPeucker.simplify(points, 0.1);
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.first, equals(points.first));
        expect(result.last, equals(points.last));
      });

      test('should handle zero tolerance', () {
        final points = [Mappoint(0.0, 0.0), Mappoint(1.0, 0.001), Mappoint(2.0, 0.0)];

        final result = douglasPeucker.simplify(points, 0.0);
        expect(result.length, equals(3)); // Should keep all points
      });

      test('should handle very high tolerance', () {
        final points = [Mappoint(0.0, 0.0), Mappoint(1.0, 1.0), Mappoint(2.0, 0.0), Mappoint(3.0, 1.0), Mappoint(4.0, 0.0)];

        final result = douglasPeucker.simplify(points, 10.0);
        expect(result.length, equals(2)); // Should simplify to endpoints
        expect(result.first, equals(points.first));
        expect(result.last, equals(points.last));
      });

      test('should handle very small coordinates', () {
        final points = [Mappoint(0.0001, 0.0001), Mappoint(0.0002, 0.0002), Mappoint(0.0003, 0.0001)];

        final result = douglasPeucker.simplify(points, 0.00001);
        expect(result.length, greaterThanOrEqualTo(2));
      });

      test('should handle very large coordinates', () {
        final points = [Mappoint(1000000.0, 1000000.0), Mappoint(1000001.0, 1000001.0), Mappoint(1000002.0, 1000000.0)];

        final result = douglasPeucker.simplify(points, 0.5);
        expect(result.length, greaterThanOrEqualTo(2));
      });
    });

    group('Algorithm Correctness', () {
      test('should maintain path topology', () {
        final points = [Mappoint(0.0, 0.0), Mappoint(1.0, 1.0), Mappoint(2.0, 0.5), Mappoint(3.0, 1.5), Mappoint(4.0, 0.0)];

        final result = douglasPeucker.simplify(points, 0.3);

        // Result should maintain start and end points
        expect(result.first, equals(points.first));
        expect(result.last, equals(points.last));

        // Points should be in order
        for (int i = 1; i < result.length; i++) {
          expect(result[i].x, greaterThanOrEqualTo(result[i - 1].x));
        }
      });

      test('should be deterministic', () {
        final points = [Mappoint(0.0, 0.0), Mappoint(1.0, 0.1), Mappoint(2.0, 0.0), Mappoint(3.0, 0.1), Mappoint(4.0, 0.0)];

        final result1 = douglasPeucker.simplify(points, 0.05);
        final result2 = douglasPeucker.simplify(points, 0.05);

        expect(result1.length, equals(result2.length));
        for (int i = 0; i < result1.length; i++) {
          expect(result1[i].x, equals(result2[i].x));
          expect(result1[i].y, equals(result2[i].y));
        }
      });

      test('should handle complex geometric shapes', () {
        // Create a rough circle approximation
        final points = <Mappoint>[];
        for (int i = 0; i < 36; i++) {
          final angle = i * 10 * 3.14159 / 180; // 10 degrees each
          final x = 10.0 + 5.0 * (angle / 3.14159); // Rough approximation
          final y = 10.0 + 5.0 * ((i % 4) / 4.0); // Rough approximation
          points.add(Mappoint(x, y));
        }

        final result = douglasPeucker.simplify(points, 1.0);
        expect(result.length, lessThan(points.length));
        expect(result.length, greaterThan(4)); // Should keep key points
      });
    });

    group('Stress Testing', () {
      test('should handle extremely long paths', () {
        final points = <Mappoint>[];
        for (int i = 0; i < 10000; i++) {
          points.add(Mappoint(i.toDouble(), (i % 100).toDouble()));
        }

        final stopwatch = Stopwatch()..start();
        final result = douglasPeucker.simplify(points, 5.0);
        stopwatch.stop();

        expect(result.length, lessThan(points.length));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete in reasonable time
      });

      test('should handle rapid tolerance changes', () {
        final points = [Mappoint(0.0, 0.0), Mappoint(1.0, 0.1), Mappoint(2.0, 0.0), Mappoint(3.0, 0.1), Mappoint(4.0, 0.0)];

        final tolerances = [0.01, 0.1, 1.0, 0.05, 0.5];

        for (final tolerance in tolerances) {
          final result = douglasPeucker.simplify(points, tolerance);
          expect(result.length, greaterThanOrEqualTo(2));
          expect(result.first, equals(points.first));
          expect(result.last, equals(points.last));
        }
      });
    });
  });
}
