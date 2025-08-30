import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/src/task_queue/enhanced_task_queue.dart';

/// Pool manager for geometric calculation isolates
/// Provides efficient reuse of isolates for CPU-intensive tasks
class IsolatePoolManager {
  final int _maxIsolates;
  final Queue<_IsolateWorker> _availableWorkers = Queue<_IsolateWorker>();
  final Set<_IsolateWorker> _busyWorkers = <_IsolateWorker>{};
  final EnhancedTaskQueue _taskQueue;

  bool _isShutdown = false;

  IsolatePoolManager({int maxIsolates = 4, int maxConcurrentTasks = 8})
    : _maxIsolates = maxIsolates,
      _taskQueue = EnhancedTaskQueue(maxParallel: maxConcurrentTasks);

  /// Get statistics about the isolate pool
  Map<String, dynamic> getStatistics() {
    return {
      'maxIsolates': _maxIsolates,
      'availableWorkers': _availableWorkers.length,
      'busyWorkers': _busyWorkers.length,
      'totalWorkers': _availableWorkers.length + _busyWorkers.length,
      'taskQueueStats': _taskQueue.getStatistics(),
      'isShutdown': _isShutdown,
    };
  }

  /// Execute Douglas-Peucker simplification using isolate pool
  Future<List<ILatLong>> simplifyPoints(List<ILatLong> points, double tolerance, {TaskPriority priority = TaskPriority.normal, Duration? timeout}) async {
    if (_isShutdown) {
      throw StateError('IsolatePoolManager has been shutdown');
    }

    // For small datasets, use synchronous calculation
    if (points.length < 1000) {
      return _douglasPeuckerSync(points, tolerance);
    }

    // Use task queue to manage isolate execution
    return await _taskQueue.add(() => _executeInIsolate(points, tolerance), priority: priority, timeout: timeout);
  }

  /// Execute calculation in available isolate
  Future<List<ILatLong>> _executeInIsolate(List<ILatLong> points, double tolerance) async {
    final worker = await _getWorker();

    try {
      final result = await worker.execute(points, tolerance);
      return result;
    } finally {
      _returnWorker(worker);
    }
  }

  /// Get an available worker, creating one if necessary
  Future<_IsolateWorker> _getWorker() async {
    if (_availableWorkers.isNotEmpty) {
      final worker = _availableWorkers.removeFirst();
      _busyWorkers.add(worker);
      return worker;
    }

    if (_availableWorkers.length + _busyWorkers.length < _maxIsolates) {
      final worker = await _createWorker();
      _busyWorkers.add(worker);
      return worker;
    }

    // Wait for a worker to become available
    final completer = Completer<_IsolateWorker>();
    _waitingForWorker.add(completer);
    return completer.future;
  }

  final Queue<Completer<_IsolateWorker>> _waitingForWorker = Queue<Completer<_IsolateWorker>>();

  /// Return worker to available pool
  void _returnWorker(_IsolateWorker worker) {
    _busyWorkers.remove(worker);

    if (_waitingForWorker.isNotEmpty) {
      final completer = _waitingForWorker.removeFirst();
      _busyWorkers.add(worker);
      completer.complete(worker);
    } else {
      _availableWorkers.add(worker);
    }
  }

  /// Create a new isolate worker
  Future<_IsolateWorker> _createWorker() async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(_isolateEntryPoint, receivePort.sendPort);

    final sendPort = await receivePort.first as SendPort;

    return _IsolateWorker(isolate: isolate, sendPort: sendPort, receivePort: receivePort);
  }

  /// Shutdown all isolates and clean up resources
  Future<void> shutdown() async {
    if (_isShutdown) return;

    _isShutdown = true;
    _taskQueue.cancel();

    // Complete all waiting requests with error
    while (_waitingForWorker.isNotEmpty) {
      final completer = _waitingForWorker.removeFirst();
      completer.completeError(StateError('IsolatePoolManager shutdown'));
    }

    // Kill all isolates
    final allWorkers = [..._availableWorkers, ..._busyWorkers];
    for (final worker in allWorkers) {
      worker.dispose();
    }

    _availableWorkers.clear();
    _busyWorkers.clear();
  }

  /// Synchronous Douglas-Peucker for small datasets
  static List<ILatLong> _douglasPeuckerSync(List<ILatLong> points, double tolerance) {
    if (points.length <= 2) return points;

    final toleranceSquared = tolerance * tolerance;
    final result = <ILatLong>[];
    final stack = Queue<_Segment>();

    stack.add(_Segment(0, points.length - 1));

    while (stack.isNotEmpty) {
      final segment = stack.removeFirst();
      final start = segment.start;
      final end = segment.end;

      double maxDistanceSquared = 0.0;
      int maxDistanceIndex = start;

      for (int i = start + 1; i < end; i++) {
        final distanceSquared = _perpendicularDistanceSquared(points[i], points[start], points[end]);
        if (distanceSquared > maxDistanceSquared) {
          maxDistanceSquared = distanceSquared;
          maxDistanceIndex = i;
        }
      }

      if (maxDistanceSquared > toleranceSquared) {
        stack.addFirst(_Segment(maxDistanceIndex, end));
        stack.addFirst(_Segment(start, maxDistanceIndex));
      } else {
        if (result.isEmpty) result.add(points[start]);
        result.add(points[end]);
      }
    }

    return result;
  }

  /// Calculate squared perpendicular distance
  static double _perpendicularDistanceSquared(ILatLong p, ILatLong a, ILatLong b) {
    final aLat = a.latitude;
    final aLon = a.longitude;
    final bLat = b.latitude;
    final bLon = b.longitude;
    final pLat = p.latitude;
    final pLon = p.longitude;

    if (aLat == bLat && aLon == bLon) {
      final dx = pLat - aLat;
      final dy = pLon - aLon;
      return dx * dx + dy * dy;
    }

    final area = (bLat - aLat) * (aLon - pLon) - (aLat - pLat) * (bLon - aLon);
    final dx = bLat - aLat;
    final dy = bLon - aLon;
    final abDistSquared = dx * dx + dy * dy;

    return (area * area) / abDistSquared;
  }

  /// Isolate entry point
  static void _isolateEntryPoint(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((message) {
      if (message is _IsolateTask) {
        final result = _douglasPeuckerSync(message.points, message.tolerance);
        message.replyPort.send(result);
      }
    });
  }
}

/// Individual isolate worker
class _IsolateWorker {
  final Isolate isolate;
  final SendPort sendPort;
  final ReceivePort receivePort;

  _IsolateWorker({required this.isolate, required this.sendPort, required this.receivePort});

  /// Execute Douglas-Peucker calculation in this isolate
  Future<List<ILatLong>> execute(List<ILatLong> points, double tolerance) async {
    final replyPort = ReceivePort();

    sendPort.send(_IsolateTask(points: points, tolerance: tolerance, replyPort: replyPort.sendPort));

    try {
      final result = await replyPort.first as List<ILatLong>;
      return result;
    } finally {
      replyPort.close();
    }
  }

  /// Dispose of this worker
  void dispose() {
    receivePort.close();
    isolate.kill();
  }
}

/// Task message for isolate communication
class _IsolateTask {
  final List<ILatLong> points;
  final double tolerance;
  final SendPort replyPort;

  const _IsolateTask({required this.points, required this.tolerance, required this.replyPort});
}

/// Internal segment representation
class _Segment {
  final int start;
  final int end;

  const _Segment(this.start, this.end);
}
