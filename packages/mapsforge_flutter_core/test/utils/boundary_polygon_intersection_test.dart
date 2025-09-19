import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';

void main() {
  group('LatLongUtils boundary-polygon intersection tests', () {
    // Define test polygons
    late List<ILatLong> squarePolygon;
    late List<ILatLong> trianglePolygon;
    late List<ILatLong> complexPolygon;

    setUp(() {
      // Square polygon centered around (52.52, 13.405)
      squarePolygon = [const LatLong(52.521, 13.404), const LatLong(52.521, 13.406), const LatLong(52.519, 13.406), const LatLong(52.519, 13.404)];

      // Triangle polygon
      trianglePolygon = [const LatLong(52.520, 13.405), const LatLong(52.522, 13.404), const LatLong(52.522, 13.406)];

      // Complex L-shaped polygon
      complexPolygon = [
        const LatLong(52.520, 13.404),
        const LatLong(52.522, 13.404),
        const LatLong(52.522, 13.405),
        const LatLong(52.521, 13.405),
        const LatLong(52.521, 13.407),
        const LatLong(52.520, 13.407),
      ];
    });

    group('doesBoundaryIntersectPolygon', () {
      test('should return true when boundary completely contains polygon', () {
        BoundingBox largeBoundary = const BoundingBox(52.518, 13.403, 52.523, 13.408);

        expect(LatLongUtils.doesBoundaryIntersectPolygon(largeBoundary, squarePolygon), isTrue);
        expect(LatLongUtils.doesBoundaryIntersectPolygon(largeBoundary, trianglePolygon), isTrue);
        expect(LatLongUtils.doesBoundaryIntersectPolygon(largeBoundary, complexPolygon), isTrue);
      });

      test('should return true when polygon completely contains boundary', () {
        BoundingBox smallBoundary = const BoundingBox(52.5205, 13.4045, 52.5206, 13.4055);

        expect(LatLongUtils.doesBoundaryIntersectPolygon(smallBoundary, squarePolygon), isTrue);
      });

      test('should return true when boundary and polygon partially intersect', () {
        // Boundary that overlaps with part of the square
        BoundingBox partialBoundary = const BoundingBox(52.520, 13.405, 52.522, 13.407);

        expect(LatLongUtils.doesBoundaryIntersectPolygon(partialBoundary, squarePolygon), isTrue);
        expect(LatLongUtils.doesBoundaryIntersectPolygon(partialBoundary, trianglePolygon), isTrue);
      });

      test('should return true when polygon edges intersect boundary edges', () {
        // Boundary that crosses through the polygon
        BoundingBox crossingBoundary = const BoundingBox(52.5195, 13.4035, 52.5205, 13.4045);

        expect(LatLongUtils.doesBoundaryIntersectPolygon(crossingBoundary, squarePolygon), isTrue);
      });

      test('should return false when boundary and polygon do not intersect', () {
        // Boundary completely separate from polygon
        BoundingBox separateBoundary = const BoundingBox(52.515, 13.400, 52.517, 13.402);

        expect(LatLongUtils.doesBoundaryIntersectPolygon(separateBoundary, squarePolygon), isFalse);
        expect(LatLongUtils.doesBoundaryIntersectPolygon(separateBoundary, trianglePolygon), isFalse);
        expect(LatLongUtils.doesBoundaryIntersectPolygon(separateBoundary, complexPolygon), isFalse);
      });

      test('should return false for invalid polygons', () {
        BoundingBox boundary = const BoundingBox(52.519, 13.404, 52.521, 13.406);

        // Empty polygon
        expect(LatLongUtils.doesBoundaryIntersectPolygon(boundary, []), isFalse);

        // Polygon with less than 3 points
        List<ILatLong> invalidPolygon = [const LatLong(52.520, 13.405), const LatLong(52.521, 13.406)];
        expect(LatLongUtils.doesBoundaryIntersectPolygon(boundary, invalidPolygon), isFalse);
      });

      test('should handle complex polygon shapes correctly', () {
        // Test with L-shaped polygon
        BoundingBox intersectingBoundary = const BoundingBox(52.5205, 13.4045, 52.5215, 13.4065);
        expect(LatLongUtils.doesBoundaryIntersectPolygon(intersectingBoundary, complexPolygon), isTrue);

        // Test with non-intersecting boundary
        BoundingBox nonIntersectingBoundary = const BoundingBox(52.523, 13.408, 52.525, 13.410);
        expect(LatLongUtils.doesBoundaryIntersectPolygon(nonIntersectingBoundary, complexPolygon), isFalse);
      });

      test('should handle edge cases with touching boundaries', () {
        // Boundary that just touches the polygon edge
        BoundingBox touchingBoundary = const BoundingBox(52.521, 13.406, 52.523, 13.408);
        expect(LatLongUtils.doesBoundaryIntersectPolygon(touchingBoundary, squarePolygon), isTrue);
      });
    });

    group('isBoundaryInsidePolygon', () {
      test('should return true when boundary is completely inside polygon', () {
        BoundingBox smallBoundary = const BoundingBox(52.5205, 13.4045, 52.5206, 13.4055);

        expect(LatLongUtils.isBoundaryInsidePolygon(smallBoundary, squarePolygon), isTrue);
      });

      test('should return false when boundary extends outside polygon', () {
        BoundingBox largeBoundary = const BoundingBox(52.518, 13.403, 52.523, 13.408);

        expect(LatLongUtils.isBoundaryInsidePolygon(largeBoundary, squarePolygon), isFalse);
        expect(LatLongUtils.isBoundaryInsidePolygon(largeBoundary, trianglePolygon), isFalse);
      });

      test('should return false when boundary partially overlaps polygon', () {
        BoundingBox partialBoundary = const BoundingBox(52.520, 13.405, 52.522, 13.407);

        expect(LatLongUtils.isBoundaryInsidePolygon(partialBoundary, squarePolygon), isFalse);
      });

      test('should return false when boundary is completely outside polygon', () {
        BoundingBox outsideBoundary = const BoundingBox(52.515, 13.400, 52.517, 13.402);

        expect(LatLongUtils.isBoundaryInsidePolygon(outsideBoundary, squarePolygon), isFalse);
      });

      test('should return false for invalid polygons', () {
        BoundingBox boundary = const BoundingBox(52.520, 13.405, 52.521, 13.406);

        // Empty polygon
        expect(LatLongUtils.isBoundaryInsidePolygon(boundary, []), isFalse);

        // Polygon with less than 3 points
        List<ILatLong> invalidPolygon = [const LatLong(52.520, 13.405), const LatLong(52.521, 13.406)];
        expect(LatLongUtils.isBoundaryInsidePolygon(boundary, invalidPolygon), isFalse);
      });

      test('should handle complex polygon shapes', () {
        // Small boundary inside the L-shaped polygon
        BoundingBox insideBoundary = const BoundingBox(52.5205, 13.4045, 52.5215, 13.4048);
        expect(LatLongUtils.isBoundaryInsidePolygon(insideBoundary, complexPolygon), isTrue);

        // Boundary that extends outside the L-shaped polygon
        BoundingBox outsideBoundary = const BoundingBox(52.5205, 13.4045, 52.5225, 13.4065);
        expect(LatLongUtils.isBoundaryInsidePolygon(outsideBoundary, complexPolygon), isFalse);
      });
    });

    group('performance and edge cases', () {
      test('should handle large polygons efficiently', () {
        // Create a polygon with many vertices
        List<ILatLong> largePolygon = [];
        for (int i = 0; i < 100; i++) {
          double angle = (i * 2 * 3.14159) / 100;
          largePolygon.add(LatLong(52.520 + 0.001 * cos(angle), 13.405 + 0.001 * sin(angle)));
        }

        BoundingBox testBoundary = const BoundingBox(52.5195, 13.4045, 52.5205, 13.4055);

        // Should complete without timeout
        expect(LatLongUtils.doesBoundaryIntersectPolygon(testBoundary, largePolygon), isTrue);
      });

      test('should handle very small boundaries and polygons', () {
        // Very small polygon
        List<ILatLong> tinyPolygon = [const LatLong(52.520000, 13.405000), const LatLong(52.520001, 13.405000), const LatLong(52.520001, 13.405001)];

        // Very small boundary
        BoundingBox tinyBoundary = const BoundingBox(52.5200005, 13.4050005, 52.5200015, 13.4050015);

        expect(LatLongUtils.doesBoundaryIntersectPolygon(tinyBoundary, tinyPolygon), isTrue);
      });

      test('should handle boundary at polygon edges correctly', () {
        // Boundary that aligns exactly with polygon edges
        BoundingBox edgeBoundary = const BoundingBox(52.519, 13.404, 52.521, 13.406);

        expect(LatLongUtils.doesBoundaryIntersectPolygon(edgeBoundary, squarePolygon), isTrue);
        expect(LatLongUtils.isBoundaryInsidePolygon(edgeBoundary, squarePolygon), isTrue);
      });
    });
  });
}
