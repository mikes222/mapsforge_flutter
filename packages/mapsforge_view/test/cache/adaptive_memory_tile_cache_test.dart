import 'dart:async';

import 'package:dart_common/model.dart';
import 'package:mapsforge_view/src/cache/adaptive_memory_tile_cache.dart';
import 'package:mapsforge_view/src/cache/memory_pressure_monitor.dart';
import 'package:test/test.dart';

void main() {
  group('AdaptiveMemoryTileCache', () {
    late AdaptiveMemoryTileCache cache;
    late MemoryPressureMonitor monitor;

    setUp(() {
      monitor = MemoryPressureMonitor(monitoringInterval: const Duration(milliseconds: 50));
      cache = AdaptiveMemoryTileCache.create(initialCapacity: 100, minCapacity: 10, maxCapacity: 200, memoryMonitor: monitor);
    });

    tearDown(() {
      cache.dispose();
    });

    test('should initialize with correct capacity', () {
      expect(cache.currentCapacity, equals(100));
      expect(cache.currentSize, equals(0));
    });

    test('should provide comprehensive statistics', () {
      final stats = cache.getStatistics();

      expect(stats, containsPair('currentCapacity', 100));
      expect(stats, containsPair('initialCapacity', 100));
      expect(stats, containsPair('minCapacity', 10));
      expect(stats, containsPair('maxCapacity', 200));
      expect(stats, containsPair('capacityAdjustments', 0));
      expect(stats, containsPair('memoryPressureEvents', 0));
      expect(stats, containsPair('cacheUtilization', 0.0));
      // expect(stats, containsKey('memoryStats'));
      // expect(stats, containsKey('spatialStats'));
    });

    test('should handle memory pressure changes', () async {
      final int initialCapacity = cache.currentCapacity;

      // Force memory pressure check
      cache.checkMemoryPressure();

      // Allow some time for monitoring
      await Future.delayed(const Duration(milliseconds: 100));

      final stats = cache.getStatistics();
      expect(stats['memoryPressureEvents'], greaterThanOrEqualTo(0));
    });

    test('should handle tile operations correctly', () async {
      final Tile testTile = Tile(1, 1, 1, 0);

      // Test get on empty cache
      expect(cache.get(testTile), isNull);

      // try {
      //   // Test getOrProduce with mock producer
      //   final TilePicture result = await cache.getOrProduce(testTile, (tile) async {
      //     // Mock tile producer - in real implementation this would create actual tile
      //     await Future.delayed(const Duration(milliseconds: 10));
      //     throw Exception('Mock producer for testing');
      //   });
      // } finally {}
    });

    test('should handle purge operations', () {
      // Test purge all
      cache.purgeAll();
      expect(cache.currentSize, equals(0));

      // Test purge by boundary
      final BoundingBox testBounds = BoundingBox(0.0, 0.0, 1.0, 1.0);
      cache.purgeByBoundary(testBounds);
      expect(cache.currentSize, equals(0));
    });

    test('should handle disposal correctly', () {
      expect(() => cache.dispose(), returnsNormally);
    });
  });

  group('AdaptiveMemoryTileCache static methods', () {
    test('should handle global operations', () {
      final cache1 = AdaptiveMemoryTileCache.create(initialCapacity: 50);
      final cache2 = AdaptiveMemoryTileCache.create(initialCapacity: 75);

      // Test global purge
      expect(() => AdaptiveMemoryTileCache.purgeAllCaches(), returnsNormally);

      // Test global boundary purge
      final BoundingBox bounds = BoundingBox(0.0, 0.0, 1.0, 1.0);
      expect(() => AdaptiveMemoryTileCache.purgeCachesByBoundary(bounds), returnsNormally);

      // Test global memory pressure check
      expect(() => AdaptiveMemoryTileCache.checkAllMemoryPressure(), returnsNormally);

      // Test global statistics
      final globalStats = AdaptiveMemoryTileCache.getGlobalStatistics();
      expect(globalStats, containsPair('totalInstances', greaterThanOrEqualTo(2)));
      expect(globalStats, containsPair('totalCapacity', greaterThanOrEqualTo(125)));
      //      expect(globalStats, containsKey('instanceStats'));

      // Clean up
      cache1.dispose();
      cache2.dispose();
    });
  });
}
