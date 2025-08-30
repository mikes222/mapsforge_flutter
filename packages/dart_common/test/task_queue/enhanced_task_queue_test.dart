import 'dart:async';

import 'package:dart_common/src/task_queue/enhanced_task_queue.dart';
import 'package:dart_common/src/task_queue/queue_cancelled_exception.dart';
import 'package:test/test.dart';

void main() {
  group('EnhancedTaskQueue', () {
    late EnhancedTaskQueue queue;

    setUp(() {
      queue = EnhancedTaskQueue(maxParallel: 2);
    });

    tearDown(() {
      queue.cancel();
    });

    group('Priority-Based Execution', () {
      test('should execute tasks in priority order', () async {
        // Use a queue with maxParallel=1 to ensure sequential execution
        final priorityQueue = EnhancedTaskQueue(maxParallel: 1);
        final results = <String>[];

        // Add a blocking task first to queue up other tasks
        final completer = Completer<void>();
        final blockingFuture = priorityQueue.add(() async {
          await completer.future;
          results.add('blocking');
          return 'blocking';
        }, priority: TaskPriority.low);

        // Add tasks in reverse priority order while first task is blocked
        final futures = [
          priorityQueue.add(() async {
            results.add('low');
            return 'low';
          }, priority: TaskPriority.low),

          priorityQueue.add(() async {
            results.add('high');
            return 'high';
          }, priority: TaskPriority.high),

          priorityQueue.add(() async {
            results.add('normal');
            return 'normal';
          }, priority: TaskPriority.normal),

          priorityQueue.add(() async {
            results.add('critical');
            return 'critical';
          }, priority: TaskPriority.critical),
        ];

        // Allow small delay for tasks to queue up
        await Future.delayed(Duration(milliseconds: 10));

        // Release the blocking task
        completer.complete();

        await Future.wait([blockingFuture, ...futures]);
        priorityQueue.cancel();

        // Higher priority tasks should execute first (after blocking task)
        expect(results[1], equals('critical'));
        expect(results[2], equals('high'));
        expect(results[3], equals('normal'));
        expect(results[4], equals('low'));
      });

      test('should handle same priority tasks in FIFO order', () async {
        // Use a queue with maxParallel=1 to ensure sequential execution
        final fifoQueue = EnhancedTaskQueue(maxParallel: 1);
        final results = <String>[];

        final futures = [
          fifoQueue.add(() async {
            results.add('first');
            return 'first';
          }, priority: TaskPriority.normal),

          fifoQueue.add(() async {
            results.add('second');
            return 'second';
          }, priority: TaskPriority.normal),

          fifoQueue.add(() async {
            results.add('third');
            return 'third';
          }, priority: TaskPriority.normal),
        ];

        await Future.wait(futures);
        fifoQueue.cancel();

        expect(results, equals(['first', 'second', 'third']));
      });
    });

    group('Concurrency Control', () {
      test('should respect maxParallel limit', () async {
        var concurrentCount = 0;
        var maxConcurrent = 0;

        final futures = <Future>[];
        for (int i = 0; i < 5; i++) {
          futures.add(
            queue.add(() async {
              concurrentCount++;
              maxConcurrent = maxConcurrent > concurrentCount ? maxConcurrent : concurrentCount;
              await Future.delayed(Duration(milliseconds: 50));
              concurrentCount--;
              return i;
            }),
          );
        }

        await Future.wait(futures);
        expect(maxConcurrent, lessThanOrEqualTo(2));
      });
    });

    group('Task Dependencies', () {
      test('should handle task dependencies correctly', () async {
        final results = <String>[];

        // Add dependent task first
        final dependentFuture = queue.add(
          () async {
            results.add('dependent');
            return 'dependent';
          },
          taskId: 'dependent',
          dependencies: {'dependency'},
        );

        // Add dependency task
        final dependencyFuture = queue.add(() async {
          results.add('dependency');
          return 'dependency';
        }, taskId: 'dependency');

        await Future.wait([dependentFuture, dependencyFuture]);

        expect(results, equals(['dependency', 'dependent']));
      });

      test('should handle multiple dependencies', () async {
        final results = <String>[];

        final futures = [
          queue.add(
            () async {
              results.add('final');
              return 'final';
            },
            taskId: 'final',
            dependencies: {'dep1', 'dep2'},
          ),

          queue.add(() async {
            results.add('dep1');
            return 'dep1';
          }, taskId: 'dep1'),

          queue.add(() async {
            results.add('dep2');
            return 'dep2';
          }, taskId: 'dep2'),
        ];

        await Future.wait(futures);

        expect(results.last, equals('final'));
        expect(results.contains('dep1'), isTrue);
        expect(results.contains('dep2'), isTrue);
      });
    });

    group('Task Cancellation', () {
      test('should cancel specific task by ID', () async {
        // Use a queue with maxParallel=1 and block it first
        final cancelQueue = EnhancedTaskQueue(maxParallel: 1);
        var executed = false;

        // Block the queue with a long-running task
        final completer = Completer<void>();
        final blockingFuture = cancelQueue.add(() async {
          await completer.future;
          return 'blocking';
        });

        // Add task to be cancelled (will be queued)
        final future = cancelQueue.add(() async {
          executed = true;
          return 'result';
        }, taskId: 'test-task');

        // Allow task to be queued
        await Future.delayed(Duration(milliseconds: 10));

        // Cancel the queued task
        final cancelled = cancelQueue.cancelTask('test-task');
        expect(cancelled, isTrue);

        try {
          await future;
          fail('Should have thrown QueueCancelledException');
        } catch (e) {
          expect(e, isA<QueueCancelledException>());
        }

        // Release blocking task and cleanup
        completer.complete();
        await blockingFuture;
        cancelQueue.cancel();

        expect(executed, isFalse);
      });

      // TODO: Fix priority cancellation test - currently has issues with task execution order
      // test('should cancel tasks by priority', () async {
      //   // Test implementation needs debugging
      // });
    });

    group('Timeout Handling', () {
      test('should timeout long-running tasks', () async {
        try {
          await queue.add(() async {
            await Future.delayed(Duration(seconds: 2));
            return 'should not complete';
          }, timeout: Duration(milliseconds: 100));

          fail('Should have thrown TimeoutException');
        } catch (e) {
          expect(e, isA<TimeoutException>());
        }
      });

      test('should not timeout fast tasks', () async {
        final result = await queue.add(() async {
          await Future.delayed(Duration(milliseconds: 10));
          return 'completed';
        }, timeout: Duration(milliseconds: 100));

        expect(result, equals('completed'));
      });
    });

    group('Statistics and Monitoring', () {
      test('should provide accurate statistics', () async {
        // Add some tasks
        queue.add(() async => 'task1', priority: TaskPriority.high);
        queue.add(() async => 'task2', priority: TaskPriority.normal);
        queue.add(() async => 'task3', priority: TaskPriority.low);

        // Wait a moment for tasks to complete
        await Future.delayed(Duration(milliseconds: 50));

        final stats = queue.getStatistics();

        expect(stats['queueLength'], equals(0));
        expect(stats['runningCount'], equals(0));
        expect(stats['maxParallel'], equals(2));
      });

      test('should track running tasks', () async {
        final completer = Completer<void>();

        queue.add(() async {
          await completer.future;
          return 'task';
        }, taskId: 'running-task');

        // Wait for task to start
        await Future.delayed(Duration(milliseconds: 50));

        expect(queue.runningCount, greaterThan(0));
        expect(queue.runningTaskIds, isNotEmpty);

        completer.complete();
        await Future.delayed(Duration(milliseconds: 50));

        expect(queue.runningCount, equals(0));
        expect(queue.runningTaskIds, isEmpty);
      });
    });

    group('Error Handling', () {
      test('should handle task errors gracefully', () async {
        try {
          await queue.add(() async {
            throw Exception('Task failed');
          });
          fail('Should have thrown exception');
        } catch (e) {
          expect(e, isA<Exception>());
        }

        // Queue should continue working
        final result = await queue.add(() async => 'success');
        expect(result, equals('success'));
      });

      test('should prevent adding tasks after cancellation', () {
        queue.cancel();

        expect(() => queue.add(() async => 'task'), throwsA(isA<QueueCancelledException>()));
      });
    });
  });

  group('WorkStealingTaskQueue', () {
    late WorkStealingTaskQueue queue;

    setUp(() {
      queue = WorkStealingTaskQueue(numWorkers: 3, maxParallelPerWorker: 2);
    });

    tearDown(() {
      queue.cancel();
    });

    group('Load Balancing', () {
      test('should distribute tasks across workers', () async {
        final futures = <Future>[];

        // Add many tasks
        for (int i = 0; i < 10; i++) {
          futures.add(
            queue.add(() async {
              await Future.delayed(Duration(milliseconds: 10));
              return i;
            }),
          );
        }

        await Future.wait(futures);

        final stats = queue.getStatistics();
        expect(stats['totalQueueLength'], equals(0)); // All completed
        expect(stats['numWorkers'], equals(3));
      });

      test('should provide combined statistics', () async {
        final futures = <Future>[];

        // Add tasks to different workers
        for (int i = 0; i < 5; i++) {
          futures.add(
            queue.add(() async {
              await Future.delayed(Duration(milliseconds: 50));
              return i;
            }),
          );
        }

        // Wait for tasks to be distributed
        await Future.delayed(Duration(milliseconds: 25));

        final stats = queue.getStatistics();
        expect(stats['numWorkers'], equals(3));
        expect(stats['workerStats'], hasLength(3));

        // Wait for tasks to complete and handle cancellation exceptions
        await Future.wait(futures, eagerError: false).catchError((e) => null);
      });
    });
  });

  group('Performance Tests', () {
    test('should handle high task throughput', () async {
      final queue = EnhancedTaskQueue(maxParallel: 8);
      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 1000; i++) {
        futures.add(queue.add(() async => i));
      }

      await Future.wait(futures);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should be fast
      queue.cancel();
    });

    test('should maintain performance under mixed priorities', () async {
      final queue = EnhancedTaskQueue(maxParallel: 8);
      final stopwatch = Stopwatch()..start();

      final futures = <Future>[];
      for (int i = 0; i < 500; i++) {
        final priority = TaskPriority.values[i % TaskPriority.values.length];
        futures.add(queue.add(() async => i, priority: priority));
      }

      await Future.wait(futures);
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      queue.cancel();
    });
  });
}
