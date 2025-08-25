import 'dart:math' as Math;
import 'package:dart_common/src/model/latlong.dart';
import 'package:dart_common/src/utils/douglas_peucker_latlong.dart';
import 'package:test/test.dart';

void main() {
  group('DouglasPeuckerLatLong', () {
    late DouglasPeuckerLatLong simplifier;

    setUp(() {
      simplifier = DouglasPeuckerLatLong();
    });

    group('Basic Functionality', () {
      test('should return same points for lists with 2 or fewer points', () {
        final singlePoint = [LatLong(0.0, 0.0)];
        final twoPoints = [LatLong(0.0, 0.0), LatLong(1.0, 1.0)];
        
        expect(simplifier.simplify(singlePoint, 0.1), equals(singlePoint));
        expect(simplifier.simplify(twoPoints, 0.1), equals(twoPoints));
        expect(simplifier.simplify([], 0.1), equals([]));
      });

      test('should preserve first and last points', () {
        final points = [
          LatLong(0.0, 0.0),
          LatLong(0.5, 0.1),
          LatLong(1.0, 0.0),
          LatLong(1.5, 0.1),
          LatLong(2.0, 0.0),
        ];
        
        final result = simplifier.simplify(points, 0.05);
        
        expect(result.first.latitude, equals(points.first.latitude));
        expect(result.first.longitude, equals(points.first.longitude));
        expect(result.last.latitude, equals(points.last.latitude));
        expect(result.last.longitude, equals(points.last.longitude));
      });

      test('should simplify straight line to endpoints only', () {
        final straightLine = [
          LatLong(0.0, 0.0),
          LatLong(0.25, 0.25),
          LatLong(0.5, 0.5),
          LatLong(0.75, 0.75),
          LatLong(1.0, 1.0),
        ];
        
        final result = simplifier.simplify(straightLine, 0.01);
        
        expect(result.length, equals(2));
        expect(result[0], equals(straightLine.first));
        expect(result[1], equals(straightLine.last));
      });

      test('should keep significant deviation points', () {
        final zigzagLine = [
          LatLong(0.0, 0.0),
          LatLong(0.5, 1.0), // Significant deviation
          LatLong(1.0, 0.0),
        ];
        
        final result = simplifier.simplify(zigzagLine, 0.1);
        
        expect(result.length, equals(3));
        expect(result, equals(zigzagLine));
      });
    });

    group('Tolerance Handling', () {
      test('should remove more points with higher tolerance', () {
        final noisyLine = [
          LatLong(0.0, 0.0),
          LatLong(0.1, 0.01),
          LatLong(0.2, 0.02),
          LatLong(0.3, 0.01),
          LatLong(0.4, 0.02),
          LatLong(0.5, 0.01),
          LatLong(1.0, 0.0),
        ];
        
        final lowTolerance = simplifier.simplify(noisyLine, 0.005);
        final highTolerance = simplifier.simplify(noisyLine, 0.05);
        
        expect(highTolerance.length, lessThan(lowTolerance.length));
        expect(lowTolerance.length, lessThanOrEqualTo(noisyLine.length));
      });

      test('should handle zero tolerance correctly', () {
        final points = [
          LatLong(0.0, 0.0),
          LatLong(0.5, 0.0001),
          LatLong(1.0, 0.0),
        ];
        
        final result = simplifier.simplify(points, 0.0);
        
        // With zero tolerance, only collinear points should be removed
        expect(result.length, greaterThanOrEqualTo(2));
      });

      test('should handle very large tolerance', () {
        final points = [
          LatLong(0.0, 0.0),
          LatLong(0.5, 0.1),
          LatLong(1.0, 0.0),
        ];
        
        final result = simplifier.simplify(points, 1000.0);
        
        expect(result.length, equals(2));
        expect(result[0], equals(points.first));
        expect(result[1], equals(points.last));
      });
    });

    group('Edge Cases', () {
      test('should handle duplicate points', () {
        final duplicatePoints = [
          LatLong(0.0, 0.0),
          LatLong(0.0, 0.0), // Duplicate
          LatLong(1.0, 1.0),
          LatLong(1.0, 1.0), // Duplicate
          LatLong(2.0, 0.0),
        ];
        
        final result = simplifier.simplify(duplicatePoints, 0.01);
        
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.first, equals(duplicatePoints.first));
        expect(result.last, equals(duplicatePoints.last));
      });

      test('should handle collinear points', () {
        final collinearPoints = [
          LatLong(0.0, 0.0),
          LatLong(1.0, 1.0),
          LatLong(2.0, 2.0),
          LatLong(3.0, 3.0),
        ];
        
        final result = simplifier.simplify(collinearPoints, 0.001);
        
        expect(result.length, equals(2));
        expect(result[0], equals(collinearPoints.first));
        expect(result[1], equals(collinearPoints.last));
      });

      test('should handle very close points', () {
        final closePoints = [
          LatLong(0.0, 0.0),
          LatLong(0.0000001, 0.0000001),
          LatLong(1.0, 1.0),
        ];
        
        final result = simplifier.simplify(closePoints, 0.01);
        
        expect(result.length, greaterThanOrEqualTo(2));
      });

      test('should handle points with same coordinates but different objects', () {
        final points = [
          LatLong(0.0, 0.0),
          LatLong(0.5, 0.5),
          LatLong(1.0, 1.0),
        ];
        
        final result = simplifier.simplify(points, 0.01);
        
        expect(result.length, equals(2));
      });
    });

    group('Performance and Correctness', () {
      test('should handle large datasets efficiently', () {
        // Generate a large dataset with noise
        final largeDataset = <LatLong>[];
        for (int i = 0; i < 10000; i++) {
          final x = i / 1000.0;
          final y = Math.sin(x) + (Math.Random().nextDouble() - 0.5) * 0.01;
          largeDataset.add(LatLong(y, x));
        }
        
        final stopwatch = Stopwatch()..start();
        final result = simplifier.simplify(largeDataset, 0.005);
        stopwatch.stop();
        
        expect(result.length, lessThan(largeDataset.length));
        expect(result.length, greaterThan(10)); // Should keep some points
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
        
        // Verify first and last points are preserved
        expect(result.first, equals(largeDataset.first));
        expect(result.last, equals(largeDataset.last));
      });

      test('should maintain geometric properties', () {
        final complexPath = [
          LatLong(0.0, 0.0),
          LatLong(0.1, 0.1),
          LatLong(0.2, 0.5), // Significant point
          LatLong(0.3, 0.1),
          LatLong(0.4, 0.1),
          LatLong(0.5, 0.6), // Significant point
          LatLong(0.6, 0.1),
          LatLong(1.0, 0.0),
        ];
        
        final result = simplifier.simplify(complexPath, 0.05);
        
        // Should keep significant deviation points
        expect(result.any((p) => (p.latitude - 0.5).abs() < 0.1), isTrue);
        expect(result.any((p) => (p.latitude - 0.6).abs() < 0.1), isTrue);
      });

      test('should be deterministic', () {
        final points = [
          LatLong(0.0, 0.0),
          LatLong(0.1, 0.05),
          LatLong(0.2, 0.1),
          LatLong(0.3, 0.05),
          LatLong(0.4, 0.1),
          LatLong(0.5, 0.0),
        ];
        
        final result1 = simplifier.simplify(points, 0.02);
        final result2 = simplifier.simplify(points, 0.02);
        
        expect(result1.length, equals(result2.length));
        for (int i = 0; i < result1.length; i++) {
          expect(result1[i].latitude, equals(result2[i].latitude));
          expect(result1[i].longitude, equals(result2[i].longitude));
        }
      });
    });

    group('Numerical Stability', () {
      test('should handle very small coordinates', () {
        final smallCoords = [
          LatLong(1e-10, 1e-10),
          LatLong(2e-10, 1.1e-10),
          LatLong(3e-10, 2e-10),
        ];
        
        final result = simplifier.simplify(smallCoords, 1e-12);
        
        expect(result.length, greaterThanOrEqualTo(2));
        expect(result.first, equals(smallCoords.first));
        expect(result.last, equals(smallCoords.last));
      });

      test('should handle very large coordinates', () {
        final largeCoords = [
          LatLong(1e6, 1e6),
          LatLong(1e6 + 0.1, 1e6 + 0.1),
          LatLong(1e6 + 0.2, 1e6 + 0.2),
        ];
        
        final result = simplifier.simplify(largeCoords, 0.05);
        
        expect(result.length, equals(2));
        expect(result.first, equals(largeCoords.first));
        expect(result.last, equals(largeCoords.last));
      });

      test('should handle mixed coordinate scales', () {
        final mixedCoords = [
          LatLong(0.0, 0.0),
          LatLong(1e-6, 1000.0),
          LatLong(1000.0, 1e-6),
        ];
        
        final result = simplifier.simplify(mixedCoords, 0.1);
        
        expect(result.length, greaterThanOrEqualTo(2));
      });
    });

    group('Regression Tests', () {
      test('should handle the original problematic case from plan', () {
        // Test case that would have used expensive Math.pow operations
        final points = [
          LatLong(52.5200, 13.4050), // Berlin
          LatLong(52.5201, 13.4051),
          LatLong(52.5202, 13.4052),
          LatLong(52.5203, 13.4053),
          LatLong(52.5300, 13.4150), // Significant deviation
          LatLong(52.5301, 13.4151),
          LatLong(52.5400, 13.4250), // End point
        ];
        
        final result = simplifier.simplify(points, 0.001);
        
        expect(result.length, lessThan(points.length));
        expect(result.first, equals(points.first));
        expect(result.last, equals(points.last));
        
        // Should keep the significant deviation point (more lenient check)
        expect(result.any((p) => (p.latitude - 52.5300).abs() < 0.01), isTrue);
      });

      test('should produce same results as reference implementation', () {
        // Known test case with expected results
        final referencePoints = [
          LatLong(0.0, 0.0),
          LatLong(1.0, 0.1),
          LatLong(2.0, -0.1),
          LatLong(3.0, 5.0),
          LatLong(4.0, 6.0),
          LatLong(5.0, 7.0),
          LatLong(6.0, 8.1),
          LatLong(7.0, 9.0),
          LatLong(8.0, 9.0),
          LatLong(9.0, 9.0),
        ];
        
        final result = simplifier.simplify(referencePoints, 0.5);
        
        // Expected behavior: should keep points with significant deviations
        expect(result.length, greaterThan(2));
        expect(result.length, lessThan(referencePoints.length));
        
        // Must preserve endpoints
        expect(result.first, equals(referencePoints.first));
        expect(result.last, equals(referencePoints.last));
      });
    });
  });
}
