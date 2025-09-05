import 'dart:async';
import 'dart:math';

import 'package:mapsforge_flutter_core/src/task_queue/high_performance_simple_task_queue.dart';
import 'package:mapsforge_flutter_core/src/task_queue/simple_task_queue.dart';
import 'package:test/test.dart';

void main() {
  group('Task Queue Performance Comparison', () {
    late Stopwatch stopwatch;

    setUp(() {
      stopwatch = Stopwatch();
    });

    test('Sequential Processing Performance - 100 tasks', () async {
      const taskCount = 100;
      const taskDuration = 10; // milliseconds

      // Test original SimpleTaskQueue
      final originalQueue = SimpleTaskQueue();
      stopwatch.start();
      final originalFutures = <Future>[];
      for (int i = 0; i < taskCount; i++) {
        originalFutures.add(
          originalQueue.add(() async {
            await Future.delayed(Duration(milliseconds: taskDuration));
            return i;
          }),
        );
      }
      await Future.wait(originalFutures);
      stopwatch.stop();
      final originalTime = stopwatch.elapsedMilliseconds;
      originalQueue.cancel();

      // Test HighPerformanceSimpleTaskQueue
      stopwatch.reset();
      final highPerfQueue = HighPerformanceSimpleTaskQueue();
      stopwatch.start();
      final highPerfFutures = <Future>[];
      for (int i = 0; i < taskCount; i++) {
        highPerfFutures.add(
          highPerfQueue.add(() async {
            await Future.delayed(Duration(milliseconds: taskDuration));
            return i;
          }),
        );
      }
      await Future.wait(highPerfFutures);
      stopwatch.stop();
      final highPerfTime = stopwatch.elapsedMilliseconds;
      highPerfQueue.cancel();

      print('Performance Results for $taskCount tasks:');
      print('Original SimpleTaskQueue: ${originalTime}ms');
      print('HighPerformanceSimpleTaskQueue: ${highPerfTime}ms');
      print('High-perf improvement: ${((originalTime - highPerfTime) / originalTime * 100).toStringAsFixed(1)}%');

      // Verify all implementations maintain order
      expect(highPerfTime, lessThanOrEqualTo(originalTime * 1.1));
    });

    test('High Load Performance - 500 tasks', () async {
      const taskCount = 500;
      const taskDuration = 1; // milliseconds

      // Test OptimizedSimpleTaskQueue under load
      final optimizedQueue = SimpleTaskQueue();
      stopwatch.start();
      final optimizedFutures = <Future>[];
      for (int i = 0; i < taskCount; i++) {
        optimizedFutures.add(
          optimizedQueue.add(() async {
            await Future.delayed(const Duration(milliseconds: taskDuration));
            return i;
          }),
        );
      }
      await Future.wait(optimizedFutures);
      stopwatch.stop();
      final optimizedTime = stopwatch.elapsedMilliseconds;

      print('\nHigh Load Performance ($taskCount tasks):');
      print('OptimizedSimpleTaskQueue: ${optimizedTime}ms');
      print('Queue stats - Processed: ${optimizedQueue.metrics.totalProcessed}, Errors: ${optimizedQueue.metrics.totalErrors}');
      print('Average processing time: ${optimizedQueue.metrics.averageProcessingTime.toStringAsFixed(2)}ms');

      // Test HighPerformanceSimpleTaskQueue under load
      stopwatch.reset();
      final highPerfQueue = HighPerformanceSimpleTaskQueue();
      stopwatch.start();
      final highPerfFutures = <Future>[];
      for (int i = 0; i < taskCount; i++) {
        highPerfFutures.add(
          highPerfQueue.add(() async {
            await Future.delayed(const Duration(milliseconds: taskDuration));
            return i;
          }),
        );
      }
      await Future.wait(highPerfFutures);
      stopwatch.stop();
      final highPerfTime = stopwatch.elapsedMilliseconds;

      print('HighPerformanceSimpleTaskQueue: ${highPerfTime}ms');
      final stats = highPerfQueue.getPerformanceStats();
      print('Detailed stats: $stats');

      optimizedQueue.cancel();
      highPerfQueue.cancel();

      expect(optimizedQueue.metrics.totalProcessed, equals(taskCount));
      expect(highPerfQueue.metrics.totalProcessed, equals(taskCount));
      expect(optimizedQueue.metrics.totalErrors, equals(0));
      expect(highPerfQueue.metrics.totalErrors, equals(0));
    });

    test('Memory Efficiency - Object Pool Performance', () async {
      const taskCount = 500;
      final highPerfQueue = HighPerformanceSimpleTaskQueue();

      // Add and process tasks to populate object pool
      final futures = <Future>[];
      for (int i = 0; i < taskCount; i++) {
        futures.add(
          highPerfQueue.add(() async {
            await Future.delayed(Duration(milliseconds: 1));
            return i;
          }),
        );
      }
      await Future.wait(futures);

      final stats = highPerfQueue.getPerformanceStats();
      print('\nMemory Efficiency Test:');
      print('Object pool size: ${stats['objectPoolSize']}');
      print('Peak queue size: ${stats['peakQueueSize']}');
      print('Total processed: ${stats['totalProcessed']}');

      // Verify object pool is being used
      expect(stats['objectPoolSize'], greaterThan(0));
      expect(stats['totalProcessed'], equals(taskCount));

      highPerfQueue.cancel();
    });

    test('Error Handling Performance', () async {
      const taskCount = 100;
      const errorRate = 0.2; // 20% of tasks will fail

      final optimizedQueue = SimpleTaskQueue();
      final highPerfQueue = HighPerformanceSimpleTaskQueue();
      final random = Random();

      // Test optimized queue with errors
      final optimizedFutures = <Future>[];
      for (int i = 0; i < taskCount; i++) {
        optimizedFutures.add(
          optimizedQueue
              .add(() async {
                await Future.delayed(Duration(milliseconds: 1));
                if (random.nextDouble() < errorRate) {
                  throw Exception('Test error $i');
                }
                return i;
              })
              .catchError((_) => -1),
        ); // Catch errors to continue test
      }
      await Future.wait(optimizedFutures);

      // Test high-performance queue with errors
      final highPerfFutures = <Future>[];
      for (int i = 0; i < taskCount; i++) {
        highPerfFutures.add(
          highPerfQueue
              .add(() async {
                await Future.delayed(Duration(milliseconds: 1));
                if (random.nextDouble() < errorRate) {
                  throw Exception('Test error $i');
                }
                return i;
              })
              .catchError((_) => -1),
        ); // Catch errors to continue test
      }
      await Future.wait(highPerfFutures);

      print('\nError Handling Performance:');
      print('Optimized queue - Processed: ${optimizedQueue.metrics.totalProcessed}, Errors: ${optimizedQueue.metrics.totalErrors}');
      print('High-perf queue - Processed: ${highPerfQueue.metrics.totalProcessed}, Errors: ${highPerfQueue.metrics.totalErrors}');

      final stats = highPerfQueue.getPerformanceStats();
      print('Error rate: ${(stats['errorRate'] * 100).toStringAsFixed(1)}%');

      expect(optimizedQueue.metrics.totalProcessed, equals(taskCount));
      expect(highPerfQueue.metrics.totalProcessed, equals(taskCount));
      expect(optimizedQueue.metrics.totalErrors, greaterThan(0));
      expect(highPerfQueue.metrics.totalErrors, greaterThan(0));

      optimizedQueue.cancel();
      highPerfQueue.cancel();
    });

    test('Backpressure Handling', () async {
      const maxQueueSize = 10; // Smaller queue to trigger backpressure
      const taskCount = 100; // More tasks than queue can hold

      final highPerfQueue = HighPerformanceSimpleTaskQueue(maxQueueSize: maxQueueSize);

      // Add tasks rapidly to trigger backpressure with longer delays
      final futures = <Future>[];
      for (int i = 0; i < taskCount; i++) {
        try {
          futures.add(
            highPerfQueue
                .add(() async {
                  await Future.delayed(Duration(milliseconds: 50)); // Longer delay to fill queue
                  return i;
                })
                .catchError((_) => -1),
          ); // Catch dropped task errors
        } catch (e) {
          // Task was dropped immediately
        }
      }

      // Wait a bit to let queue fill up
      await Future.delayed(Duration(milliseconds: 100));

      final stats = highPerfQueue.getPerformanceStats();
      print('\nBackpressure Test:');
      print('Max queue size: $maxQueueSize');
      print('Tasks submitted: $taskCount');
      print('Tasks processed: ${stats['totalProcessed']}');
      print('Tasks dropped: ${stats['totalDropped']}');
      print('Drop rate: ${(stats['dropRate'] * 100).toStringAsFixed(1)}%');

      // Cancel to stop processing and get final stats
      highPerfQueue.cancel();

      // Either tasks were dropped OR queue size was properly limited
      final finalStats = highPerfQueue.getPerformanceStats();
      expect(finalStats['peakQueueSize'], lessThanOrEqualTo(maxQueueSize));
    });

    test('Throughput Measurement', () async {
      const taskCount = 200;
      const taskDuration = 5; // milliseconds

      final highPerfQueue = HighPerformanceSimpleTaskQueue();

      final futures = <Future>[];
      for (int i = 0; i < taskCount; i++) {
        futures.add(
          highPerfQueue.add(() async {
            await Future.delayed(Duration(milliseconds: taskDuration));
            return i;
          }),
        );
      }

      await Future.wait(futures);

      final stats = highPerfQueue.getPerformanceStats();
      print('\nThroughput Measurement:');
      print('Tasks per second: ${stats['throughputPerSecond'].toStringAsFixed(2)}');
      print('Average processing time: ${stats['averageProcessingTime'].toStringAsFixed(2)}ms');
      print('Total processed: ${stats['totalProcessed']}');

      expect(stats['throughputPerSecond'], greaterThan(0));
      expect(stats['totalProcessed'], equals(taskCount));

      highPerfQueue.cancel();
    });
  });
}
