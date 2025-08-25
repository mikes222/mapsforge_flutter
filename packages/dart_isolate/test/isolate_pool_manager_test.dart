import 'dart:math';
import 'dart:async';
import 'package:test/test.dart';
import 'package:dart_common/model.dart';
import 'package:dart_isolate/dart_isolate.dart';
import 'package:task_queue/task_queue.dart';

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
      
      expect(result.length, lessThan(points.length));
      expect(result.first, equals(points.first));
      expect(result.last, equals(points.last));
    });

    test('should handle large datasets with isolates', () async {
      final points = _generateTestPoints(1500); // Above isolate threshold
      final stopwatch = Stopwatch()..start();
      
      final result = await poolManager.simplifyPoints(points, 0.1);
      stopwatch.stop();
      
      expect(result.length, lessThan(points.length));
      expect(result.first, equals(points.first));
      expect(result.last, equals(points.last));
      
      print('Pool manager simplification of ${points.length} points took ${stopwatch.elapsedMilliseconds}ms');
    });

    test('should handle concurrent requests efficiently', () async {
      final futures = <Future<List<Mappoint>>>[];
      
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
        expect(result.length, greaterThan(0));
      }
      
      print('Concurrent processing of 6 tasks took ${stopwatch.elapsedMilliseconds}ms');
    });

    test('should respect priority ordering', () async {
      final results = <String>[];
      
      // Add tasks with different priorities
      final futures = [
        poolManager.simplifyPoints(
          _generateTestPoints(1100), 
          0.1, 
          priority: TaskPriority.low
        ).then((_) => results.add('low')),
        
        poolManager.simplifyPoints(
          _generateTestPoints(1100), 
          0.1, 
          priority: TaskPriority.critical
        ).then((_) => results.add('critical')),
        
        poolManager.simplifyPoints(
          _generateTestPoints(1100), 
          0.1, 
          priority: TaskPriority.high
        ).then((_) => results.add('high')),
      ];
      
      await Future.wait(futures);
      
      // Critical should execute before high, high before low
      expect(results.first, equals('critical'));
    });

    test('should handle timeout correctly', () async {
      final points = _generateLargeDataset(5000);
      
      try {
        await poolManager.simplifyPoints(
          points, 
          0.001, // Very strict tolerance for slow processing
          timeout: Duration(milliseconds: 50)
        );
        fail('Should have timed out');
      } catch (e) {
        expect(e, isA<TimeoutException>());
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

    test('should handle shutdown gracefully', () async {
      final points = _generateTestPoints(1200);
      
      // Start some tasks
      final future1 = poolManager.simplifyPoints(points, 0.1);
      final future2 = poolManager.simplifyPoints(points, 0.1);
      
      // Shutdown while tasks are running
      await poolManager.shutdown();
      
      final stats = poolManager.getStatistics();
      expect(stats['isShutdown'], isTrue);
      
      // New tasks should fail
      expect(
        () => poolManager.simplifyPoints(points, 0.1),
        throwsA(isA<StateError>())
      );
    });

    test('should handle edge cases', () async {
      // Empty points
      final emptyResult = await poolManager.simplifyPoints([], 0.1);
      expect(emptyResult, isEmpty);
      
      // Single point
      final singlePoint = [Mappoint(0, 0)];
      final singleResult = await poolManager.simplifyPoints(singlePoint, 0.1);
      expect(singleResult, equals(singlePoint));
      
      // Two points
      final twoPoints = [Mappoint(0, 0), Mappoint(1, 1)];
      final twoResult = await poolManager.simplifyPoints(twoPoints, 0.1);
      expect(twoResult, equals(twoPoints));
    });

    test('should maintain performance under load', () async {
      final futures = <Future<List<Mappoint>>>[];
      final stopwatch = Stopwatch()..start();
      
      // Submit many concurrent requests
      for (int i = 0; i < 10; i++) {
        final points = _generateTestPoints(1000 + i * 50);
        futures.add(poolManager.simplifyPoints(points, 0.1));
      }
      
      final results = await Future.wait(futures);
      stopwatch.stop();
      
      expect(results.length, equals(10));
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
      
      print('High load test (10 concurrent tasks) completed in ${stopwatch.elapsedMilliseconds}ms');
    });
  });
}

/// Generate test points in a line with some noise
List<Mappoint> _generateTestPoints(int count) {
  final points = <Mappoint>[];
  final random = Random(42); // Fixed seed for reproducible tests
  
  for (int i = 0; i < count; i++) {
    final x = i.toDouble();
    final y = x + (random.nextDouble() - 0.5) * 0.2; // Add small noise
    points.add(Mappoint(x, y));
  }
  
  return points;
}

/// Generate a large dataset for performance testing
List<Mappoint> _generateLargeDataset(int count) {
  final points = <Mappoint>[];
  final random = Random(123);
  
  for (int i = 0; i < count; i++) {
    final x = i * 0.1;
    final y = sin(x) + cos(x * 2) * 0.5 + (random.nextDouble() - 0.5) * 0.1;
    points.add(Mappoint(x, y));
  }
  
  return points;
}
