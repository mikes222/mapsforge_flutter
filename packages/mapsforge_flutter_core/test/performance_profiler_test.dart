import 'dart:async';

import 'package:test/test.dart';

import '../lib/src/utils/performance_profiler.dart';

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
      DefaultProfilerSession session = profiler.startSession(category: 'testing') as DefaultProfilerSession;
      expect(session.category, equals('testing'));
      //expect(session.duration.inMicroseconds, greaterThan(0));

      session.addMetadata('test_key', 'test_value');
      session.complete();

      final stats = profiler.getStats('testing', false);
      expect(stats.count, equals(1));
    });

    test('should record events directly', () {
      profiler.recordEvent(const Duration(milliseconds: 100), category: 'direct', metadata: {'type': 'test'});

      final stats = profiler.getStats('direct', false);
      expect(stats.count, equals(1));
      expect(stats.mean, equals(100));
    });

    test('should calculate statistics correctly', () {
      // Record multiple events with known durations
      final durations = [50, 100, 150, 200, 250]; // milliseconds
      for (final duration in durations) {
        profiler.recordEvent(Duration(milliseconds: duration), category: 'statistics');
      }

      final stats = profiler.getStats('statistics', false);
      expect(stats.count, equals(5));
      expect(stats.mean, equals(150)); // (50+100+150+200+250)/5
      expect(stats.median, equals(150));
      expect(stats.min, equals(50));
      expect(stats.max, equals(250));
    });

    test('should handle empty statistics', () {
      final stats = profiler.getStats('nonexistent', false);
      expect(stats.count, equals(0));
      expect(stats.mean, equals(0));
    });

    test('should track recent events', () {
      profiler.recordEvent(const Duration(milliseconds: 10), category: 'recent');
      profiler.recordEvent(const Duration(milliseconds: 20), category: 'recent');
      profiler.recordEvent(const Duration(milliseconds: 30), category: 'other');

      final allEvents = profiler.getRecentEvents();
      expect(allEvents.length, equals(3));

      final recentEvents = profiler.getRecentEvents(category: 'recent');
      expect(recentEvents.length, equals(2));

      final limitedEvents = profiler.getRecentEvents(limit: 1);
      expect(limitedEvents.length, equals(1));
    });

    test('should generate comprehensive reports', () {
      profiler.recordEvent(const Duration(milliseconds: 100), category: 'reporting');

      final report = profiler.generateReport(false);
      expect(report.enabled, isTrue);
      expect(report.categoryStats.containsKey('reporting'), isTrue);
      expect(report.totalEvents, greaterThan(0));
    });

    test('should handle enable/disable', () {
      profiler.setEnabled(false);

      ProfilerSession session = profiler.startSession();

      profiler.recordEvent(const Duration(milliseconds: 100));
      expect(profiler.getStats('default', false).count, equals(0));

      profiler.setEnabled(true);
    });

    test('should configure limits correctly', () {
      profiler.configure(maxRecentEvents: 2, maxMetricsPerCategory: 1);

      profiler.recordEvent(const Duration(milliseconds: 10), category: 'limits');
      profiler.recordEvent(const Duration(milliseconds: 20), category: 'limits');
      profiler.recordEvent(const Duration(milliseconds: 30), category: 'limits');

      final stats = profiler.getStats('limits', false);
      expect(stats.count, equals(1)); // Should only keep 1 metric per category

      final events = profiler.getRecentEvents();
      expect(events.length, lessThanOrEqualTo(2)); // Should only keep 2 recent events
    });

    test('should handle session checkpoints', () {
      DefaultProfilerSession session = profiler.startSession() as DefaultProfilerSession;

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
      final result = profiler.time(() {
        // Simulate work
        int sum = 0;
        for (int i = 0; i < 1000; i++) {
          sum += i;
        }
        return sum;
      }, category: 'sync');

      expect(result, equals(499500)); // Sum of 0 to 999

      final stats = profiler.getStats('sync', false);
      expect(stats.count, equals(1));
      //expect(stats.mean.inMicroseconds, greaterThan(0));
    });

    test('should time asynchronous functions', () async {
      final result = await profiler.timeAsync(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'completed';
      }, category: 'async');

      expect(result, equals('completed'));

      final stats = profiler.getStats('async', false);
      expect(stats.count, equals(1));
      expect(stats.mean, greaterThanOrEqualTo(10));
    });

    test('should handle exceptions in timed functions', () {
      expect(() {
        profiler.time(() {
          throw Exception('Test exception');
        });
      }, throwsException);

      // Should still record the timing even with exception
      final stats = profiler.getStats('timeSync', false);
      expect(stats.count, equals(1));
    });

    test('should handle exceptions in async timed functions', () async {
      await expectLater(
        profiler.timeAsync(() async {
          await Future.delayed(const Duration(milliseconds: 5));
          throw Exception('Async test exception');
        }),
        throwsException,
      );

      // Should still record the timing even with exception
      final stats = profiler.getStats('timeAsync', false);
      expect(stats.count, equals(1));
    });
  });

  group('PerformanceStats', () {
    test('should convert to map correctly', () {
      final stats = PerformanceStats(count: 5, sum: 500, mean: 100, median: 90, min: 50, max: 150, p95: 140, p99: 145, standardDeviation: 25);

      final map = stats.toMap();
      expect(map['count'], equals(5));
      expect(map['mean_ms'], equals(100));
      expect(map['p95_ms'], equals(140));
    });

    test('should create empty stats correctly', () {
      final empty = PerformanceStats.empty('empty_category');
      expect(empty.count, equals(0));
      expect(empty.mean, equals(0));
    });
  });

  group('PerformanceReport', () {
    test('should convert to map correctly', () {
      final stats = PerformanceStats.empty('test');
      final report = PerformanceReport(
        instance: "test",
        timestamp: DateTime.now(),
        categoryStats: {'test': stats},
        activeSessions: 2,
        totalEvents: 10,
        enabled: true,
      );

      final map = report.toMap();
      expect(map['enabled'], isTrue);
      expect(map['activeSessions'], equals(2));
      expect(map['totalEvents'], equals(10));
      expect(map['categoryStats'], isA<Map>());
    });

    test('should generate readable string representation', () {
      final stats = PerformanceStats.empty('test');
      final report = PerformanceReport(
        instance: "test",
        timestamp: DateTime.now(),
        categoryStats: {'test': stats},
        activeSessions: 1,
        totalEvents: 5,
        enabled: true,
      );

      final string = report.toString();
      expect(string, contains('Performance Report'));
      //expect(string, contains('Enabled: true'));
      expect(string, contains('Active Sessions: 1'));
    });
  });
}
