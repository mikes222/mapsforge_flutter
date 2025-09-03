import 'dart:async';

import 'package:mapsforge_flutter_core/src/task_queue/queue_cancelled_exception.dart';

/// Abstract class for a queue to execute Futures in order.
abstract class TaskQueue {
  /// Cancels the queue. Also cancels any unprocessed items throwing a [QueueCancelledException]
  /// Subsquent calls to [add] will throw a [QueueCancelledException].
  void cancel();

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
