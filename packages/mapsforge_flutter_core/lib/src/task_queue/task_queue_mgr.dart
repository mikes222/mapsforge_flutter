import 'package:mapsforge_flutter_core/src/task_queue/task_queue.dart';

class TaskQueueMgr {
  static TaskQueueMgr? _instance;

  final Set<TaskQueue> _queues = {};

  bool _enabled = false;

  int _registered = 0;

  int _unregisterd = 0;

  TaskQueueMgr._();

  factory TaskQueueMgr() {
    if (_instance != null) return _instance!;
    _instance = TaskQueueMgr._();
    return _instance!;
  }

  void setEnabled(bool enabled) {
    // assertions are not included in production code so it is impossible to enable profiling in release mode
    assert(() {
      _enabled = enabled;
      return true;
    }());
  }

  bool isEnabled() => _enabled;

  void register(TaskQueue taskQueue) {
    if (!_enabled) return;
    _queues.add(taskQueue);
    ++_registered;
  }

  void unregister(TaskQueue taskQueue) {
    _queues.remove(taskQueue);
    ++_unregisterd;
  }

  void clear() {
    for (var queue in _queues) {
      queue.metrics.clear();
    }
    _registered = 0;
    _unregisterd = 0;
  }

  TaskQueueReport createReport() {
    final report = TaskQueueReport();
    for (var queue in _queues) {
      report.queueMetrics.add(queue.metrics);
    }
    return report;
  }

  /// Reset the singleton instance (for testing purposes only)
  // @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }
}

//////////////////////////////////////////////////////////////////////////////

class TaskQueueReport {
  final DateTime timestamp;

  final int registered;

  final int unregistered;

  final bool enabled;

  final List<TaskQueueMetrics> _queueMetrics = [];

  TaskQueueReport()
    : registered = TaskQueueMgr()._registered,
      unregistered = TaskQueueMgr()._unregisterd,
      enabled = TaskQueueMgr().isEnabled(),
      timestamp = DateTime.now();

  /// Returns the storage metrics map
  List<TaskQueueMetrics> get queueMetrics => _queueMetrics;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('TaskQueue Report (${timestamp.toIso8601String()})');
    buffer.writeln('TaskQueue registered: $registered, unregistered: $unregistered');
    if (!enabled) buffer.writeln('TaskQueue reports are disabled');
    for (final entry in queueMetrics) {
      buffer.writeln('  $entry');
    }

    return buffer.toString();
  }
}
