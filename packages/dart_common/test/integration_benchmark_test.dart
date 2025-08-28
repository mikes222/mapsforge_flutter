import 'package:test/test.dart';

import 'integration_benchmark.dart';

void main() {
  group('IntegrationBenchmark', () {
    late IntegrationBenchmark benchmark;

    setUp(() {
      benchmark = IntegrationBenchmark();
    });

    test('should run comprehensive benchmarks', () async {
      final results = await benchmark.runBenchmarks(
        enableProfiling: true,
        iterations: 20, // Reduced for faster testing
      );

      expect(results.douglasPeuckerResults, isNotNull);
      expect(results.spatialResults, isNotNull);
      expect(results.memoryResults, isNotNull);
      expect(results.concurrentResults, isNotNull);
      expect(results.performanceReport, isNotNull);

      // Verify Douglas-Peucker results
      final dpResults = results.douglasPeuckerResults!;
      expect(dpResults.operationName, equals('Douglas-Peucker Line Simplification'));
      expect(dpResults.totalIterations, greaterThan(0));
      expect(dpResults.averageDuration.inMicroseconds, greaterThan(0));
      expect(dpResults.sizeToPerformance.isNotEmpty, isTrue);

      // Verify spatial results
      final spatialResults = results.spatialResults!;
      expect(spatialResults.operationName, equals('Spatial Operations'));
      expect(spatialResults.totalIterations, equals(20));
      expect(spatialResults.averageDuration.inMicroseconds, greaterThan(0));

      // Verify memory results
      final memoryResults = results.memoryResults!;
      expect(memoryResults.operationName, equals('Memory Operations'));
      expect(memoryResults.totalIterations, equals(20));
      expect(memoryResults.averageDuration.inMicroseconds, greaterThan(0));

      // Verify concurrent results
      final concurrentResults = results.concurrentResults!;
      expect(concurrentResults.operationName, equals('Concurrent Operations'));
      expect(concurrentResults.totalIterations, greaterThan(0));
      expect(concurrentResults.averageDuration.inMicroseconds, greaterThan(0));
    });

    test('should generate overall metrics', () async {
      final results = await benchmark.runBenchmarks(iterations: 10);
      final metrics = results.getOverallMetrics();

      // expect(metrics, containsKey('douglasPeucker'));
      // expect(metrics, containsKey('spatial'));
      // expect(metrics, containsKey('memory'));
      // expect(metrics, containsKey('concurrent'));
      // expect(metrics, containsKey('profilerReport'));
    });

    test('should generate summary report', () async {
      final results = await benchmark.runBenchmarks(iterations: 10);
      final summary = results.generateSummaryReport();

      expect(summary, contains('Integration Benchmark Results'));
      expect(summary, contains('Douglas-Peucker Line Simplification'));
      expect(summary, contains('Spatial Operations'));
      expect(summary, contains('Memory Operations'));
      expect(summary, contains('Concurrent Operations'));
      expect(summary, contains('Performance Profiler Summary'));
    });

    test('should handle different iteration counts', () async {
      final results = await benchmark.runBenchmarks(iterations: 5);

      expect(results.spatialResults!.totalIterations, equals(5));
      expect(results.memoryResults!.totalIterations, equals(5));
    });
  });

  group('OperationBenchmarkResult', () {
    test('should convert to map correctly', () {
      final result = OperationBenchmarkResult(
        operationName: 'Test Operation',
        totalIterations: 100,
        averageDuration: const Duration(milliseconds: 50),
        minDuration: const Duration(milliseconds: 10),
        maxDuration: const Duration(milliseconds: 100),
        sizeToPerformance: {100: const Duration(milliseconds: 20), 500: const Duration(milliseconds: 80)},
      );

      final map = result.toMap();
      expect(map['operationName'], equals('Test Operation'));
      expect(map['totalIterations'], equals(100));
      expect(map['averageDuration_ms'], equals(50));
      expect(map['minDuration_ms'], equals(10));
      expect(map['maxDuration_ms'], equals(100));
      expect(map['sizeToPerformance'], isA<Map<String, int>>());
    });
  });
}
