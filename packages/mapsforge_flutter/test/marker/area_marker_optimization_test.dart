import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/src/marker/area_marker.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';

void main() {
  group('AreaMarker shouldPaint optimization', () {
    late AreaMarker<String> areaMarker;

    setUp(() {
      // Create a small area marker for testing
      List<ILatLong> smallPath = [
        LatLong(52.5200, 13.4050), // Berlin center
        LatLong(52.5201, 13.4050),
        LatLong(52.5201, 13.4051),
        LatLong(52.5200, 13.4051),
      ];

      areaMarker = AreaMarker<String>(path: smallPath, strokeWidth: 2.0, strokeColor: 0xff000000, fillColor: 0x80ff0000);
    });

    test('should paint at low zoom levels', () async {
      // Initialize the marker for zoom level 10
      await areaMarker.changeZoomlevel(10, PixelProjection(10));

      // Create a boundary that intersects with the area
      BoundingBox boundary = BoundingBox(52.519, 13.404, 52.521, 13.406);

      // Should paint at zoom level 10 (below threshold)
      expect(areaMarker.shouldPaint(boundary, 10), isTrue);
    });

    test('should skip painting very small areas at high zoom levels', () async {
      // Initialize the marker for zoom level 18
      await areaMarker.changeZoomlevel(18, PixelProjection(18));

      // Create a very small boundary that barely intersects
      BoundingBox smallBoundary = BoundingBox(52.52005, 13.40505, 52.52006, 13.40506);

      // Should skip painting at zoom level 18 due to small pixel size
      expect(areaMarker.shouldPaint(smallBoundary, 18), isFalse);
    });

    test('should paint larger intersections at high zoom levels', () async {
      // Initialize the marker for zoom level 15
      await areaMarker.changeZoomlevel(15, PixelProjection(15));

      // Create a boundary that has significant intersection
      BoundingBox largeBoundary = BoundingBox(52.5199, 13.4049, 52.5202, 13.4052);

      // Should still paint at zoom level 15 if intersection is large enough
      expect(areaMarker.shouldPaint(largeBoundary, 15), isTrue);
    });

    test('should respect zoom level range', () async {
      // Create marker with limited zoom range
      AreaMarker<String> limitedMarker = AreaMarker<String>(
        path: [LatLong(52.5200, 13.4050), LatLong(52.5201, 13.4051), LatLong(52.5200, 13.4051)],
        zoomlevelRange: ZoomlevelRange(5, 12),
      );

      await limitedMarker.changeZoomlevel(15, PixelProjection(15));

      BoundingBox boundary = BoundingBox(52.519, 13.404, 52.521, 13.406);

      // Should not paint outside zoom level range
      expect(limitedMarker.shouldPaint(boundary, 15), isFalse);
    });

    test('should handle non-intersecting boundaries', () async {
      await areaMarker.changeZoomlevel(15, PixelProjection(15));

      // Create a boundary that doesn't intersect with the area
      BoundingBox nonIntersectingBoundary = BoundingBox(52.510, 13.390, 52.515, 13.395);

      // Should not paint when boundaries don't intersect
      expect(areaMarker.shouldPaint(nonIntersectingBoundary, 15), isFalse);
    });

    test('optimization behavior with very small intersections', () async {
      // Create a very small area marker
      List<ILatLong> tinyPath = [LatLong(52.520000, 13.405000), LatLong(52.520001, 13.405000), LatLong(52.520001, 13.405001), LatLong(52.520000, 13.405001)];

      AreaMarker<String> tinyMarker = AreaMarker<String>(path: tinyPath, strokeWidth: 1.0);

      await tinyMarker.changeZoomlevel(18, PixelProjection(18));

      // Test with a boundary that barely intersects
      BoundingBox tinyBoundary = BoundingBox(52.5200005, 13.4050005, 52.5200006, 13.4050006);

      // At zoom level 18, this tiny intersection should be skipped
      expect(tinyMarker.shouldPaint(tinyBoundary, 18), isFalse);
    });
  });
}
