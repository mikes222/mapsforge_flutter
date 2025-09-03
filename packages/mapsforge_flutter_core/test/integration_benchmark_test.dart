import 'package:test/test.dart';

import 'integration_benchmark.dart';

void main() {
  group('IntegrationBenchmark', () {
    setUp(() {});

    test('should run comprehensive benchmarks', () async {
      IntegrationBenchmark benchmark = IntegrationBenchmark();
      await benchmark.runBenchmarks(iterations: 100);
    });
  });
}
