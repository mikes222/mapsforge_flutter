import 'package:mapsforge_flutter_core/src/utils/performance_profiler.dart';
import 'package:test/test.dart';

import 'integration_benchmark.dart';

void main() {
  group('IntegrationBenchmark', () {
    setUp(() {
      PerformanceProfiler().setEnabled(true);
    });

    test('should run comprehensive benchmarks', () async {
      IntegrationBenchmark benchmark = IntegrationBenchmark();
      await benchmark.runBenchmarks(iterations: 100);
    });
  });
}
