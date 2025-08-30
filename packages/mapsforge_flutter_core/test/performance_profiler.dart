import 'dart:async';
import 'dart:collection';
import 'dart:math' as Math;

/// Comprehensive performance profiling and monitoring system
class PerformanceProfiler {
  static final PerformanceProfiler _instance = PerformanceProfiler._internal();
  factory PerformanceProfiler() => _instance;
  PerformanceProfiler._internal();

  final Map<String, ProfilerSession> _activeSessions = {};
  final Map<String, List<PerformanceMetric>> _completedMetrics = {};
  final Queue<PerformanceEvent> _recentEvents = Queue<PerformanceEvent>();
  
  bool _enabled = true;
  int _maxRecentEvents = 1000;
  int _maxMetricsPerCategory = 500;

  /// Starts a new profiling session
  ProfilerSession startSession(String name, {String? category}) {
    if (!_enabled) return _NoOpProfilerSession();
    
    final session = ProfilerSession._(name, category ?? 'default');
    _activeSessions[session.id] = session;
    return session;
  }

  /// Records a performance event
  void recordEvent(String name, Duration duration, {
    String? category,
    Map<String, dynamic>? metadata,
  }) {
    if (!_enabled) return;

    final event = PerformanceEvent(
      name: name,
      duration: duration,
      category: category ?? 'default',
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _recentEvents.add(event);
    while (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeFirst();
    }

    // Convert to metric and store
    final metric = PerformanceMetric.fromEvent(event);
    final categoryKey = event.category;
    _completedMetrics.putIfAbsent(categoryKey, () => <PerformanceMetric>[]);
    _completedMetrics[categoryKey]!.add(metric);

    // Limit metrics per category
    final categoryMetrics = _completedMetrics[categoryKey]!;
    while (categoryMetrics.length > _maxMetricsPerCategory) {
      categoryMetrics.removeAt(0);
    }
  }

  /// Completes a profiling session
  void _completeSession(ProfilerSession session) {
    _activeSessions.remove(session.id);
    recordEvent(session.name, session.duration, 
        category: session.category, metadata: session.metadata);
  }

  /// Gets performance statistics for a category
  PerformanceStats getStats(String category) {
    final metrics = _completedMetrics[category] ?? [];
    if (metrics.isEmpty) {
      return PerformanceStats.empty(category);
    }

    final durations = metrics.map((m) => m.duration.inMicroseconds).toList();
    durations.sort();

    final int count = durations.length;
    final double mean = durations.reduce((a, b) => a + b) / count;
    final double median = count % 2 == 0
        ? (durations[count ~/ 2 - 1] + durations[count ~/ 2]) / 2
        : durations[count ~/ 2].toDouble();
    
    final int min = durations.first;
    final int max = durations.last;
    final int p95 = durations[(count * 0.95).floor()];
    final int p99 = durations[(count * 0.99).floor()];

    // Calculate standard deviation
    final double variance = durations
        .map((d) => Math.pow(d - mean, 2))
        .reduce((a, b) => a + b) / count;
    final double stdDev = Math.sqrt(variance);

    return PerformanceStats(
      category: category,
      count: count,
      mean: Duration(microseconds: mean.round()),
      median: Duration(microseconds: median.round()),
      min: Duration(microseconds: min),
      max: Duration(microseconds: max),
      p95: Duration(microseconds: p95),
      p99: Duration(microseconds: p99),
      standardDeviation: Duration(microseconds: stdDev.round()),
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
  PerformanceReport generateReport() {
    final Map<String, PerformanceStats> categoryStats = {};
    for (final category in getCategories()) {
      categoryStats[category] = getStats(category);
    }

    return PerformanceReport(
      timestamp: DateTime.now(),
      categoryStats: categoryStats,
      activeSessions: _activeSessions.length,
      totalEvents: _recentEvents.length,
      enabled: _enabled,
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
    _enabled = enabled;
    if (!enabled) {
      _activeSessions.clear();
    }
  }

  /// Configures profiler settings
  void configure({
    int? maxRecentEvents,
    int? maxMetricsPerCategory,
  }) {
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

/// Represents a profiling session for measuring operation duration
class ProfilerSession {
  final String id;
  final String name;
  final String category;
  final DateTime startTime;
  final Map<String, dynamic> metadata = {};
  
  DateTime? _endTime;
  bool _completed = false;

  ProfilerSession._(this.name, this.category) 
      : id = '${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}',
        startTime = DateTime.now();

  /// Gets the duration of the session
  Duration get duration {
    final endTime = _endTime ?? DateTime.now();
    return endTime.difference(startTime);
  }

  /// Adds metadata to the session
  void addMetadata(String key, dynamic value) {
    if (!_completed) {
      metadata[key] = value;
    }
  }

  /// Completes the profiling session
  void complete() {
    if (_completed) return;
    
    _endTime = DateTime.now();
    _completed = true;
    PerformanceProfiler()._completeSession(this);
  }

  /// Records a checkpoint within the session
  void checkpoint(String name) {
    if (_completed) return;
    
    final checkpointDuration = DateTime.now().difference(startTime);
    metadata['checkpoint_$name'] = checkpointDuration.inMicroseconds;
  }
}

/// No-op implementation for when profiling is disabled
class _NoOpProfilerSession extends ProfilerSession {
  _NoOpProfilerSession() : super._('noop', 'noop');

  @override
  void addMetadata(String key, dynamic value) {}

  @override
  void complete() {}

  @override
  void checkpoint(String name) {}
}

/// Represents a single performance event
class PerformanceEvent {
  final String name;
  final Duration duration;
  final String category;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceEvent({
    required this.name,
    required this.duration,
    required this.category,
    required this.timestamp,
    required this.metadata,
  });

  @override
  String toString() {
    return 'PerformanceEvent(name: $name, duration: ${duration.inMilliseconds}ms, category: $category)';
  }
}

/// Represents a performance metric derived from events
class PerformanceMetric {
  final String name;
  final Duration duration;
  final String category;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.category,
    required this.timestamp,
    required this.metadata,
  });

  factory PerformanceMetric.fromEvent(PerformanceEvent event) {
    return PerformanceMetric(
      name: event.name,
      duration: event.duration,
      category: event.category,
      timestamp: event.timestamp,
      metadata: Map.from(event.metadata),
    );
  }
}

/// Statistical analysis of performance metrics
class PerformanceStats {
  final String category;
  final int count;
  final Duration mean;
  final Duration median;
  final Duration min;
  final Duration max;
  final Duration p95;
  final Duration p99;
  final Duration standardDeviation;

  PerformanceStats({
    required this.category,
    required this.count,
    required this.mean,
    required this.median,
    required this.min,
    required this.max,
    required this.p95,
    required this.p99,
    required this.standardDeviation,
  });

  factory PerformanceStats.empty(String category) {
    const zeroDuration = Duration.zero;
    return PerformanceStats(
      category: category,
      count: 0,
      mean: zeroDuration,
      median: zeroDuration,
      min: zeroDuration,
      max: zeroDuration,
      p95: zeroDuration,
      p99: zeroDuration,
      standardDeviation: zeroDuration,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'count': count,
      'mean_ms': mean.inMilliseconds,
      'median_ms': median.inMilliseconds,
      'min_ms': min.inMilliseconds,
      'max_ms': max.inMilliseconds,
      'p95_ms': p95.inMilliseconds,
      'p99_ms': p99.inMilliseconds,
      'stddev_ms': standardDeviation.inMilliseconds,
    };
  }

  @override
  String toString() {
    return 'PerformanceStats(category: $category, count: $count, '
           'mean: ${mean.inMilliseconds}ms, p95: ${p95.inMilliseconds}ms)';
  }
}

/// Comprehensive performance report
class PerformanceReport {
  final DateTime timestamp;
  final Map<String, PerformanceStats> categoryStats;
  final int activeSessions;
  final int totalEvents;
  final bool enabled;

  PerformanceReport({
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
    buffer.writeln('Enabled: $enabled');
    buffer.writeln('Active Sessions: $activeSessions');
    buffer.writeln('Total Events: $totalEvents');
    buffer.writeln('Categories: ${categoryStats.length}');
    
    for (final entry in categoryStats.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    
    return buffer.toString();
  }
}

/// Convenience functions for common profiling patterns
extension PerformanceProfilerExtensions on PerformanceProfiler {
  /// Times a synchronous function execution
  T time<T>(String name, T Function() function, {String? category}) {
    final session = startSession(name, category: category);
    try {
      return function();
    } finally {
      session.complete();
    }
  }

  /// Times an asynchronous function execution
  Future<T> timeAsync<T>(String name, Future<T> Function() function, {String? category}) async {
    final session = startSession(name, category: category);
    try {
      return await function();
    } finally {
      session.complete();
    }
  }
}
