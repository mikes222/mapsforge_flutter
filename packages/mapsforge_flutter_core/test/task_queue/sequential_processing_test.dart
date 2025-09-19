import 'dart:async';

import 'package:mapsforge_flutter_core/src/task_queue/high_performance_simple_task_queue.dart';
import 'package:mapsforge_flutter_core/src/task_queue/simple_task_queue.dart';
import 'package:test/test.dart';

void main() {
  group('Sequential Processing Verification', () {
    test('OptimizedSimpleTaskQueue maintains sequential order', () async {
      final queue = SimpleTaskQueue();
      final results = <int>[];
      final futures = <Future>[];

      // Add tasks that record their execution order
      for (int i = 0; i < 10; i++) {
        futures.add(
          queue.add(() async {
            await Future.delayed(const Duration(milliseconds: 10));
            results.add(i);
            return i;
          }),
        );
      }

      await Future.wait(futures);
      queue.cancel();

      // Verify tasks executed in order
      expect(results, equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));

      // Verify statistics were collected
      expect(queue.metrics.totalProcessed, equals(10));
      expect(queue.metrics.totalErrors, equals(0));
      expect(queue.queueLength, equals(0));
    });

    test('HighPerformanceSimpleTaskQueue maintains sequential order', () async {
      final queue = HighPerformanceSimpleTaskQueue();
      final results = <int>[];
      final futures = <Future>[];

      // Add tasks that record their execution order
      for (int i = 0; i < 10; i++) {
        futures.add(
          queue.add(() async {
            await Future.delayed(Duration(milliseconds: 10));
            results.add(i);
            return i;
          }),
        );
      }

      await Future.wait(futures);
      queue.cancel();

      // Verify tasks executed in order
      expect(results, equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]));

      // Verify comprehensive statistics were collected
      final stats = queue.getPerformanceStats();
      expect(stats['totalProcessed'], equals(10));
      expect(stats['totalErrors'], equals(0));
      expect(stats['queueLength'], equals(0));
      expect(stats['throughputPerSecond'], greaterThan(0));
    });

    test('Sequential processing with overlapping async operations', () async {
      final queue = SimpleTaskQueue();
      final executionOrder = <String>[];
      final futures = <Future>[];

      // Add tasks with different durations to test sequential execution
      futures.add(
        queue.add(() async {
          executionOrder.add('task1_start');
          await Future.delayed(Duration(milliseconds: 50));
          executionOrder.add('task1_end');
          return 1;
        }),
      );

      futures.add(
        queue.add(() async {
          executionOrder.add('task2_start');
          await Future.delayed(Duration(milliseconds: 20));
          executionOrder.add('task2_end');
          return 2;
        }),
      );

      futures.add(
        queue.add(() async {
          executionOrder.add('task3_start');
          await Future.delayed(Duration(milliseconds: 30));
          executionOrder.add('task3_end');
          return 3;
        }),
      );

      await Future.wait(futures);
      queue.cancel();

      // Verify tasks started and completed in order (no overlap)
      expect(executionOrder, equals(['task1_start', 'task1_end', 'task2_start', 'task2_end', 'task3_start', 'task3_end']));
    });

    test('Sequential processing with error handling', () async {
      final queue = SimpleTaskQueue();
      final results = <String>[];
      final futures = <Future>[];

      // Add tasks where some fail
      futures.add(
        queue.add(() async {
          await Future.delayed(Duration(milliseconds: 10));
          results.add('task1_success');
          return 1;
        }),
      );

      futures.add(
        queue
            .add(() async {
              await Future.delayed(Duration(milliseconds: 10));
              results.add('task2_before_error');
              throw Exception('Test error');
            })
            .then(
              (value) => value,
              onError: (error) {
                results.add('task2_error_caught');
                return -1;
              },
            ),
      );

      futures.add(
        queue.add(() async {
          await Future.delayed(Duration(milliseconds: 10));
          results.add('task3_success');
          return 3;
        }),
      );

      await Future.wait(futures);
      queue.cancel();

      // Verify execution order maintained even with errors
      expect(results, equals(['task1_success', 'task2_before_error', 'task2_error_caught', 'task3_success']));

      // Verify error statistics
      expect(queue.metrics.totalProcessed, equals(3));
      expect(queue.metrics.totalErrors, equals(1));
    });

    test('High load sequential processing verification', () async {
      final queue = HighPerformanceSimpleTaskQueue();
      final results = <int>[];
      final futures = <Future>[];
      const taskCount = 100;

      // Add many tasks to verify sequential order under load
      for (int i = 0; i < taskCount; i++) {
        futures.add(
          queue.add(() async {
            await Future.delayed(Duration(milliseconds: 1));
            results.add(i);
            return i;
          }),
        );
      }

      await Future.wait(futures);
      queue.cancel();

      // Verify all tasks executed in correct order
      final expectedResults = List.generate(taskCount, (i) => i);
      expect(results, equals(expectedResults));

      // Verify comprehensive statistics
      final stats = queue.getPerformanceStats();
      expect(stats['totalProcessed'], equals(taskCount));
      expect(stats['totalErrors'], equals(0));
      expect(stats['objectPoolSize'], greaterThan(0)); // Object pool was used
    });

    test('Statistics accuracy during sequential processing', () async {
      final queue = SimpleTaskQueue();
      final futures = <Future>[];

      // Add tasks with known durations
      for (int i = 0; i < 5; i++) {
        futures.add(
          queue.add(() async {
            await Future.delayed(Duration(milliseconds: 20));
            return i;
          }),
        );
      }

      await Future.wait(futures);

      // Verify statistics are accurate
      expect(queue.metrics.totalProcessed, equals(5));
      expect(queue.metrics.totalErrors, equals(0));
      expect(queue.queueLength, equals(0));
      // Note: averageProcessingTime might be 0 due to timing precision

      queue.cancel();
    });
  });
}
