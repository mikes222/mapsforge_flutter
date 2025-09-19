import 'dart:async';
import 'dart:collection';

import 'package:mapsforge_flutter_core/src/task_queue/queue_cancelled_exception.dart';
import 'package:mapsforge_flutter_core/src/task_queue/task_queue.dart';

/// Queue to execute Futures in order.
class ParallelTaskQueue implements TaskQueue {
  final Queue<_QueuedFuture> _nextCycle = Queue();

  // Performance monitoring
  @override
  late final TaskQueueMetrics metrics;

  bool _isCancelled = false;

  @override
  bool get isCancelled => _isCancelled;

  int _runningCount = 0;

  final int maxParallel;

  ParallelTaskQueue(this.maxParallel, {String? name}) {
    metrics = TaskQueueMetrics(name: name ?? runtimeType.toString());
  }

  @override
  void dispose() {}

  @override
  void cancel() {
    for (final item in _nextCycle) {
      item.completer.completeError(QueueCancelledException());
    }
    _nextCycle.clear();
    _isCancelled = true;
  }

  @override
  void clear() {
    _nextCycle.clear();
  }

  @override
  Future<T> add<T>(Future<T> Function() closure) {
    if (_isCancelled) throw QueueCancelledException();
    final item = _QueuedFuture<T>(closure);
    _nextCycle.addLast(item);
    unawaited(_process());
    return item.completer.future;
  }

  /// Handles the number of parallel tasks firing at any one time
  ///
  /// It does this by checking how many streams are running by querying active
  /// items, and then if it has less than the number of parallel operations fire off another stream.
  ///
  /// When each item completes it will only fire up one othe process
  ///
  Future<void> _process() async {
    if (_runningCount >= maxParallel || _nextCycle.isEmpty) {
      return;
    }
    final item = _nextCycle.removeFirst();
    ++_runningCount;
    item.execute().whenComplete(() {
      --_runningCount;
      unawaited(_process());
    });
  }
}

//////////////////////////////////////////////////////////////////////////////

class _QueuedFuture<T> {
  final Completer<T> completer = Completer();

  final Future<T> Function() closure;

  _QueuedFuture(this.closure);

  Future<void> execute() async {
    try {
      T result = await closure();
      completer.complete(result);
    } catch (error, stacktrace) {
      completer.completeError(error, stacktrace);
    }
  }
}
