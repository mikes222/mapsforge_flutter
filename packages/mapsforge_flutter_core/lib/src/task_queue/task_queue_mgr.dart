import 'package:mapsforge_flutter_core/src/task_queue/task_queue.dart';

/// A singleton manager for all `TaskQueue` instances.
///
/// This class provides a central point for registering, unregistering, and
/// monitoring task queues. It can be enabled or disabled for performance profiling.
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

  /// Enables or disables the task queue manager.
  ///
  /// When disabled, no queues are registered and no metrics are collected.
  /// This can only be enabled in debug mode.
  void setEnabled(bool enabled) {
    // assertions are not included in production code so it is impossible to enable profiling in release mode
    assert(() {
      _enabled = enabled;
      return true;
    }());
  }

  /// Returns true if the task queue manager is enabled.
  bool isEnabled() => _enabled;

  /// Registers a `TaskQueue` with the manager.
  void register(TaskQueue taskQueue) {
    if (!_enabled) return;
    _queues.add(taskQueue);
    ++_registered;
  }

  /// Unregisters a `TaskQueue` from the manager.
  void unregister(TaskQueue taskQueue) {
    _queues.remove(taskQueue);
    ++_unregisterd;
  }

  /// Clears the metrics of all registered queues.
  void clear() {
    for (var queue in _queues) {
      queue.metrics.clear();
    }
    _registered = 0;
    _unregisterd = 0;
  }

  /// Creates a report with the current metrics of all registered queues.
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

/// A report containing performance metrics for all registered task queues.
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

  /// A list of metrics for each registered queue.
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
