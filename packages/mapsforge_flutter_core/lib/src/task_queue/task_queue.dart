import 'dart:async';

import 'package:mapsforge_flutter_core/src/task_queue/queue_cancelled_exception.dart';

/// Abstract class for a queue to execute Futures in order.
abstract class TaskQueue {
  // Performance monitoring
  TaskQueueMetrics get metrics;

  /// Cancels the queue. Also cancels any unprocessed items throwing a [QueueCancelledException]
  /// Subsquent calls to [add] will throw a [QueueCancelledException].
  void cancel();

  void dispose();

  bool get isCancelled;

  /// Removes all unstarted jobs from the queue. The future of these jobs will never return.
  void clear();

  /// Adds the future-returning closure to the queue.
  ///
  /// It will be executed after futures returned
  /// by preceding closures have been awaited.
  ///
  /// Will throw an exception if the queue has been cancelled.
  Future<T> add<T>(Future<T> Function() closure);
}

//////////////////////////////////////////////////////////////////////////////

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

  /// Reset performance counters
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
