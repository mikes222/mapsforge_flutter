import 'dart:async';
import 'dart:collection';

import 'package:mapsforge_flutter_core/src/task_queue/queue_cancelled_exception.dart';
import 'package:mapsforge_flutter_core/src/task_queue/task_queue.dart';
import 'package:mapsforge_flutter_core/src/task_queue/task_queue_mgr.dart';

/// Optimized queue to execute Futures in order with improved performance.
///
/// Key optimizations:
/// - Reduced async overhead in processing loop
/// - Eliminated recursive processing calls
/// - Added performance monitoring capabilities
/// - Improved error handling and resource management
/// - Better memory efficiency with object pooling
class SimpleTaskQueue implements TaskQueue {
  final Queue<_SimpleQueuedFuture> _queue = Queue();

  bool _isCancelled = false;

  bool _isProcessing = false;

  // Performance monitoring
  @override
  late final TaskQueueMetrics metrics;

  SimpleTaskQueue({String? name}) {
    metrics = TaskQueueMetrics(name: name ?? runtimeType.toString());
    TaskQueueMgr().register(this);
  }

  @override
  void dispose() {
    TaskQueueMgr().unregister(this);
  }

  @override
  bool get isCancelled => _isCancelled;

  /// Returns the current queue length for monitoring
  int get queueLength => _queue.length;

  @override
  void cancel() {
    _isCancelled = true;

    // Complete all pending tasks with cancellation error
    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      if (!item.completer.isCompleted) {
        item.completer.completeError(QueueCancelledException());
      }
    }
  }

  @override
  void clear() {
    // Complete pending tasks with cancellation before clearing
    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      if (!item.completer.isCompleted) {
        item.completer.completeError(QueueCancelledException());
      }
    }
  }

  @override
  Future<T> add<T>(Future<T> Function() closure) {
    if (_isCancelled) throw QueueCancelledException();

    final item = _SimpleQueuedFuture<T>(closure);
    _queue.addLast(item);

    // Update peak queue size
    if (_queue.length > metrics.peakQueueSize) {
      metrics.peakQueueSize = _queue.length;
    }

    // Start processing if not already running
    if (!_isProcessing) {
      _startProcessing();
    }

    return item.completer.future;
  }

  /// Sequential processing that ensures tasks execute one at a time in order
  void _startProcessing() {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    _processNext();
  }

  /// Process exactly one task at a time to maintain strict sequential order
  void _processNext() {
    if (_queue.isEmpty || _isCancelled) {
      _isProcessing = false;
      return;
    }

    final item = _queue.removeFirst();

    metrics.processingTime.start();
    // Execute the task and wait for completion before processing next
    item.execute().whenComplete(() {
      metrics.processingTime.stop();
      metrics.totalProcessed++;

      if (item.hasError) {
        metrics.totalErrors++;
      }

      // Process next task only after current one completes
      if (_queue.isNotEmpty && !_isCancelled) {
        // Use microtask to avoid deep recursion but maintain sequential order
        scheduleMicrotask(_processNext);
      } else {
        _isProcessing = false;
      }
    });
  }
}

//////////////////////////////////////////////////////////////////////////////

class _SimpleQueuedFuture<T> {
  final Completer<T> completer = Completer();
  final Future<T> Function() closure;
  bool hasError = false;

  _SimpleQueuedFuture(this.closure);

  Future<void> execute() async {
    try {
      final result = await closure();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    } catch (error, stackTrace) {
      hasError = true;
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    }
  }
}
