import 'dart:async';
import 'dart:math' as Math;

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/src/utils/douglas_peucker_latlong.dart';

import 'performance_profiler.dart';

/// Comprehensive integration benchmark to measure overall performance improvements
class IntegrationBenchmark {
  final PerformanceProfiler _profiler = PerformanceProfiler();

  /// Runs comprehensive performance benchmarks
  Future<BenchmarkResults> runBenchmarks({bool enableProfiling = true, int iterations = 100}) async {
    if (enableProfiling) {
      _profiler.setEnabled(true);
      _profiler.clear();
    }

    final results = BenchmarkResults();

    // 1. Douglas-Peucker Line Simplification Benchmark
    results.douglasPeuckerResults = await _benchmarkDouglasPeucker(iterations);

    // 2. Spatial Operations Benchmark
    results.spatialResults = await _benchmarkSpatialOperations(iterations);

    // 3. Memory Operations Benchmark
    results.memoryResults = await _benchmarkMemoryOperations(iterations);

    // 4. Concurrent Operations Benchmark
    results.concurrentResults = await _benchmarkConcurrentOperations(iterations);

    // Generate overall performance report
    if (enableProfiling) {
      results.performanceReport = _profiler.generateReport();
    }

    return results;
  }

  /// Benchmarks Douglas-Peucker line simplification performance
  Future<OperationBenchmarkResult> _benchmarkDouglasPeucker(int iterations) async {
    final List<Duration> durations = [];
    final List<int> inputSizes = [100, 500, 1000, 2000, 5000];
    final Map<int, Duration> sizeToTime = {};

    for (final int size in inputSizes) {
      final List<LatLong> points = _generateTestPoints(size);
      final List<Duration> sizeDurations = [];

      for (int i = 0; i < iterations ~/ inputSizes.length; i++) {
        final session = _profiler.startSession('douglas_peucker_$size', category: 'line_simplification');

        final stopwatch = Stopwatch()..start();
        DouglasPeuckerLatLong().simplify(points, 0.001);
        stopwatch.stop();

        session.addMetadata('input_size', size);
        session.addMetadata('iteration', i);
        session.complete();

        sizeDurations.add(stopwatch.elapsed);
        durations.add(stopwatch.elapsed);
      }

      // Calculate average for this size
      final avgDuration = Duration(microseconds: sizeDurations.map((d) => d.inMicroseconds).reduce((a, b) => a + b) ~/ sizeDurations.length);
      sizeToTime[size] = avgDuration;
    }

    return OperationBenchmarkResult(
      operationName: 'Douglas-Peucker Line Simplification',
      totalIterations: durations.length,
      averageDuration: _calculateAverage(durations),
      minDuration: durations.reduce((a, b) => a < b ? a : b),
      maxDuration: durations.reduce((a, b) => a > b ? a : b),
      sizeToPerformance: sizeToTime,
    );
  }

  /// Benchmarks spatial operations performance
  Future<OperationBenchmarkResult> _benchmarkSpatialOperations(int iterations) async {
    final List<Duration> durations = [];
    final Map<int, Duration> sizeToTime = {};

    for (int i = 0; i < iterations; i++) {
      final session = _profiler.startSession('spatial_operations', category: 'spatial');

      final stopwatch = Stopwatch()..start();

      // Simulate spatial operations
      final BoundingBox bounds1 = BoundingBox(0.0, 0.0, 1.0, 1.0);
      final BoundingBox bounds2 = BoundingBox(0.5, 0.5, 1.5, 1.5);

      // Test intersection
      final bool intersects = bounds1.intersects(bounds2);

      // Test containment
      final bool contains = bounds1.contains(0.75, 0.75);

      // Test distance calculations
      final LatLong point1 = LatLong(0.0, 0.0);
      final LatLong point2 = LatLong(1.0, 1.0);
      final double distance = _calculateDistance(point1, point2);

      stopwatch.stop();

      session.addMetadata('intersects', intersects);
      session.addMetadata('contains', contains);
      session.addMetadata('distance', distance);
      session.complete();

      durations.add(stopwatch.elapsed);
    }

    return OperationBenchmarkResult(
      operationName: 'Spatial Operations',
      totalIterations: iterations,
      averageDuration: _calculateAverage(durations),
      minDuration: durations.reduce((a, b) => a < b ? a : b),
      maxDuration: durations.reduce((a, b) => a > b ? a : b),
      sizeToPerformance: sizeToTime,
    );
  }

  /// Benchmarks memory operations performance
  Future<OperationBenchmarkResult> _benchmarkMemoryOperations(int iterations) async {
    final List<Duration> durations = [];
    final Map<int, Duration> sizeToTime = {};

    for (int i = 0; i < iterations; i++) {
      final session = _profiler.startSession('memory_operations', category: 'memory');

      final stopwatch = Stopwatch()..start();

      // Simulate memory-intensive operations
      final List<LatLong> largeList = _generateTestPoints(1000);
      final Map<String, LatLong> pointMap = {};

      // Fill map
      for (int j = 0; j < largeList.length; j++) {
        pointMap['point_$j'] = largeList[j];
      }

      // Access patterns
      for (int j = 0; j < 100; j++) {
        final key = 'point_${j * 10}';
        final point = pointMap[key];
        if (point != null) {
          // Simulate processing
          final processed = LatLong(point.latitude * 1.1, point.longitude * 1.1);
        }
      }

      stopwatch.stop();

      session.addMetadata('list_size', largeList.length);
      session.addMetadata('map_size', pointMap.length);
      session.complete();

      durations.add(stopwatch.elapsed);
    }

    return OperationBenchmarkResult(
      operationName: 'Memory Operations',
      totalIterations: iterations,
      averageDuration: _calculateAverage(durations),
      minDuration: durations.reduce((a, b) => a < b ? a : b),
      maxDuration: durations.reduce((a, b) => a > b ? a : b),
      sizeToPerformance: sizeToTime,
    );
  }

  /// Benchmarks concurrent operations performance
  Future<OperationBenchmarkResult> _benchmarkConcurrentOperations(int iterations) async {
    final List<Duration> durations = [];
    final Map<int, Duration> sizeToTime = {};

    final int concurrentTasks = 4;

    for (int i = 0; i < iterations ~/ concurrentTasks; i++) {
      final session = _profiler.startSession('concurrent_operations', category: 'concurrency');

      final stopwatch = Stopwatch()..start();

      // Create concurrent tasks
      final List<Future<List<ILatLong>>> futures = [];
      for (int j = 0; j < concurrentTasks; j++) {
        futures.add(_simulateConcurrentTask(500 + j * 100));
      }

      // Wait for all tasks to complete
      final List<List<ILatLong>> results = await Future.wait(futures);

      stopwatch.stop();

      session.addMetadata('concurrent_tasks', concurrentTasks);
      session.addMetadata('total_results', results.expand((r) => r).length);
      session.complete();

      durations.add(stopwatch.elapsed);
    }

    return OperationBenchmarkResult(
      operationName: 'Concurrent Operations',
      totalIterations: durations.length,
      averageDuration: _calculateAverage(durations),
      minDuration: durations.reduce((a, b) => a < b ? a : b),
      maxDuration: durations.reduce((a, b) => a > b ? a : b),
      sizeToPerformance: sizeToTime,
    );
  }

  /// Simulates a concurrent task
  Future<List<ILatLong>> _simulateConcurrentTask(int pointCount) async {
    final points = _generateTestPoints(pointCount);

    // Simulate processing delay
    await Future.delayed(const Duration(microseconds: 100));

    // Apply Douglas-Peucker simplification
    return DouglasPeuckerLatLong().simplify(points, 0.001);
  }

  /// Generates test points for benchmarking
  List<LatLong> _generateTestPoints(int count) {
    final Math.Random random = Math.Random(42); // Fixed seed for reproducibility
    final List<LatLong> points = [];

    for (int i = 0; i < count; i++) {
      final double lat = random.nextDouble() * 180.0 - 90.0; // -90 to 90
      final double lon = random.nextDouble() * 360.0 - 180.0; // -180 to 180
      points.add(LatLong(lat, lon));
    }

    return points;
  }

  /// Calculates average duration
  Duration _calculateAverage(List<Duration> durations) {
    if (durations.isEmpty) return Duration.zero;

    final int totalMicroseconds = durations.map((d) => d.inMicroseconds).reduce((a, b) => a + b);

    return Duration(microseconds: totalMicroseconds ~/ durations.length);
  }

  /// Calculates distance between two points (simplified)
  double _calculateDistance(LatLong point1, LatLong point2) {
    final double latDiff = point1.latitude - point2.latitude;
    final double lonDiff = point1.longitude - point2.longitude;
    return Math.sqrt(latDiff * latDiff + lonDiff * lonDiff);
  }
}

/// Results from a complete benchmark run
class BenchmarkResults {
  OperationBenchmarkResult? douglasPeuckerResults;
  OperationBenchmarkResult? spatialResults;
  OperationBenchmarkResult? memoryResults;
  OperationBenchmarkResult? concurrentResults;
  PerformanceReport? performanceReport;

  /// Gets overall performance improvement metrics
  Map<String, dynamic> getOverallMetrics() {
    final Map<String, dynamic> metrics = {};

    if (douglasPeuckerResults != null) {
      metrics['douglasPeucker'] = douglasPeuckerResults!.toMap();
    }

    if (spatialResults != null) {
      metrics['spatial'] = spatialResults!.toMap();
    }

    if (memoryResults != null) {
      metrics['memory'] = memoryResults!.toMap();
    }

    if (concurrentResults != null) {
      metrics['concurrent'] = concurrentResults!.toMap();
    }

    if (performanceReport != null) {
      metrics['profilerReport'] = performanceReport!.toMap();
    }

    return metrics;
  }

  /// Generates a summary report
  String generateSummaryReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Integration Benchmark Results ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln();

    if (douglasPeuckerResults != null) {
      buffer.writeln('Douglas-Peucker Line Simplification:');
      buffer.writeln('  Average: ${douglasPeuckerResults!.averageDuration.inMilliseconds}ms');
      buffer.writeln('  Min: ${douglasPeuckerResults!.minDuration.inMilliseconds}ms');
      buffer.writeln('  Max: ${douglasPeuckerResults!.maxDuration.inMilliseconds}ms');
      buffer.writeln('  Iterations: ${douglasPeuckerResults!.totalIterations}');
      buffer.writeln();
    }

    if (spatialResults != null) {
      buffer.writeln('Spatial Operations:');
      buffer.writeln('  Average: ${spatialResults!.averageDuration.inMicroseconds}μs');
      buffer.writeln('  Min: ${spatialResults!.minDuration.inMicroseconds}μs');
      buffer.writeln('  Max: ${spatialResults!.maxDuration.inMicroseconds}μs');
      buffer.writeln('  Iterations: ${spatialResults!.totalIterations}');
      buffer.writeln();
    }

    if (memoryResults != null) {
      buffer.writeln('Memory Operations:');
      buffer.writeln('  Average: ${memoryResults!.averageDuration.inMilliseconds}ms');
      buffer.writeln('  Min: ${memoryResults!.minDuration.inMilliseconds}ms');
      buffer.writeln('  Max: ${memoryResults!.maxDuration.inMilliseconds}ms');
      buffer.writeln('  Iterations: ${memoryResults!.totalIterations}');
      buffer.writeln();
    }

    if (concurrentResults != null) {
      buffer.writeln('Concurrent Operations:');
      buffer.writeln('  Average: ${concurrentResults!.averageDuration.inMilliseconds}ms');
      buffer.writeln('  Min: ${concurrentResults!.minDuration.inMilliseconds}ms');
      buffer.writeln('  Max: ${concurrentResults!.maxDuration.inMilliseconds}ms');
      buffer.writeln('  Iterations: ${concurrentResults!.totalIterations}');
      buffer.writeln();
    }

    if (performanceReport != null) {
      buffer.writeln('Performance Profiler Summary:');
      buffer.writeln('  Categories: ${performanceReport!.categoryStats.length}');
      buffer.writeln('  Total Events: ${performanceReport!.totalEvents}');
      buffer.writeln();
    }

    return buffer.toString();
  }
}

/// Results from a specific operation benchmark
class OperationBenchmarkResult {
  final String operationName;
  final int totalIterations;
  final Duration averageDuration;
  final Duration minDuration;
  final Duration maxDuration;
  final Map<int, Duration> sizeToPerformance;

  OperationBenchmarkResult({
    required this.operationName,
    required this.totalIterations,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.sizeToPerformance,
  });

  Map<String, dynamic> toMap() {
    return {
      'operationName': operationName,
      'totalIterations': totalIterations,
      'averageDuration_ms': averageDuration.inMilliseconds,
      'minDuration_ms': minDuration.inMilliseconds,
      'maxDuration_ms': maxDuration.inMilliseconds,
      'sizeToPerformance': sizeToPerformance.map((size, duration) => MapEntry(size.toString(), duration.inMilliseconds)),
    };
  }
}
