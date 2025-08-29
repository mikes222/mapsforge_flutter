import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/util/spatial_index.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simple mock RenderInfo for testing spatial index functionality
class TestRenderInfo extends RenderInfo {
  final MapRectangle? _boundary;
  final bool _shouldClash;
  final String _id;

  TestRenderInfo(this._id, this._boundary, {bool shouldClash = false}) : _shouldClash = shouldClash, super(_MockRenderInstruction()) {
    boundaryAbsolute = _boundary;
  }

  @override
  bool clashesWith(RenderInfo other) {
    if (other is TestRenderInfo) {
      return _shouldClash && other._shouldClash;
    }
    return _shouldClash;
  }

  @override
  MapRectangle getBoundaryAbsolute() {
    return _boundary ?? MapRectangle(0, 0, 0, 0);
  }

  @override
  bool intersects(MapRectangle other) {
    if (_boundary == null) return false;
    return _boundary!.intersects(other);
  }

  @override
  void render(RenderContext renderContext) {
    // Mock implementation - do nothing
  }

  @override
  String toString() => 'TestRenderInfo($_id)';
}

/// Mock RenderInfo that throws exception during collision check
class ExceptionRenderInfo extends TestRenderInfo {
  ExceptionRenderInfo(String id, MapRectangle? boundary) : super(id, boundary);

  @override
  bool clashesWith(RenderInfo other) {
    throw Exception('Test exception during collision check');
  }
}

/// Minimal mock RenderInstruction
class _MockRenderInstruction extends Renderinstruction {
  @override
  MapRectangle getBoundary() => MapRectangle(0, 0, 0, 0);

  @override
  ShapePainter? getPainter() => null;

  @override
  String getType() => 'mock';

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {}

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {}

  int level = 0;
}

void main() {
  group('SpatialIndex', () {
    late SpatialIndex spatialIndex;

    setUp(() {
      spatialIndex = SpatialIndex(cellSize: 100.0);
    });

    group('Constructor', () {
      test('should create with default cell size', () {
        final index = SpatialIndex();
        expect(index, isNotNull);
      });

      test('should create with custom cell size', () {
        final index = SpatialIndex(cellSize: 50.0);
        expect(index, isNotNull);
      });
    });

    group('add()', () {
      test('should add item with boundary to index', () {
        final boundary = MapRectangle(0, 0, 50, 50);
        final item = TestRenderInfo('item1', boundary);

        spatialIndex.add(item);

        final stats = spatialIndex.getStats();
        expect(stats['totalItems'], equals(1));
        expect(stats['totalCells'], equals(1));
      });

      test('should handle item with null boundary', () {
        final item = TestRenderInfo('item1', null);

        spatialIndex.add(item);

        final stats = spatialIndex.getStats();
        expect(stats['totalItems'], equals(0));
        expect(stats['totalCells'], equals(0));
      });

      test('should add item spanning multiple cells', () {
        final boundary = MapRectangle(0, 0, 150, 150); // Spans 4 cells with cellSize=100
        final item = TestRenderInfo('item1', boundary);

        spatialIndex.add(item);

        final stats = spatialIndex.getStats();
        expect(stats['totalItems'], equals(4)); // Item added to 4 cells
        expect(stats['totalCells'], equals(4));
      });

      test('should add multiple items to same cell', () {
        final boundary1 = MapRectangle(10, 10, 20, 20);
        final boundary2 = MapRectangle(30, 30, 40, 40);
        final item1 = TestRenderInfo('item1', boundary1);
        final item2 = TestRenderInfo('item2', boundary2);

        spatialIndex.add(item1);
        spatialIndex.add(item2);

        final stats = spatialIndex.getStats();
        expect(stats['totalItems'], equals(2));
        expect(stats['totalCells'], equals(1)); // Both in same cell
        expect(stats['maxItemsPerCell'], equals(2));
      });
    });

    group('hasCollision()', () {
      test('should return false for item with null boundary', () {
        final item = TestRenderInfo('item1', null);

        final hasCollision = spatialIndex.hasCollision(item);

        expect(hasCollision, isFalse);
      });

      test('should return false when no items in index', () {
        final boundary = MapRectangle(0, 0, 50, 50);
        final item = TestRenderInfo('item1', boundary);

        final hasCollision = spatialIndex.hasCollision(item);

        expect(hasCollision, isFalse);
      });

      test('should return false when no collision occurs', () {
        final boundary1 = MapRectangle(0, 0, 50, 50);
        final boundary2 = MapRectangle(60, 60, 110, 110);
        final item1 = TestRenderInfo('item1', boundary1, shouldClash: false);
        final item2 = TestRenderInfo('item2', boundary2, shouldClash: false);

        spatialIndex.add(item1);
        final hasCollision = spatialIndex.hasCollision(item2);

        expect(hasCollision, isFalse);
      });

      test('should return true when collision occurs', () {
        final boundary1 = MapRectangle(0, 0, 50, 50);
        final boundary2 = MapRectangle(25, 25, 75, 75);
        final item1 = TestRenderInfo('item1', boundary1, shouldClash: true);
        final item2 = TestRenderInfo('item2', boundary2, shouldClash: true);

        spatialIndex.add(item1);
        final hasCollision = spatialIndex.hasCollision(item2);

        expect(hasCollision, isTrue);
      });

      test('should handle exception during collision check gracefully', () {
        final boundary1 = MapRectangle(0, 0, 50, 50);
        final boundary2 = MapRectangle(25, 25, 75, 75);
        final item1 = ExceptionRenderInfo('item1', boundary1);
        final item2 = TestRenderInfo('item2', boundary2);

        spatialIndex.add(item1);
        final hasCollision = spatialIndex.hasCollision(item2);

        // Should not throw exception and return false
        expect(hasCollision, isFalse);
      });

      test('should check collision across multiple cells', () {
        final boundary1 = MapRectangle(0, 0, 150, 150); // Spans multiple cells
        final boundary2 = MapRectangle(120, 120, 170, 170); // Overlaps with item1
        final item1 = TestRenderInfo('item1', boundary1, shouldClash: true);
        final item2 = TestRenderInfo('item2', boundary2, shouldClash: true);

        spatialIndex.add(item1);
        final hasCollision = spatialIndex.hasCollision(item2);

        expect(hasCollision, isTrue);
      });
    });

    group('_getCells()', () {
      test('should return single cell for small boundary', () {
        final boundary = MapRectangle(10, 10, 50, 50);
        final item = TestRenderInfo('item1', boundary);

        spatialIndex.add(item);

        final stats = spatialIndex.getStats();
        expect(stats['totalCells'], equals(1));
      });

      test('should return multiple cells for boundary spanning cells', () {
        final boundary = MapRectangle(50, 50, 150, 150); // Crosses cell boundaries
        final item = TestRenderInfo('item1', boundary);

        spatialIndex.add(item);

        final stats = spatialIndex.getStats();
        expect(stats['totalCells'], equals(4)); // 2x2 grid
      });

      test('should handle negative coordinates', () {
        final boundary = MapRectangle(-50, -50, 50, 50);
        final item = TestRenderInfo('item1', boundary);

        spatialIndex.add(item);

        final stats = spatialIndex.getStats();
        expect(stats['totalItems'], greaterThan(0));
      });

      test('should handle zero-size boundary', () {
        final boundary = MapRectangle(100, 100, 100, 100);
        final item = TestRenderInfo('item1', boundary);

        spatialIndex.add(item);

        final stats = spatialIndex.getStats();
        expect(stats['totalItems'], equals(1));
        expect(stats['totalCells'], equals(1));
      });
    });

    group('clear()', () {
      test('should clear all items from index', () {
        final boundary1 = MapRectangle(0, 0, 50, 50);
        final boundary2 = MapRectangle(100, 100, 150, 150);
        final item1 = TestRenderInfo('item1', boundary1);
        final item2 = TestRenderInfo('item2', boundary2);

        spatialIndex.add(item1);
        spatialIndex.add(item2);

        var stats = spatialIndex.getStats();
        expect(stats['totalItems'], greaterThan(0));

        spatialIndex.clear();

        stats = spatialIndex.getStats();
        expect(stats['totalItems'], equals(0));
        expect(stats['totalCells'], equals(0));
      });

      test('should allow adding items after clear', () {
        final boundary = MapRectangle(0, 0, 50, 50);
        final item = TestRenderInfo('item1', boundary);

        spatialIndex.add(item);
        spatialIndex.clear();
        spatialIndex.add(item);

        final stats = spatialIndex.getStats();
        expect(stats['totalItems'], equals(1));
      });
    });

    group('getStats()', () {
      test('should return correct stats for empty index', () {
        final stats = spatialIndex.getStats();

        expect(stats['totalCells'], equals(0));
        expect(stats['totalItems'], equals(0));
        expect(stats['maxItemsPerCell'], equals(0));
        expect(stats['avgItemsPerCell'], equals(0.0));
      });

      test('should return correct stats for single item', () {
        final boundary = MapRectangle(0, 0, 50, 50);
        final item = TestRenderInfo('item1', boundary);

        spatialIndex.add(item);

        final stats = spatialIndex.getStats();
        expect(stats['totalCells'], equals(1));
        expect(stats['totalItems'], equals(1));
        expect(stats['maxItemsPerCell'], equals(1));
        expect(stats['avgItemsPerCell'], equals(1.0));
      });

      test('should return correct stats for multiple items', () {
        final boundary1 = MapRectangle(0, 0, 50, 50);
        final boundary2 = MapRectangle(25, 25, 75, 75); // Same cell as item1
        final boundary3 = MapRectangle(200, 200, 250, 250); // Different cell
        final item1 = TestRenderInfo('item1', boundary1);
        final item2 = TestRenderInfo('item2', boundary2);
        final item3 = TestRenderInfo('item3', boundary3);

        spatialIndex.add(item1);
        spatialIndex.add(item2);
        spatialIndex.add(item3);

        final stats = spatialIndex.getStats();
        expect(stats['totalCells'], equals(2));
        expect(stats['totalItems'], equals(3));
        expect(stats['maxItemsPerCell'], equals(2));
        expect(stats['avgItemsPerCell'], equals(1.5));
      });

      test('should handle item spanning multiple cells in stats', () {
        final boundary = MapRectangle(0, 0, 250, 250); // Spans 9 cells (3x3)
        final item = TestRenderInfo('item1', boundary);

        spatialIndex.add(item);

        final stats = spatialIndex.getStats();
        expect(stats['totalCells'], equals(9));
        expect(stats['totalItems'], equals(9)); // Item counted in each cell
        expect(stats['maxItemsPerCell'], equals(1));
        expect(stats['avgItemsPerCell'], equals(1.0));
      });
    });

    group('Performance', () {
      test('should handle large number of items efficiently', () {
        final stopwatch = Stopwatch()..start();

        // Add 1000 items
        for (int i = 0; i < 1000; i++) {
          final x = (i % 100) * 10.0;
          final y = (i ~/ 100) * 10.0;
          final boundary = MapRectangle(x, y, x + 5, y + 5);
          final item = TestRenderInfo('item$i', boundary);
          spatialIndex.add(item);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast

        final stats = spatialIndex.getStats();
        expect(stats['totalItems'], equals(1000));
      });

      test('should perform collision detection efficiently', () {
        // Add many items
        for (int i = 0; i < 500; i++) {
          final x = (i % 50) * 20.0;
          final y = (i ~/ 50) * 20.0;
          final boundary = MapRectangle(x, y, x + 10, y + 10);
          final item = TestRenderInfo('item$i', boundary, shouldClash: true);
          spatialIndex.add(item);
        }

        final stopwatch = Stopwatch()..start();

        // Test collision detection
        for (int i = 0; i < 100; i++) {
          final boundary = MapRectangle(i * 5.0, i * 5.0, i * 5.0 + 15, i * 5.0 + 15);
          final testItem = TestRenderInfo('test$i', boundary, shouldClash: true);
          spatialIndex.hasCollision(testItem);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should be fast
      });
    });

    group('Edge Cases', () {
      test('should handle large boundaries', () {
        final boundary = MapRectangle(-1000, -1000, 1000, 1000);
        final item = TestRenderInfo('large', boundary);

        spatialIndex.add(item);

        final stats = spatialIndex.getStats();
        expect(stats['totalItems'], greaterThan(0));
        expect(stats['totalCells'], greaterThan(0));
      });

      test('should handle boundaries at cell boundaries', () {
        final boundary = MapRectangle(100, 100, 200, 200); // Exactly on cell boundaries
        final item = TestRenderInfo('boundary', boundary);

        spatialIndex.add(item);

        final stats = spatialIndex.getStats();
        expect(stats['totalItems'], equals(4)); // Should span 4 cells
      });

      test('should handle very small cell size', () {
        final smallCellIndex = SpatialIndex(cellSize: 1.0);
        final boundary = MapRectangle(0, 0, 5, 5);
        final item = TestRenderInfo('small', boundary);

        smallCellIndex.add(item);

        final stats = smallCellIndex.getStats();
        expect(stats['totalItems'], equals(36)); // 6x6 grid
      });

      test('should handle very large cell size', () {
        final largeCellIndex = SpatialIndex(cellSize: 10000.0);
        final boundary1 = MapRectangle(0, 0, 50, 50);
        final boundary2 = MapRectangle(1000, 1000, 1050, 1050);
        final item1 = TestRenderInfo('item1', boundary1);
        final item2 = TestRenderInfo('item2', boundary2);

        largeCellIndex.add(item1);
        largeCellIndex.add(item2);

        final stats = largeCellIndex.getStats();
        expect(stats['totalCells'], equals(1)); // Both in same large cell
        expect(stats['totalItems'], equals(2));
      });
    });
  });
}
