import 'package:test/test.dart';
import 'package:dart_common/model.dart';
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
  bool operator ==(Object other) =>
      identical(this, other) || other is MockTile && _id == other._id;

  @override
  int get hashCode => _id.hashCode;
}

void main() {
  group('SpatialTileIndex', () {
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

      test('should clear all tiles', () {
        final tile1 = MockTile('tile1', BoundingBox(0.0, 0.0, 1.0, 1.0));
        final tile2 = MockTile('tile2', BoundingBox(2.0, 2.0, 3.0, 3.0));

        spatialIndex.addTile(tile1);
        spatialIndex.addTile(tile2);
        spatialIndex.clear();

        expect(spatialIndex.tileCount, equals(0));
        expect(spatialIndex.gridCellCount, equals(0));
      });
    });

    group('Spatial Queries', () {
      test('should find tiles within boundary', () {
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

      test('should handle tiles spanning multiple cells', () {
        // Large tile spanning multiple grid cells
        final largeTile = MockTile('large', BoundingBox(0.0, 0.0, 2.5, 2.5));
        spatialIndex.addTile(largeTile);

        // Query in different corners should find the same tile
        final query1 = BoundingBox(0.0, 0.0, 0.5, 0.5);
        final query2 = BoundingBox(2.0, 2.0, 2.5, 2.5);

        final result1 = spatialIndex.getTilesInBoundary(query1);
        final result2 = spatialIndex.getTilesInBoundary(query2);

        expect(result1.contains(largeTile), isTrue);
        expect(result2.contains(largeTile), isTrue);
      });
    });

    group('Performance Tests', () {
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

    group('Edge Cases', () {
      test('should handle tiles with zero-size boundaries', () {
        final pointTile = MockTile('point', BoundingBox(1.0, 1.0, 1.0, 1.0));
        spatialIndex.addTile(pointTile);

        final queryBounds = BoundingBox(0.5, 0.5, 1.5, 1.5);
        final result = spatialIndex.getTilesInBoundary(queryBounds);

        expect(result.contains(pointTile), isTrue);
      });

      test('should handle negative coordinates', () {
        final tile = MockTile('negative', BoundingBox(-2.0, -2.0, -1.0, -1.0));
        spatialIndex.addTile(tile);

        final queryBounds = BoundingBox(-2.5, -2.5, -0.5, -0.5);
        final result = spatialIndex.getTilesInBoundary(queryBounds);

        expect(result.contains(tile), isTrue);
      });

      test('should handle very large coordinates', () {
        final tile = MockTile('large_coords', BoundingBox(1000.0, 1000.0, 1001.0, 1001.0));
        spatialIndex.addTile(tile);

        final queryBounds = BoundingBox(999.5, 999.5, 1001.5, 1001.5);
        final result = spatialIndex.getTilesInBoundary(queryBounds);

        expect(result.contains(tile), isTrue);
      });
    });

    group('Statistics', () {
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

    group('Cell Size Configuration', () {
      test('should work with different cell sizes', () {
        final smallCellIndex = SpatialTileIndex(cellSize: 0.1);
        final largeCellIndex = SpatialTileIndex(cellSize: 10.0);

        final tile = MockTile('tile', BoundingBox(0.0, 0.0, 1.0, 1.0));

        smallCellIndex.addTile(tile);
        largeCellIndex.addTile(tile);

        final smallStats = smallCellIndex.getStatistics();
        final largeStats = largeCellIndex.getStatistics();

        // Small cells should create more grid cells for the same tile
        expect(smallStats['gridCells'], greaterThan(largeStats['gridCells']));
      });
    });
  });
}
