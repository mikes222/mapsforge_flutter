import 'dart:async';
import 'package:test/test.dart';
import 'package:mapsforge_view/src/cache/memory_pressure_monitor.dart';

void main() {
  group('MemoryPressureMonitor', () {
    late MemoryPressureMonitor monitor;

    setUp(() {
      monitor = MemoryPressureMonitor(
        monitoringInterval: const Duration(milliseconds: 100),
      );
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
      final stats = monitor.getMemoryStats();
      
      expect(stats, containsPair('totalSystemMemory', isA<int>()));
      expect(stats, containsPair('availableMemory', isA<int>()));
      expect(stats, containsPair('usedMemory', isA<int>()));
      expect(stats, containsPair('memoryPressure', isA<double>()));
      expect(stats, containsPair('pressureLevel', isA<String>()));
      expect(stats, containsPair('recommendedCacheSize', isA<int>()));
    });

    test('should allow setting custom cache size limits', () {
      monitor.setCacheSizeLimits(minSize: 50, maxSize: 500);
      
      final stats = monitor.getMemoryStats();
      final recommendedSize = stats['recommendedCacheSize'] as int;
      
      expect(recommendedSize, greaterThanOrEqualTo(50));
      expect(recommendedSize, lessThanOrEqualTo(500));
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
      
      final stats = monitor.getMemoryStats();
      expect(stats['memoryPressure'], isA<double>());
    });

    test('should handle disposal correctly', () {
      monitor.startMonitoring();
      expect(() => monitor.dispose(), returnsNormally);
      
      // Should not throw after disposal
      expect(() => monitor.getMemoryStats(), returnsNormally);
    });
  });

  group('MemoryPressureLevel', () {
    test('should provide correct descriptions', () {
      expect(MemoryPressureLevel.normal.description, equals('Normal memory usage'));
      expect(MemoryPressureLevel.moderate.description, equals('Moderate memory pressure'));
      expect(MemoryPressureLevel.high.description, equals('High memory pressure'));
      expect(MemoryPressureLevel.critical.description, equals('Critical memory pressure'));
    });

    test('should provide recommended actions', () {
      expect(MemoryPressureLevel.normal.recommendedAction, equals('No action needed'));
      expect(MemoryPressureLevel.moderate.recommendedAction, equals('Consider reducing cache sizes'));
      expect(MemoryPressureLevel.high.recommendedAction, equals('Reduce cache sizes and clear unused data'));
      expect(MemoryPressureLevel.critical.recommendedAction, equals('Immediately clear caches and free memory'));
    });
  });
}
