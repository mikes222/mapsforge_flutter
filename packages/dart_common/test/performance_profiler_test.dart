import 'dart:async';

import 'package:dart_common/src/performance_profiler.dart';
import 'package:test/test.dart';

void main() {
  group('PerformanceProfiler', () {
    late PerformanceProfiler profiler;

    setUp(() {
      profiler = PerformanceProfiler();
      profiler.clear();
      profiler.setEnabled(true);
    });

    tearDown(() {
      profiler.clear();
    });

    test('should be singleton', () {
      final profiler1 = PerformanceProfiler();
      final profiler2 = PerformanceProfiler();
      expect(identical(profiler1, profiler2), isTrue);
    });

    test('should start and complete sessions', () {
      final session = profiler.startSession('test_operation', category: 'testing');
      expect(session.name, equals('test_operation'));
      expect(session.category, equals('testing'));
      //expect(session.duration.inMicroseconds, greaterThan(0));

      session.addMetadata('test_key', 'test_value');
      session.complete();

      final stats = profiler.getStats('testing');
      expect(stats.count, equals(1));
    });

    test('should record events directly', () {
      profiler.recordEvent('direct_event', const Duration(milliseconds: 100), category: 'direct', metadata: {'type': 'test'});

      final stats = profiler.getStats('direct');
      expect(stats.count, equals(1));
      expect(stats.mean.inMilliseconds, equals(100));
    });

    test('should calculate statistics correctly', () {
      // Record multiple events with known durations
      final durations = [50, 100, 150, 200, 250]; // milliseconds
      for (final duration in durations) {
        profiler.recordEvent('stat_test', Duration(milliseconds: duration), category: 'statistics');
      }

      final stats = profiler.getStats('statistics');
      expect(stats.count, equals(5));
      expect(stats.mean.inMilliseconds, equals(150)); // (50+100+150+200+250)/5
      expect(stats.median.inMilliseconds, equals(150));
      expect(stats.min.inMilliseconds, equals(50));
      expect(stats.max.inMilliseconds, equals(250));
    });

    test('should handle empty statistics', () {
      final stats = profiler.getStats('nonexistent');
      expect(stats.count, equals(0));
      expect(stats.mean, equals(Duration.zero));
    });

    test('should track recent events', () {
      profiler.recordEvent('event1', const Duration(milliseconds: 10), category: 'recent');
      profiler.recordEvent('event2', const Duration(milliseconds: 20), category: 'recent');
      profiler.recordEvent('event3', const Duration(milliseconds: 30), category: 'other');

      final allEvents = profiler.getRecentEvents();
      expect(allEvents.length, equals(3));

      final recentEvents = profiler.getRecentEvents(category: 'recent');
      expect(recentEvents.length, equals(2));

      final limitedEvents = profiler.getRecentEvents(limit: 1);
      expect(limitedEvents.length, equals(1));
    });

    test('should generate comprehensive reports', () {
      profiler.recordEvent('report_test', const Duration(milliseconds: 100), category: 'reporting');

      final report = profiler.generateReport();
      expect(report.enabled, isTrue);
      expect(report.categoryStats.containsKey('reporting'), isTrue);
      expect(report.totalEvents, greaterThan(0));
    });

    test('should handle enable/disable', () {
      profiler.setEnabled(false);

      final session = profiler.startSession('disabled_test');
      expect(session.name, equals('noop')); // No-op session

      profiler.recordEvent('disabled_event', const Duration(milliseconds: 100));
      expect(profiler.getStats('default').count, equals(0));

      profiler.setEnabled(true);
    });

    test('should configure limits correctly', () {
      profiler.configure(maxRecentEvents: 2, maxMetricsPerCategory: 1);

      profiler.recordEvent('limit1', const Duration(milliseconds: 10), category: 'limits');
      profiler.recordEvent('limit2', const Duration(milliseconds: 20), category: 'limits');
      profiler.recordEvent('limit3', const Duration(milliseconds: 30), category: 'limits');

      final stats = profiler.getStats('limits');
      expect(stats.count, equals(1)); // Should only keep 1 metric per category

      final events = profiler.getRecentEvents();
      expect(events.length, lessThanOrEqualTo(2)); // Should only keep 2 recent events
    });

    test('should handle session checkpoints', () {
      final session = profiler.startSession('checkpoint_test');

      // Simulate some work
      Future.delayed(const Duration(milliseconds: 10));
      session.checkpoint('middle');

      Future.delayed(const Duration(milliseconds: 10));
      session.checkpoint('end');

      session.complete();

      expect(session.metadata.containsKey('checkpoint_middle'), isTrue);
      expect(session.metadata.containsKey('checkpoint_end'), isTrue);
    });

    test('should provide configuration info', () {
      final config = profiler.getConfiguration();

      expect(config, containsPair('enabled', isA<bool>()));
      expect(config, containsPair('maxRecentEvents', isA<int>()));
      expect(config, containsPair('maxMetricsPerCategory', isA<int>()));
      expect(config, containsPair('activeSessions', isA<int>()));
      expect(config, containsPair('categories', isA<int>()));
      expect(config, containsPair('totalEvents', isA<int>()));
    });
  });

  group('PerformanceProfiler Extensions', () {
    late PerformanceProfiler profiler;

    setUp(() {
      profiler = PerformanceProfiler();
      profiler.clear();
      profiler.setEnabled(true);
    });

    test('should time synchronous functions', () {
      final result = profiler.time('sync_test', () {
        // Simulate work
        int sum = 0;
        for (int i = 0; i < 1000; i++) {
          sum += i;
        }
        return sum;
      }, category: 'sync');

      expect(result, equals(499500)); // Sum of 0 to 999

      final stats = profiler.getStats('sync');
      expect(stats.count, equals(1));
      //expect(stats.mean.inMicroseconds, greaterThan(0));
    });

    test('should time asynchronous functions', () async {
      final result = await profiler.timeAsync('async_test', () async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'completed';
      }, category: 'async');

      expect(result, equals('completed'));

      final stats = profiler.getStats('async');
      expect(stats.count, equals(1));
      expect(stats.mean.inMilliseconds, greaterThanOrEqualTo(10));
    });

    test('should handle exceptions in timed functions', () {
      expect(() {
        profiler.time('exception_test', () {
          throw Exception('Test exception');
        });
      }, throwsException);

      // Should still record the timing even with exception
      final stats = profiler.getStats('default');
      expect(stats.count, equals(1));
    });

    test('should handle exceptions in async timed functions', () async {
      await expectLater(
        profiler.timeAsync('async_exception_test', () async {
          await Future.delayed(const Duration(milliseconds: 5));
          throw Exception('Async test exception');
        }),
        throwsException,
      );

      // Should still record the timing even with exception
      final stats = profiler.getStats('default');
      expect(stats.count, equals(1));
    });
  });

  group('PerformanceStats', () {
    test('should convert to map correctly', () {
      final stats = PerformanceStats(
        category: 'test',
        count: 5,
        mean: const Duration(milliseconds: 100),
        median: const Duration(milliseconds: 90),
        min: const Duration(milliseconds: 50),
        max: const Duration(milliseconds: 150),
        p95: const Duration(milliseconds: 140),
        p99: const Duration(milliseconds: 145),
        standardDeviation: const Duration(milliseconds: 25),
      );

      final map = stats.toMap();
      expect(map['category'], equals('test'));
      expect(map['count'], equals(5));
      expect(map['mean_ms'], equals(100));
      expect(map['p95_ms'], equals(140));
    });

    test('should create empty stats correctly', () {
      final empty = PerformanceStats.empty('empty_category');
      expect(empty.category, equals('empty_category'));
      expect(empty.count, equals(0));
      expect(empty.mean, equals(Duration.zero));
    });
  });

  group('PerformanceReport', () {
    test('should convert to map correctly', () {
      final stats = PerformanceStats.empty('test');
      final report = PerformanceReport(timestamp: DateTime.now(), categoryStats: {'test': stats}, activeSessions: 2, totalEvents: 10, enabled: true);

      final map = report.toMap();
      expect(map['enabled'], isTrue);
      expect(map['activeSessions'], equals(2));
      expect(map['totalEvents'], equals(10));
      expect(map['categoryStats'], isA<Map>());
    });

    test('should generate readable string representation', () {
      final stats = PerformanceStats.empty('test');
      final report = PerformanceReport(timestamp: DateTime.now(), categoryStats: {'test': stats}, activeSessions: 1, totalEvents: 5, enabled: true);

      final string = report.toString();
      expect(string, contains('Performance Report'));
      expect(string, contains('Enabled: true'));
      expect(string, contains('Active Sessions: 1'));
    });
  });
}
