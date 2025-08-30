import 'dart:async';

import 'package:mapsforge_flutter/src/util/memory_pressure_monitor.dart';
import 'package:test/test.dart';

void main() {
  group('MemoryPressureMonitor', () {
    late MemoryPressureMonitor monitor;

    setUp(() {
      monitor = MemoryPressureMonitor(monitoringInterval: const Duration(milliseconds: 100));
    });

    tearDown(() {
      monitor.dispose();
    });

    test('should initialize with normal pressure level', () {
      expect(monitor.currentPressureLevel, equals(MemoryPressureLevel.normal));
      expect(monitor.memoryPressure, greaterThanOrEqualTo(0.0));
      expect(monitor.memoryPressure, lessThanOrEqualTo(1.0));
    });

    test('should start and stop monitoring', () {
      expect(() => monitor.startMonitoring(), returnsNormally);
      expect(() => monitor.stopMonitoring(), returnsNormally);
    });

    test('should provide memory statistics', () {
      final stats = monitor.memoryStatistics;

      expect(stats.totalSystemMemory, isA<int>());
      expect(stats.availableMemory, isA<int>());
      expect(stats.usedMemory, isA<int>());
      expect(stats.memoryPressure, isA<double>());
      expect(stats.monitoringCycles, isA<int>());
      expect(stats.lastCriticalPressure, isA<DateTime?>());
    });

    test('should handle pressure callbacks', () async {
      bool callbackCalled = false;
      MemoryPressureLevel? receivedLevel;

      monitor.addPressureCallback((level) {
        callbackCalled = true;
        receivedLevel = level;
      });

      monitor.startMonitoring();
      await Future.delayed(const Duration(milliseconds: 200));

      // Force a check to ensure callback system works
      monitor.forceCheck();

      // Remove callback
      monitor.removePressureCallback((level) {
        callbackCalled = true;
        receivedLevel = level;
      });
    });

    test('should force memory check', () {
      expect(() => monitor.forceCheck(), returnsNormally);

      final stats = monitor.memoryStatistics;
      expect(stats.memoryPressure, isA<double>());
    });

    test('should handle disposal correctly', () {
      monitor.startMonitoring();
      expect(() => monitor.dispose(), returnsNormally);

      // Should not throw after disposal
      expect(() => monitor.memoryStatistics, returnsNormally);
    });
  });
}
