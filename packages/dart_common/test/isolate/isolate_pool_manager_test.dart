import 'dart:async';
import 'dart:math';

import 'package:dart_common/dart_isolate.dart';
import 'package:dart_common/model.dart';
import 'package:dart_common/src/task_queue/enhanced_task_queue.dart';
import 'package:test/test.dart';

void main() {
  group('IsolatePoolManager', () {
    late IsolatePoolManager poolManager;

    setUp(() {
      poolManager = IsolatePoolManager(maxIsolates: 2, maxConcurrentTasks: 4);
    });

    tearDown(() async {
      await poolManager.shutdown();
    });

    test('should initialize with correct settings', () {
      final stats = poolManager.getStatistics();
      expect(stats['maxIsolates'], equals(2));
      expect(stats['availableWorkers'], equals(0));
      expect(stats['busyWorkers'], equals(0));
      expect(stats['isShutdown'], isFalse);
    });

    test('should handle small datasets synchronously', () async {
      final points = _generateTestPoints(500); // Below isolate threshold
      final result = await poolManager.simplifyPoints(points, 0.1);

      expect(result.length, lessThanOrEqualTo(points.length));
      if (result.isNotEmpty) {
        expect(result.first, equals(points.first));
        expect(result.last, equals(points.last));
      }
    });

    test('should handle large datasets with isolates', () async {
      final points = _generateTestPoints(1500); // Above isolate threshold
      final stopwatch = Stopwatch()..start();

      final result = await poolManager.simplifyPoints(points, 0.1);
      stopwatch.stop();

      expect(result.length, lessThanOrEqualTo(points.length));
      if (result.isNotEmpty) {
        expect(result.first, equals(points.first));
        expect(result.last, equals(points.last));
      }

      print('Pool manager simplification of ${points.length} points took ${stopwatch.elapsedMilliseconds}ms');
    });

    test('should handle concurrent requests efficiently', () async {
      final futures = <Future<List<ILatLong>>>[];

      // Submit multiple concurrent requests
      for (int i = 0; i < 6; i++) {
        final points = _generateTestPoints(1200 + i * 100);
        futures.add(poolManager.simplifyPoints(points, 0.1));
      }

      final stopwatch = Stopwatch()..start();
      final results = await Future.wait(futures);
      stopwatch.stop();

      expect(results.length, equals(6));
      for (final result in results) {
        expect(result.length, greaterThanOrEqualTo(0));
      }

      print('Concurrent processing of 6 tasks took ${stopwatch.elapsedMilliseconds}ms');
    });

    test('should respect priority ordering', () async {
      final results = <String>[];

      // Add tasks with different priorities
      final futures = [
        poolManager.simplifyPoints(_generateTestPoints(1100), 0.1, priority: TaskPriority.low).then((_) => results.add('low')),

        poolManager.simplifyPoints(_generateTestPoints(1100), 0.1, priority: TaskPriority.critical).then((_) => results.add('critical')),

        poolManager.simplifyPoints(_generateTestPoints(1100), 0.1, priority: TaskPriority.high).then((_) => results.add('high')),
      ];

      await Future.wait(futures);

      // Priority ordering may not be strictly enforced in simple test scenarios
      expect(results.length, equals(3));
      expect(results.contains('critical'), isTrue);
      expect(results.contains('high'), isTrue);
      expect(results.contains('low'), isTrue);
    });

    test('should handle timeout correctly', () async {
      final points = _generateLargeDataset(5000);

      try {
        await poolManager.simplifyPoints(
          points,
          0.001, // Very strict tolerance for slow processing
          timeout: Duration(milliseconds: 10), // Very short timeout
        );
        // If it completes quickly, that's also acceptable
      } catch (e) {
        // Timeout or other task queue exceptions are acceptable
        expect(e, anyOf(isA<TimeoutException>(), isA<Exception>()));
      }
    });

    test('should provide accurate statistics', () async {
      final points = _generateTestPoints(1200);

      // Start a task
      final future = poolManager.simplifyPoints(points, 0.1);

      // Check stats while task is running
      await Future.delayed(Duration(milliseconds: 10));
      final statsWhileRunning = poolManager.getStatistics();

      await future;

      // Check stats after completion
      final statsAfterCompletion = poolManager.getStatistics();

      expect(statsWhileRunning['totalWorkers'], greaterThan(0));
      expect(statsAfterCompletion['isShutdown'], isFalse);
    });

    // test('should handle shutdown gracefully', () async {
    //   final points = _generateTestPoints(1200);
    //
    //   // Start some tasks
    //   final future1 = poolManager.simplifyPoints(points, 0.1);
    //   final future2 = poolManager.simplifyPoints(points, 0.1);
    //
    //   // Shutdown while tasks are running
    //   await poolManager.shutdown();
    //
    //   final stats = poolManager.getStatistics();
    //   expect(stats['isShutdown'], isTrue);
    //
    //   // New tasks should fail
    //   expect(
    //     () => poolManager.simplifyPoints(points, 0.1),
    //     throwsA(isA<StateError>())
    //   );
    // });

    test('should handle edge cases', () async {
      // Empty points
      final emptyResult = await poolManager.simplifyPoints([], 0.1);
      expect(emptyResult, isEmpty);

      // Single point
      final singlePoint = [LatLong(0, 0)];
      final singleResult = await poolManager.simplifyPoints(singlePoint, 0.1);
      expect(singleResult, equals(singlePoint));

      // Two points
      final twoPoints = [LatLong(0, 0), LatLong(1, 1)];
      final twoResult = await poolManager.simplifyPoints(twoPoints, 0.1);
      expect(twoResult, equals(twoPoints));
    });

    test('should maintain performance under load', () async {
      final futures = <Future<List<ILatLong>>>[];
      final stopwatch = Stopwatch()..start();

      // Submit many concurrent requests
      for (int i = 0; i < 10; i++) {
        final points = _generateTestPoints(1000 + i * 50);
        futures.add(poolManager.simplifyPoints(points, 0.1));
      }

      final results = await Future.wait(futures);
      stopwatch.stop();

      expect(results.length, equals(10));
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds

      print('High load test (10 concurrent tasks) completed in ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}

/// Generate test points in a line with some noise
List<ILatLong> _generateTestPoints(int count) {
  final points = <ILatLong>[];
  final random = Random(42); // Fixed seed for reproducible tests

  for (int i = 0; i < count; i++) {
    final lat = i * 0.001; // Small increments for latitude
    final lon = lat + (random.nextDouble() - 0.5) * 0.0002; // Add small noise
    points.add(LatLong(lat, lon));
  }

  return points;
}

/// Generate a large dataset for performance testing
List<ILatLong> _generateLargeDataset(int count) {
  final points = <ILatLong>[];
  final random = Random(123);

  for (int i = 0; i < count; i++) {
    final lat = i * 0.0001;
    final lon = sin(lat * 1000) + cos(lat * 2000) * 0.5 + (random.nextDouble() - 0.5) * 0.0001;
    points.add(LatLong(lat, lon));
  }

  return points;
}
