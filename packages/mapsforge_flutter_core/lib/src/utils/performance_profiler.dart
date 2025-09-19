import 'dart:async';
import 'dart:collection';
import 'dart:math' as Math;

/// Comprehensive performance profiling and monitoring system
class PerformanceProfiler {
  static final PerformanceProfiler _instance = PerformanceProfiler._internal();
  factory PerformanceProfiler() => _instance;
  PerformanceProfiler._internal();

  final Map<int, ProfilerSession> _activeSessions = {};
  final Map<String, List<PerformanceMetric>> _completedMetrics = {};
  final Queue<PerformanceEvent> _recentEvents = Queue<PerformanceEvent>();

  bool _enabled = false;
  int _maxRecentEvents = 1000;
  int _maxMetricsPerCategory = 500;

  /// Starts a new profiling session
  ProfilerSession startSession({String category = 'default'}) {
    if (!_enabled) return _NoOpProfilerSession();

    final session = DefaultProfilerSession._(category);
    _activeSessions[session.id] = session;
    return session;
  }

  /// Records a performance event directly without a session
  void recordEvent(Duration duration, {String category = "default", Map<String, dynamic> metadata = const {}}) {
    if (!_enabled) return;

    final event = PerformanceEvent(duration: duration, category: category, timestamp: DateTime.now(), metadata: metadata);

    _recentEvents.add(event);
    while (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeFirst();
    }

    // Convert to metric and store
    final categoryKey = event.category;
    List<PerformanceMetric> metrics = _completedMetrics.putIfAbsent(categoryKey, () => <PerformanceMetric>[]);
    metrics.add(PerformanceMetric.fromEvent(event));

    // Limit metrics per category
    while (metrics.length > _maxMetricsPerCategory) {
      metrics.removeAt(0);
    }
  }

  /// Completes a profiling session
  void _completeSession(DefaultProfilerSession session) {
    _activeSessions.remove(session.id);
    recordEvent(session.duration, category: session.category, metadata: session.metadata);
  }

  /// Gets performance statistics for a category
  PerformanceStats getStats(String category, bool microseconds) {
    final metrics = _completedMetrics[category] ?? [];
    if (metrics.isEmpty) {
      return PerformanceStats.empty(category);
    }

    final durations = microseconds ? metrics.map((m) => m.duration.inMicroseconds).toList() : metrics.map((m) => m.duration.inMilliseconds).toList();
    durations.sort();

    final int count = durations.length;
    final int sum = durations.reduce((a, b) => a + b);
    final double mean = sum / count;
    final double median = count % 2 == 0 ? (durations[count ~/ 2 - 1] + durations[count ~/ 2]) / 2 : durations[count ~/ 2].toDouble();

    final int min = durations.first;
    final int max = durations.last;
    final int p95 = durations[(count * 0.95).floor()];
    final int p99 = durations[(count * 0.99).floor()];

    // Calculate standard deviation
    final double variance = durations.map((d) => Math.pow(d - mean, 2)).reduce((a, b) => a + b) / count;
    final double stdDev = Math.sqrt(variance);

    return PerformanceStats(
      count: count,
      mean: mean.round(),
      median: median.round(),
      min: min,
      max: max,
      p95: p95,
      p99: p99,
      standardDeviation: stdDev.round(),
      sum: sum,
    );
  }

  /// Gets all available categories
  List<String> getCategories() {
    return _completedMetrics.keys.toList()..sort();
  }

  /// Gets recent performance events
  List<PerformanceEvent> getRecentEvents({int? limit, String? category}) {
    var events = _recentEvents.toList();

    if (category != null) {
      events = events.where((e) => e.category == category).toList();
    }

    if (limit != null && limit < events.length) {
      events = events.sublist(events.length - limit);
    }

    return events;
  }

  /// Gets comprehensive performance report
  PerformanceReport generateReport(bool microseconds) {
    final Map<String, PerformanceStats> categoryStats = {};
    for (final category in getCategories()) {
      categoryStats[category] = getStats(category, microseconds);
    }

    return PerformanceReport(
      timestamp: DateTime.now(),
      categoryStats: categoryStats,
      activeSessions: _activeSessions.length,
      totalEvents: _recentEvents.length,
      enabled: _enabled,
      instance: "${identityHashCode(this)}",
    );
  }

  /// Clears all performance data
  void clear() {
    _completedMetrics.clear();
    _recentEvents.clear();
    _activeSessions.clear();
  }

  /// Enables or disables profiling
  void setEnabled(bool enabled) {
    // assertions are not included in production code so it is impossible to enable profiling in release mode
    assert(() {
      _enabled = enabled;
      return true;
    }());
    if (!enabled) {
      _activeSessions.clear();
    }
  }

  /// Configures profiler settings
  void configure({int? maxRecentEvents, int? maxMetricsPerCategory}) {
    if (maxRecentEvents != null) {
      _maxRecentEvents = maxRecentEvents;
      while (_recentEvents.length > _maxRecentEvents) {
        _recentEvents.removeFirst();
      }
    }

    if (maxMetricsPerCategory != null) {
      _maxMetricsPerCategory = maxMetricsPerCategory;
      for (final metrics in _completedMetrics.values) {
        while (metrics.length > _maxMetricsPerCategory) {
          metrics.removeAt(0);
        }
      }
    }
  }

  /// Times a synchronous function execution
  T time<T>(T Function() function, {String category = "timeSync"}) {
    final session = startSession(category: category);
    try {
      return function();
    } finally {
      session.complete();
    }
  }

  /// Times an asynchronous function execution
  Future<T> timeAsync<T>(Future<T> Function() function, {String category = 'timeAsync'}) async {
    final session = startSession(category: category);
    try {
      return await function();
    } finally {
      session.complete();
    }
  }

  /// Gets profiler configuration
  Map<String, dynamic> getConfiguration() {
    return {
      'enabled': _enabled,
      'maxRecentEvents': _maxRecentEvents,
      'maxMetricsPerCategory': _maxMetricsPerCategory,
      'activeSessions': _activeSessions.length,
      'categories': getCategories().length,
      'totalEvents': _recentEvents.length,
    };
  }
}

//////////////////////////////////////////////////////////////////////////////

abstract class ProfilerSession {
  void addMetadata(String key, dynamic value);

  void complete() {}

  void checkpoint(String name);
}

//////////////////////////////////////////////////////////////////////////////

/// Represents a profiling session for measuring operation duration
class DefaultProfilerSession implements ProfilerSession {
  final int id;
  final String category;
  final DateTime startTime;
  final Map<String, dynamic> metadata = {};

  DateTime? _endTime;
  bool _completed = false;

  static int _nextId = 0;

  DefaultProfilerSession._(this.category) : id = ++_nextId, startTime = DateTime.now();

  /// Gets the duration of the session
  Duration get duration {
    final endTime = _endTime ?? DateTime.now();
    return endTime.difference(startTime);
  }

  /// Adds metadata to the session
  @override
  void addMetadata(String key, dynamic value) {
    if (!_completed) {
      metadata[key] = value;
    }
  }

  /// Completes the profiling session
  @override
  void complete() {
    if (_completed) return;

    _endTime = DateTime.now();
    _completed = true;
    PerformanceProfiler()._completeSession(this);
  }

  /// Records a checkpoint within the session
  @override
  void checkpoint(String name) {
    if (_completed) return;

    final checkpointDuration = DateTime.now().difference(startTime);
    metadata['checkpoint_$name'] = checkpointDuration.inMicroseconds;
  }
}

//////////////////////////////////////////////////////////////////////////////

/// No-op implementation for when profiling is disabled
class _NoOpProfilerSession implements ProfilerSession {
  _NoOpProfilerSession();

  @override
  void addMetadata(String key, dynamic value) {}

  @override
  void complete() {}

  @override
  void checkpoint(String name) {}
}

//////////////////////////////////////////////////////////////////////////////

/// Represents a single performance event
class PerformanceEvent {
  final Duration duration;
  final String category;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceEvent({required this.duration, required this.category, required this.timestamp, required this.metadata});

  @override
  String toString() {
    return 'category: $category, PerformanceEvent(duration: ${duration.inMilliseconds}ms)';
  }
}

//////////////////////////////////////////////////////////////////////////////

/// Represents a performance metric derived from events
class PerformanceMetric {
  final Duration duration;
  final String category;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric._({required this.duration, required this.category, required this.timestamp, required this.metadata});

  factory PerformanceMetric.fromEvent(PerformanceEvent event) {
    return PerformanceMetric._(duration: event.duration, category: event.category, timestamp: event.timestamp, metadata: Map.from(event.metadata));
  }
}

//////////////////////////////////////////////////////////////////////////////

/// Statistical analysis of performance metrics
class PerformanceStats {
  final int count;
  final int mean;
  final int median;
  final int min;
  final int max;
  final int p95;
  final int p99;
  final int standardDeviation;
  final int sum;

  PerformanceStats({
    // total number
    required this.count,
    // average
    required this.mean,
    required this.median,
    required this.min,
    required this.max,
    required this.p95,
    required this.p99,
    required this.standardDeviation,
    required this.sum,
  });

  factory PerformanceStats.empty(String category) {
    const zeroDuration = 0;
    return PerformanceStats(
      count: 0,
      mean: zeroDuration,
      median: zeroDuration,
      min: zeroDuration,
      max: zeroDuration,
      p95: zeroDuration,
      p99: zeroDuration,
      standardDeviation: zeroDuration,
      sum: zeroDuration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'count': count,
      'sum': sum,
      'mean_ms': mean,
      'median_ms': median,
      'min_ms': min,
      'max_ms': max,
      'p95_ms': p95,
      'p99_ms': p99,
      'stddev_ms': standardDeviation,
    };
  }

  @override
  String toString() {
    return 'count: $count, '
        'mean: ${mean}ms, sum: ${sum}ms, median: ${median}ms, min: ${min}ms, max: ${max}ms, p95: ${p95}ms, p99: ${p99}ms, stddev: ${standardDeviation}ms';
  }
}

//////////////////////////////////////////////////////////////////////////////

/// Comprehensive performance report
class PerformanceReport {
  final DateTime timestamp;
  final Map<String, PerformanceStats> categoryStats;
  final int activeSessions;
  final int totalEvents;
  final bool enabled;
  final String instance;

  PerformanceReport({
    required this.instance,
    required this.timestamp,
    required this.categoryStats,
    required this.activeSessions,
    required this.totalEvents,
    required this.enabled,
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> statsMap = {};
    for (final entry in categoryStats.entries) {
      statsMap[entry.key] = entry.value.toMap();
    }

    return {
      'timestamp': timestamp.toIso8601String(),
      'categoryStats': statsMap,
      'activeSessions': activeSessions,
      'totalEvents': totalEvents,
      'enabled': enabled,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Performance Report (${timestamp.toIso8601String()})');
    if (!enabled) buffer.writeln('Enabled: $enabled');
    buffer.writeln('Active Sessions: $activeSessions');
    buffer.writeln('Total Events: $totalEvents');
    buffer.writeln('Categories: ${categoryStats.length}');

    for (final entry in categoryStats.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }

    return buffer.toString();
  }
}
