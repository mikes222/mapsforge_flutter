import 'dart:async';

import 'package:mapsforge_flutter_core/src/task_queue/queue_cancelled_exception.dart';

/// Priority levels for tasks
enum TaskPriority {
  low(0),
  normal(1),
  high(2),
  critical(3);

  const TaskPriority(this.value);
  final int value;
}

/// Enhanced task queue with priority scheduling, cancellation, and timeout support
class EnhancedTaskQueue {
  final List<_EnhancedTask> _taskQueue = <_EnhancedTask>[];
  final Map<String, _EnhancedTask> _taskMap = <String, _EnhancedTask>{};
  final Set<String> _runningTasks = <String>{};
  final Set<String> _completedTasks = <String>{};

  bool _isCancelled = false;
  int _runningCount = 0;
  int _taskIdCounter = 0;

  final int maxParallel;
  final Duration defaultTimeout;

  EnhancedTaskQueue({this.maxParallel = 4, this.defaultTimeout = const Duration(minutes: 5)});

  bool get isCancelled => _isCancelled;
  int get queueLength => _taskQueue.length;
  int get runningCount => _runningCount;
  List<String> get runningTaskIds => _runningTasks.toList();

  /// Adds a task with specified priority and optional timeout
  Future<T> add<T>(Future<T> Function() closure, {TaskPriority priority = TaskPriority.normal, Duration? timeout, String? taskId, Set<String>? dependencies}) {
    if (_isCancelled) throw QueueCancelledException();

    final id = taskId ?? 'task_${++_taskIdCounter}';
    timeout ??= defaultTimeout;

    final task = _EnhancedTask<T>(
      id: id,
      closure: closure,
      priority: priority,
      timeout: timeout,
      dependencies: dependencies ?? <String>{},
      createdAt: DateTime.now(),
    );

    _taskMap[id] = task;
    _taskQueue.add(task);
    _taskQueue.sort(); // Keep queue sorted by priority

    _processNext();
    return task.completer.future;
  }

  /// Cancels a specific task by ID
  bool cancelTask(String taskId) {
    final task = _taskMap[taskId];
    if (task == null) return false;

    if (_runningTasks.contains(taskId)) {
      // Task is running, cancel its timer and completer
      task.timeoutTimer?.cancel();
      if (!task.completer.isCompleted) {
        task.completer.completeError(QueueCancelledException());
      }
      _runningTasks.remove(taskId);
      _runningCount--;
    } else {
      // Task is queued, remove from queue
      _taskQueue.remove(task);
      if (!task.completer.isCompleted) {
        task.completer.completeError(QueueCancelledException());
      }
    }

    _taskMap.remove(taskId);
    _processNext();
    return true;
  }

  /// Cancels all tasks with specified priority or lower
  void cancelTasksByPriority(TaskPriority maxPriority) {
    final tasksToCancel = _taskMap.values.where((task) => task.priority.value <= maxPriority.value).map((task) => task.id).toList();

    for (final taskId in tasksToCancel) {
      cancelTask(taskId);
    }
  }

  /// Cancels the entire queue
  void cancel() {
    _isCancelled = true;

    // Cancel all queued tasks
    for (final task in _taskQueue.toList()) {
      task.timeoutTimer?.cancel();
      if (!task.completer.isCompleted) {
        task.completer.completeError(QueueCancelledException());
      }
    }
    _taskQueue.clear();

    // Cancel all running tasks
    for (final taskId in _runningTasks.toList()) {
      final task = _taskMap[taskId];
      if (task != null) {
        task.timeoutTimer?.cancel();
        if (!task.completer.isCompleted) {
          task.completer.completeError(QueueCancelledException());
        }
      }
    }

    _taskMap.clear();
    _runningTasks.clear();
    _runningCount = 0;
  }

  /// Clears all queued tasks (not running ones)
  void clear() {
    final queuedTasks = _taskQueue.toList();
    _taskQueue.clear();

    for (final task in queuedTasks) {
      if (!task.completer.isCompleted) {
        task.completer.completeError(QueueCancelledException());
      }
      _taskMap.remove(task.id);
    }
  }

  /// Gets task statistics
  Map<String, dynamic> getStatistics() {
    final priorityCounts = <TaskPriority, int>{};
    for (final priority in TaskPriority.values) {
      priorityCounts[priority] = 0;
    }

    for (final task in _taskQueue) {
      priorityCounts[task.priority] = (priorityCounts[task.priority] ?? 0) + 1;
    }

    return {
      'queueLength': _taskQueue.length,
      'runningCount': _runningCount,
      'maxParallel': maxParallel,
      'priorityCounts': priorityCounts.map((k, v) => MapEntry(k.name, v)),
      'isCancelled': _isCancelled,
    };
  }

  /// Process next available tasks
  void _processNext() {
    while (!_isCancelled && _runningCount < maxParallel && _taskQueue.isNotEmpty) {
      // Find next task that has all dependencies completed
      _EnhancedTask? nextTask;
      for (int i = 0; i < _taskQueue.length; i++) {
        final task = _taskQueue[i];
        if (_areDepencenciesSatisfied(task)) {
          nextTask = task;
          _taskQueue.removeAt(i);
          break;
        }
      }

      if (nextTask == null) break;

      _runningTasks.add(nextTask.id);
      _runningCount++;

      _executeTask(nextTask);
    }
  }

  /// Check if all task dependencies are satisfied
  bool _areDepencenciesSatisfied(_EnhancedTask task) {
    for (final depId in task.dependencies) {
      if (!_completedTasks.contains(depId)) {
        // Dependency not yet completed
        return false;
      }
    }
    return true;
  }

  /// Execute a single task with timeout handling
  Future<void> _executeTask(_EnhancedTask task) async {
    // Set up timeout
    task.timeoutTimer = Timer(task.timeout, () {
      if (_runningTasks.contains(task.id)) {
        if (!task.completer.isCompleted) {
          task.completer.completeError(TimeoutException('Task ${task.id} timed out', task.timeout));
        }
        _taskCompleted(task);
      }
    });

    try {
      final result = await task.closure();
      task.timeoutTimer?.cancel();

      if (!task.completer.isCompleted) {
        task.completer.complete(result);
      }
    } catch (error, stackTrace) {
      task.timeoutTimer?.cancel();

      if (!task.completer.isCompleted) {
        task.completer.completeError(error, stackTrace);
      }
    } finally {
      _taskCompleted(task);
    }
  }

  /// Handle task completion cleanup
  void _taskCompleted(_EnhancedTask task) {
    _runningTasks.remove(task.id);
    _taskMap.remove(task.id);
    _completedTasks.add(task.id);
    _runningCount--;

    // Process next tasks
    _processNext();
  }
}

/// Work-stealing task queue for load balancing across multiple workers
class WorkStealingTaskQueue {
  final List<EnhancedTaskQueue> _workers;
  final int _numWorkers;
  int _nextWorker = 0;

  WorkStealingTaskQueue({int numWorkers = 4, int maxParallelPerWorker = 2})
    : _numWorkers = numWorkers,
      _workers = List.generate(numWorkers, (index) => EnhancedTaskQueue(maxParallel: maxParallelPerWorker));

  /// Add task to the least busy worker
  Future<T> add<T>(Future<T> Function() closure, {TaskPriority priority = TaskPriority.normal, Duration? timeout, String? taskId, Set<String>? dependencies}) {
    // Find worker with least load
    EnhancedTaskQueue leastBusyWorker = _workers[0];
    int minLoad = leastBusyWorker.queueLength + leastBusyWorker.runningCount;

    for (int i = 1; i < _workers.length; i++) {
      final worker = _workers[i];
      final load = worker.queueLength + worker.runningCount;
      if (load < minLoad) {
        minLoad = load;
        leastBusyWorker = worker;
      }
    }

    return leastBusyWorker.add(closure, priority: priority, timeout: timeout, taskId: taskId, dependencies: dependencies);
  }

  /// Add task to specific worker (round-robin)
  Future<T> addToWorker<T>(
    int workerIndex,
    Future<T> Function() closure, {
    TaskPriority priority = TaskPriority.normal,
    Duration? timeout,
    String? taskId,
    Set<String>? dependencies,
  }) {
    if (workerIndex < 0 || workerIndex >= _numWorkers) {
      throw ArgumentError('Worker index out of range: $workerIndex');
    }

    return _workers[workerIndex].add(closure, priority: priority, timeout: timeout, taskId: taskId, dependencies: dependencies);
  }

  /// Cancel all workers
  void cancel() {
    for (final worker in _workers) {
      worker.cancel();
    }
  }

  /// Get combined statistics from all workers
  Map<String, dynamic> getStatistics() {
    int totalQueue = 0;
    int totalRunning = 0;
    final Map<String, int> combinedPriorityCounts = {};

    for (final worker in _workers) {
      final stats = worker.getStatistics();
      totalQueue += stats['queueLength'] as int;
      totalRunning += stats['runningCount'] as int;

      final priorityCounts = stats['priorityCounts'] as Map<String, int>;
      for (final entry in priorityCounts.entries) {
        combinedPriorityCounts[entry.key] = (combinedPriorityCounts[entry.key] ?? 0) + entry.value;
      }
    }

    return {
      'numWorkers': _numWorkers,
      'totalQueueLength': totalQueue,
      'totalRunningCount': totalRunning,
      'combinedPriorityCounts': combinedPriorityCounts,
      'workerStats': _workers.map((w) => w.getStatistics()).toList(),
    };
  }
}

/// Internal task representation with priority and metadata
class _EnhancedTask<T> implements Comparable<_EnhancedTask> {
  final String id;
  final Future<T> Function() closure;
  final TaskPriority priority;
  final Duration timeout;
  final Set<String> dependencies;
  final DateTime createdAt;
  final Completer<T> completer = Completer<T>();

  Timer? timeoutTimer;

  _EnhancedTask({required this.id, required this.closure, required this.priority, required this.timeout, required this.dependencies, required this.createdAt});

  @override
  int compareTo(_EnhancedTask other) {
    // Higher priority first
    final priorityComparison = other.priority.value.compareTo(priority.value);
    if (priorityComparison != 0) return priorityComparison;

    // Earlier creation time first (FIFO within same priority)
    return createdAt.compareTo(other.createdAt);
  }
}
