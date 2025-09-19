import 'dart:async';
import 'dart:math' as Math;

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/src/utils/douglas_peucker_latlong.dart';

import 'package:mapsforge_flutter_core/src/utils/performance_profiler.dart';

/// Comprehensive integration benchmark to measure overall performance improvements
class IntegrationBenchmark {
  /// Runs comprehensive performance benchmarks
  Future<void> runBenchmarks({int iterations = 100}) async {
    //_profiler.setEnabled(true);
    //_profiler.clear();

    // 1. Douglas-Peucker Line Simplification Benchmark
    await _benchmarkDouglasPeucker(iterations);

    // 2. Spatial Operations Benchmark
    await _benchmarkSpatialOperations(iterations);

    // 3. Memory Operations Benchmark
    await _benchmarkMemoryOperations(iterations);

    // 4. Concurrent Operations Benchmark
    await _benchmarkConcurrentOperations(iterations);

    print(PerformanceProfiler().generateReport(true));
  }

  /// Benchmarks Douglas-Peucker line simplification performance
  Future<void> _benchmarkDouglasPeucker(int iterations) async {
    final List<Duration> durations = [];
    final List<int> inputSizes = [100, 500, 1000, 2000, 5000];
    final Map<int, Duration> sizeToTime = {};

    for (final int size in inputSizes) {
      final List<LatLong> points = _generateTestPoints(size);
      final List<Duration> sizeDurations = [];

      for (int i = 0; i < iterations ~/ inputSizes.length; i++) {
        final session = PerformanceProfiler().startSession(category: 'line_simplification');

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
  }

  /// Benchmarks spatial operations performance
  Future<void> _benchmarkSpatialOperations(int iterations) async {
    for (int i = 0; i < iterations; i++) {
      final session = PerformanceProfiler().startSession(category: 'spatial');

      // Simulate spatial operations
      final BoundingBox bounds1 = const BoundingBox(0.0, 0.0, 1.0, 1.0);
      final BoundingBox bounds2 = const BoundingBox(0.5, 0.5, 1.5, 1.5);

      // Test intersection
      final bool intersects = bounds1.intersects(bounds2);

      // Test containment
      final bool contains = bounds1.contains(0.75, 0.75);

      // Test distance calculations
      final LatLong point1 = const LatLong(0.0, 0.0);
      final LatLong point2 = const LatLong(1.0, 1.0);
      final double distance = _calculateDistance(point1, point2);

      session.addMetadata('intersects', intersects);
      session.addMetadata('contains', contains);
      session.addMetadata('distance', distance);
      session.complete();
    }
  }

  /// Benchmarks memory operations performance
  Future<void> _benchmarkMemoryOperations(int iterations) async {
    for (int i = 0; i < iterations; i++) {
      final session = PerformanceProfiler().startSession(category: 'memory');

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

      session.addMetadata('list_size', largeList.length);
      session.addMetadata('map_size', pointMap.length);
      session.complete();
    }
  }

  /// Benchmarks concurrent operations performance
  Future<void> _benchmarkConcurrentOperations(int iterations) async {
    final int concurrentTasks = 4;

    for (int i = 0; i < iterations ~/ concurrentTasks; i++) {
      final session = PerformanceProfiler().startSession(category: 'concurrency');

      // Create concurrent tasks
      final List<Future<List<ILatLong>>> futures = [];
      for (int j = 0; j < concurrentTasks; j++) {
        futures.add(_simulateConcurrentTask(500 + j * 100));
      }

      // Wait for all tasks to complete
      final List<List<ILatLong>> results = await Future.wait(futures);

      session.addMetadata('concurrent_tasks', concurrentTasks);
      session.addMetadata('total_results', results.expand((r) => r).length);
      session.complete();
    }
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

  /// Calculates distance between two points (simplified)
  double _calculateDistance(LatLong point1, LatLong point2) {
    final double latDiff = point1.latitude - point2.latitude;
    final double lonDiff = point1.longitude - point2.longitude;
    return Math.sqrt(latDiff * latDiff + lonDiff * lonDiff);
  }
}
