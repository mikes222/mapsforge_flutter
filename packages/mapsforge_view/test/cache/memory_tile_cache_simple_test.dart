import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_view/src/cache/spatial_tile_index.dart';

// Mock Tile class for testing
class MockTile extends Tile {
  final BoundingBox _boundingBox;
  final String _id;

  MockTile(this._id, this._boundingBox) : super(0, 0, 0, 0);

  @override
  BoundingBox getBoundingBox() => _boundingBox;

  @override
  String toString() => 'MockTile($_id)';

  @override
  bool operator ==(Object other) => identical(this, other) || other is MockTile && _id == other._id;

  @override
  int get hashCode => _id.hashCode;
}

void main() {
  group('Cache Optimizations - Spatial Index Only', () {
    late SpatialTileIndex spatialIndex;

    setUp(() {
      spatialIndex = SpatialTileIndex(cellSize: 1.0);
    });

    group('Basic Operations', () {
      test('should start empty', () {
        expect(spatialIndex.tileCount, equals(0));
        expect(spatialIndex.gridCellCount, equals(0));
      });

      test('should add and track tiles correctly', () {
        final tile1 = MockTile('tile1', BoundingBox(0.0, 0.0, 1.0, 1.0));
        final tile2 = MockTile('tile2', BoundingBox(2.0, 2.0, 3.0, 3.0));

        spatialIndex.addTile(tile1);
        spatialIndex.addTile(tile2);

        expect(spatialIndex.tileCount, equals(2));
        expect(spatialIndex.gridCellCount, greaterThan(0));
      });

      test('should remove tiles correctly', () {
        final tile1 = MockTile('tile1', BoundingBox(0.0, 0.0, 1.0, 1.0));
        final tile2 = MockTile('tile2', BoundingBox(2.0, 2.0, 3.0, 3.0));

        spatialIndex.addTile(tile1);
        spatialIndex.addTile(tile2);
        spatialIndex.removeTile(tile1);

        expect(spatialIndex.tileCount, equals(1));
      });
    });

    group('Boundary-Based Queries', () {
      test('should find tiles within boundary efficiently', () {
        final tile1 = MockTile('tile1', BoundingBox(0.0, 0.0, 1.0, 1.0));
        final tile2 = MockTile('tile2', BoundingBox(2.0, 2.0, 3.0, 3.0));
        final tile3 = MockTile('tile3', BoundingBox(0.5, 0.5, 1.5, 1.5));

        spatialIndex.addTile(tile1);
        spatialIndex.addTile(tile2);
        spatialIndex.addTile(tile3);

        // Query overlapping with tile1 and tile3
        final queryBounds = BoundingBox(0.0, 0.0, 1.2, 1.2);
        final result = spatialIndex.getTilesInBoundary(queryBounds);

        expect(result.length, equals(2));
        expect(result.contains(tile1), isTrue);
        expect(result.contains(tile3), isTrue);
        expect(result.contains(tile2), isFalse);
      });

      test('should handle empty query results', () {
        final tile1 = MockTile('tile1', BoundingBox(0.0, 0.0, 1.0, 1.0));
        spatialIndex.addTile(tile1);

        // Query far from tile1
        final queryBounds = BoundingBox(10.0, 10.0, 11.0, 11.0);
        final result = spatialIndex.getTilesInBoundary(queryBounds);

        expect(result.isEmpty, isTrue);
      });
    });

    group('Performance Validation', () {
      test('should handle large number of tiles efficiently', () {
        final stopwatch = Stopwatch()..start();

        // Add 1000 tiles in a grid pattern
        for (int i = 0; i < 1000; i++) {
          final x = (i % 10).toDouble();
          final y = (i ~/ 10).toDouble();
          final tile = MockTile('tile$i', BoundingBox(x, y, x + 0.5, y + 0.5));
          spatialIndex.addTile(tile);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be very fast

        expect(spatialIndex.tileCount, equals(1000));
      });

      test('should perform spatial queries efficiently', () {
        // Add many tiles
        for (int i = 0; i < 1000; i++) {
          final x = (i % 10).toDouble();
          final y = (i ~/ 10).toDouble();
          final tile = MockTile('tile$i', BoundingBox(x, y, x + 0.5, y + 0.5));
          spatialIndex.addTile(tile);
        }

        final stopwatch = Stopwatch()..start();

        // Perform multiple queries
        for (int i = 0; i < 100; i++) {
          final queryBounds = BoundingBox(0.0, 0.0, 2.0, 2.0);
          spatialIndex.getTilesInBoundary(queryBounds);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should be very fast
      });
    });

    group('Statistics and Monitoring', () {
      test('should provide accurate statistics', () {
        final tile1 = MockTile('tile1', BoundingBox(0.0, 0.0, 1.0, 1.0));
        final tile2 = MockTile('tile2', BoundingBox(2.0, 2.0, 3.0, 3.0));

        spatialIndex.addTile(tile1);
        spatialIndex.addTile(tile2);

        final stats = spatialIndex.getStatistics();

        expect(stats['totalTiles'], equals(2));
        expect(stats['gridCells'], greaterThan(0));
        expect(stats['cellSize'], equals(1.0));
        expect(stats['avgTilesPerCell'], greaterThan(0.0));
      });

      test('should handle empty index statistics', () {
        final stats = spatialIndex.getStatistics();

        expect(stats['totalTiles'], equals(0));
        expect(stats['gridCells'], equals(0));
        expect(stats['avgTilesPerCell'], equals(0.0));
      });
    });
  });
}
