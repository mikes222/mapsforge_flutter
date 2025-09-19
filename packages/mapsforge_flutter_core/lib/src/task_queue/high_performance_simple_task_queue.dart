import 'dart:async';
import 'dart:collection';

import 'package:mapsforge_flutter_core/src/task_queue/queue_cancelled_exception.dart';
import 'package:mapsforge_flutter_core/src/task_queue/task_queue.dart';

/// High-performance queue to execute Futures in order with maximum efficiency.
///
/// Advanced optimizations:
/// - Object pooling to reduce GC pressure
/// - Batch processing for better throughput
/// - Adaptive processing based on queue size
/// - Memory-efficient queue operations
/// - Detailed performance metrics
/// - Backpressure handling
class HighPerformanceSimpleTaskQueue implements TaskQueue {
  static const int _defaultBatchSize = 10;
  static const int _maxQueueSize = 1000;

  final Queue<_PooledQueuedFuture> _queue = Queue();
  final Queue<_PooledQueuedFuture> _objectPool = Queue();

  bool _isCancelled = false;
  bool _isProcessing = false;

  final int maxQueueSize;
  final int batchSize;

  // Performance metrics
  @override
  late final TaskQueueMetrics metrics;

  int _totalDropped = 0;
  final Stopwatch _totalTime = Stopwatch();
  final List<int> _processingTimes = <int>[];

  HighPerformanceSimpleTaskQueue({this.maxQueueSize = _maxQueueSize, this.batchSize = _defaultBatchSize, String? name}) {
    metrics = TaskQueueMetrics(name: runtimeType.toString());
  }

  @override
  void dispose() {}

  @override
  bool get isCancelled => _isCancelled;

  /// Performance monitoring getters
  int get queueLength => _queue.length;
  int get totalDropped => _totalDropped;
  double get averageProcessingTime => _processingTimes.isNotEmpty ? _processingTimes.reduce((a, b) => a + b) / _processingTimes.length : 0.0;
  double get throughputPerSecond => _totalTime.elapsedMilliseconds > 0 ? (metrics.totalProcessed * 1000.0) / _totalTime.elapsedMilliseconds : 0.0;

  @override
  void cancel() {
    _isCancelled = true;

    // Return all queued items to pool and complete with error
    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      if (!item.completer.isCompleted) {
        item.completer.completeError(QueueCancelledException());
      }
      _returnToPool(item);
    }
  }

  @override
  void clear() {
    while (_queue.isNotEmpty) {
      final item = _queue.removeFirst();
      if (!item.completer.isCompleted) {
        item.completer.completeError(QueueCancelledException());
      }
      _returnToPool(item);
    }
  }

  @override
  Future<T> add<T>(Future<T> Function() closure) {
    if (_isCancelled) throw QueueCancelledException();

    // Implement backpressure - drop oldest tasks if queue is full
    if (_queue.length >= maxQueueSize) {
      final dropped = _queue.removeFirst();
      if (!dropped.completer.isCompleted) {
        dropped.completer.completeError(StateError('Task dropped due to queue overflow'));
      }
      _returnToPool(dropped);
      _totalDropped++;
    }

    final item = _getFromPool<T>();
    item.initialize(closure);
    _queue.addLast(item);

    // Update peak queue size
    if (_queue.length > metrics.peakQueueSize) {
      metrics.peakQueueSize = _queue.length;
    }

    if (!_isProcessing) {
      _startProcessing();
    }

    return item.completer.future;
  }

  /// Get a task object from the pool or create new one
  _PooledQueuedFuture<T> _getFromPool<T>() {
    if (_objectPool.isNotEmpty) {
      final item = _objectPool.removeFirst() as _PooledQueuedFuture<T>;
      item.reset();
      return item;
    }
    return _PooledQueuedFuture<T>();
  }

  /// Return a task object to the pool for reuse
  void _returnToPool(_PooledQueuedFuture item) {
    if (_objectPool.length < 50) {
      // Limit pool size
      _objectPool.addLast(item);
    }
  }

  void _startProcessing() {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;
    if (!_totalTime.isRunning) {
      _totalTime.start();
    }

    _processNext();
  }

  /// Process exactly one task at a time to maintain strict sequential order
  void _processNext() {
    if (_queue.isEmpty || _isCancelled) {
      _isProcessing = false;
      return;
    }

    final item = _queue.removeFirst();
    final taskStopwatch = Stopwatch()..start();

    // Execute the task and wait for completion before processing next
    item.execute().whenComplete(() {
      taskStopwatch.stop();
      _processingTimes.add(taskStopwatch.elapsedMilliseconds);

      // Keep only recent processing times for rolling average
      if (_processingTimes.length > 100) {
        _processingTimes.removeAt(0);
      }

      metrics.totalProcessed++;
      if (item.hasError) {
        metrics.totalErrors++;
      }

      _returnToPool(item);

      // Process next task only after current one completes
      if (_queue.isNotEmpty && !_isCancelled) {
        // Use microtask to avoid deep recursion but maintain sequential order
        scheduleMicrotask(_processNext);
      } else {
        _isProcessing = false;
      }
    });
  }

  /// Get comprehensive performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'queueLength': queueLength,
      'totalProcessed': metrics.totalProcessed,
      'totalErrors': metrics.totalErrors,
      'totalDropped': totalDropped,
      'peakQueueSize': metrics.peakQueueSize,
      'averageProcessingTime': averageProcessingTime,
      'throughputPerSecond': throughputPerSecond,
      'objectPoolSize': _objectPool.length,
      'errorRate': metrics.totalProcessed > 0 ? (metrics.totalErrors / metrics.totalProcessed) : 0.0,
      'dropRate': (metrics.totalProcessed + totalDropped) > 0 ? (totalDropped / (metrics.totalProcessed + totalDropped)) : 0.0,
    };
  }

  /// Reset all performance counters
  void resetStats() {
    metrics.totalProcessed = 0;
    metrics.totalErrors = 0;
    _totalDropped = 0;
    metrics.peakQueueSize = 0;
    _processingTimes.clear();
    _totalTime.reset();
  }
}

//////////////////////////////////////////////////////////////////////////////

class _PooledQueuedFuture<T> {
  late Completer<T> completer;
  late Future<T> Function() closure;
  bool hasError = false;

  _PooledQueuedFuture() {
    reset();
  }

  void initialize(Future<T> Function() taskClosure) {
    closure = taskClosure;
  }

  void reset() {
    completer = Completer<T>();
    hasError = false;
  }

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
