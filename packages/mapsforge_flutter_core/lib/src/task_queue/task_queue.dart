import 'dart:async';

import 'package:mapsforge_flutter_core/src/task_queue/queue_cancelled_exception.dart';

/// An abstract class that defines the interface for a queue that executes
/// `Future`-returning closures in a controlled manner.
abstract class TaskQueue {
  // Performance monitoring
  TaskQueueMetrics get metrics;

  /// Cancels the queue.
  ///
  /// Any unprocessed items will be completed with a [QueueCancelledException].
  /// Subsequent calls to [add] will also throw a [QueueCancelledException].
  void cancel();

  /// Disposes the queue and releases any associated resources.
  void dispose();

  bool get isCancelled;

  /// Removes all pending tasks from the queue.
  ///
  /// The `Future`s of these tasks will be completed with a [QueueCancelledException].
  void clear();

  /// Adds a `Future`-returning closure to the queue.
  ///
  /// The closure will be executed when its turn comes up in the queue.
  ///
  /// Throws a [QueueCancelledException] if the queue has been cancelled.
  Future<T> add<T>(Future<T> Function() closure);
}

//////////////////////////////////////////////////////////////////////////////

/// A class that holds performance metrics for a `TaskQueue`.
class TaskQueueMetrics {
  final String name;

  int peakQueueSize = 0;

  /// Returns total number of tasks processed
  int totalProcessed = 0;

  /// Returns total number of errors encountered
  int totalErrors = 0;

  final Stopwatch processingTime = Stopwatch();

  /// Returns average processing time per task in milliseconds
  double get averageProcessingTime => totalProcessed > 0 ? processingTime.elapsedMilliseconds / totalProcessed : 0.0;

  TaskQueueMetrics({required this.name});

  /// Resets all performance counters.
  void clear() {
    peakQueueSize = 0;
    totalProcessed = 0;
    totalErrors = 0;
    processingTime.reset();
  }

  @override
  String toString() {
    return '$name: peakQueueSize: $peakQueueSize, totalProcessed: $totalProcessed, totalErrors: $totalErrors, processingTime: ${processingTime.elapsedMilliseconds}ms, avg: ${averageProcessingTime.toStringAsFixed(1)}ms';
  }
}
