import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/src/utils/object_pool.dart';
import 'package:mapsforge_flutter_renderer/src/util/layerutil.dart';
import 'package:mapsforge_flutter_renderer/src/util/spatial_boundary_index.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// Mock RenderInstruction for testing
class _MockRenderInstruction extends Renderinstruction {
  @override
  MapRectangle getBoundary(RenderInfo renderInfo) => const MapRectangle.zero();

  @override
  String getType() => 'mock';

  @override
  void matchNode(LayerContainer layerContainer, NodeProperties nodeProperties) {}

  @override
  void matchWay(LayerContainer layerContainer, WayProperties wayProperties) {}

  @override
  int level = 0;
}

// Mock RenderInfo for testing
class MockRenderInfo extends RenderInfo {
  final MapRectangle _boundary;

  MockRenderInfo(this._boundary) : super(_MockRenderInstruction()) {
    boundaryAbsolute = _boundary;
  }

  @override
  bool clashesWith(RenderInfo other) {
    final otherBoundary = other.boundaryAbsolute;
    if (otherBoundary == null) return false;
    return _boundary.intersects(otherBoundary);
  }

  @override
  void render(RenderContext renderContext) {}

  @override
  bool intersects(MapRectangle boundary) {
    return _boundary.intersects(boundary);
  }

  @override
  MapRectangle getBoundaryAbsolute() {
    return _boundary;
  }
}

void main() {
  group('Performance Optimization Tests', () {
    test('Spatial Index Performance', () {
      final spatialIndex = SpatialBoundaryIndex(cellSize: 100.0);
      final stopwatch = Stopwatch()..start();

      // Add 1000 items to spatial index
      final items = <MockRenderInfo>[];
      for (int i = 0; i < 1000; i++) {
        final boundary = MapRectangle(i.toDouble(), i.toDouble(), i + 10.0, i + 10.0);
        final item = MockRenderInfo(boundary);
        items.add(item);
        spatialIndex.add(item, item.getBoundaryAbsolute());
      }

      stopwatch.stop();
      print('Spatial Index Add: ${stopwatch.elapsedMicroseconds} microseconds for 1000 items');

      // Test collision detection performance
      stopwatch.reset();
      stopwatch.start();

      int collisions = 0;
      for (int i = 0; i < 100; i++) {
        final testBoundary = MapRectangle(i * 5.0, i * 5.0, i * 5.0 + 15.0, i * 5.0 + 15.0);
        final testItem = MockRenderInfo(testBoundary);
        if (spatialIndex.hasCollision(testItem, testItem.getBoundaryAbsolute())) {
          collisions++;
        }
      }

      stopwatch.stop();
      print('Spatial Index Collision Detection: ${stopwatch.elapsedMicroseconds} microseconds for 100 queries');
      print('Found $collisions collisions');

      expect(stopwatch.elapsedMicroseconds, lessThan(50000)); // Should be under 50ms
    });

    test('LayerUtil Collision Removal Performance', () {
      // Create test data
      final addElements = <MockRenderInfo>[];
      final keepElements = <MockRenderInfo>[];

      for (int i = 0; i < 100; i++) {
        addElements.add(MockRenderInfo(MapRectangle(i.toDouble(), i.toDouble(), i + 5.0, i + 5.0)));

        keepElements.add(MockRenderInfo(MapRectangle(i * 2.0, i * 2.0, i * 2.0 + 3.0, i * 2.0 + 3.0)));
      }

      final stopwatch = Stopwatch()..start();

      final result = LayerUtil.removeCollisions(addElements, keepElements);

      stopwatch.stop();
      print('LayerUtil removeCollisions: ${stopwatch.elapsedMicroseconds} microseconds');
      print('Kept ${result.length} out of ${addElements.length} elements');

      expect(stopwatch.elapsedMicroseconds, lessThan(100000)); // Should be under 100ms
      expect(result.length, lessThanOrEqualTo(addElements.length));
    });

    test('Object Pool Performance', () {
      final pool = ObjectPool<List<int>>(factory: () => <int>[], reset: (list) => list.clear(), maxSize: 10);

      final stopwatch = Stopwatch()..start();

      // Test acquire/release cycle
      for (int i = 0; i < 1000; i++) {
        final list = pool.acquire();
        list.addAll([1, 2, 3, 4, 5]);
        pool.release(list);
      }

      stopwatch.stop();
      print('Object Pool: ${stopwatch.elapsedMicroseconds} microseconds for 1000 acquire/release cycles');

      expect(stopwatch.elapsedMicroseconds, lessThan(10000)); // Should be under 10ms

      final stats = pool.getStats();
      print('Pool stats: $stats');
      expect(stats['poolSize'], lessThanOrEqualTo(stats['maxSize'] ?? 0));
    });

    test('Cache Key Hashing Performance', () {
      final tags = [const Tag('highway', 'primary'), const Tag('name', 'Main Street'), const Tag('maxspeed', '50'), const Tag('surface', 'asphalt')];

      final stopwatch = Stopwatch()..start();

      final keys = <String>[];
      for (int i = 0; i < 1000; i++) {
        // Create a simple cache key representation
        final key = '${tags.map((t) => '${t.key}=${t.value}').join(',')}:${i % 10}';
        keys.add(key);
        // Access hashCode to trigger calculation
        key.hashCode;
      }

      stopwatch.stop();
      print('Cache Key Creation: ${stopwatch.elapsedMicroseconds} microseconds for 1000 keys');

      // Test hash code caching
      stopwatch.reset();
      stopwatch.start();

      int totalHash = 0;
      for (final key in keys) {
        totalHash += key.hashCode; // Should use cached value
      }

      stopwatch.stop();
      print('Cache Key Hash Access: ${stopwatch.elapsedMicroseconds} microseconds for 1000 cached lookups');
      print('Total hash: $totalHash');

      expect(stopwatch.elapsedMicroseconds, lessThan(5000)); // Should be very fast with caching
    });

    test('Comprehensive Performance Benchmark', () {
      print('\n=== COMPREHENSIVE PERFORMANCE BENCHMARK ===');

      final overallStopwatch = Stopwatch()..start();

      // Simulate a complex rendering scenario
      final spatialIndex = SpatialBoundaryIndex();
      final renderItems = <MockRenderInfo>[];

      // Create 500 render items
      for (int i = 0; i < 500; i++) {
        final boundary = MapRectangle((i % 50).toDouble(), (i ~/ 50).toDouble(), (i % 50) + 2.0, (i ~/ 50) + 2.0);
        final item = MockRenderInfo(boundary);
        renderItems.add(item);
        spatialIndex.add(item, item.getBoundaryAbsolute());
      }

      // Perform collision detection for 100 new items
      final newItems = <MockRenderInfo>[];
      for (int i = 0; i < 100; i++) {
        final boundary = MapRectangle(i * 0.5, i * 0.5, i * 0.5 + 1.5, i * 0.5 + 1.5);
        newItems.add(MockRenderInfo(boundary));
      }

      // Use LayerUtil for collision removal
      final finalItems = LayerUtil.removeCollisions(newItems, renderItems);

      overallStopwatch.stop();

      print('Total benchmark time: ${overallStopwatch.elapsedMilliseconds}ms');
      print('Final items after collision removal: ${finalItems.length}/${newItems.length}');

      final spatialStats = spatialIndex.getStats();
      print('Spatial index stats: $spatialStats');

      // Performance should be significantly better than O(n²) approach
      expect(overallStopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
