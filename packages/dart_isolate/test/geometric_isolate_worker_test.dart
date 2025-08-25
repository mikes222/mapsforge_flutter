import 'dart:math';
import 'package:test/test.dart';
import 'package:dart_common/model.dart';
import 'package:dart_isolate/dart_isolate.dart';

void main() {
  group('GeometricIsolateWorker', () {
    test('should simplify small point sets synchronously', () async {
      final points = _generateTestPoints(100);
      final tolerance = 0.1;
      
      final result = await GeometricIsolateWorker.simplifyPoints(points, tolerance);
      
      expect(result.length, lessThan(points.length));
      expect(result.first, equals(points.first));
      expect(result.last, equals(points.last));
    });
    
    test('should simplify large point sets using isolate', () async {
      final points = _generateTestPoints(2000);
      final tolerance = 0.1;
      
      final stopwatch = Stopwatch()..start();
      final result = await GeometricIsolateWorker.simplifyPoints(points, tolerance);
      stopwatch.stop();
      
      expect(result.length, lessThan(points.length));
      expect(result.first, equals(points.first));
      expect(result.last, equals(points.last));
      
      print('Isolate simplification of ${points.length} points took ${stopwatch.elapsedMilliseconds}ms');
    });
    
    test('should handle edge cases correctly', () async {
      // Empty list
      expect(await GeometricIsolateWorker.simplifyPoints([], 0.1), isEmpty);
      
      // Single point
      final singlePoint = [Mappoint(0, 0)];
      expect(await GeometricIsolateWorker.simplifyPoints(singlePoint, 0.1), equals(singlePoint));
      
      // Two points
      final twoPoints = [Mappoint(0, 0), Mappoint(1, 1)];
      expect(await GeometricIsolateWorker.simplifyPoints(twoPoints, 0.1), equals(twoPoints));
    });
    
    test('should preserve endpoint accuracy', () async {
      final points = _generateSineWavePoints(1500);
      final tolerance = 0.05;
      
      final result = await GeometricIsolateWorker.simplifyPoints(points, tolerance);
      
      expect(result.first.x, closeTo(points.first.x, 1e-10));
      expect(result.first.y, closeTo(points.first.y, 1e-10));
      expect(result.last.x, closeTo(points.last.x, 1e-10));
      expect(result.last.y, closeTo(points.last.y, 1e-10));
    });
    
    test('should handle different tolerance values', () async {
      final points = _generateTestPoints(1200);
      
      final strictResult = await GeometricIsolateWorker.simplifyPoints(points, 0.01);
      final looseResult = await GeometricIsolateWorker.simplifyPoints(points, 0.5);
      
      expect(strictResult.length, greaterThan(looseResult.length));
    });
    
    test('should maintain point ordering', () async {
      final points = _generateTestPoints(1100);
      final result = await GeometricIsolateWorker.simplifyPoints(points, 0.1);
      
      for (int i = 1; i < result.length; i++) {
        expect(result[i].x, greaterThanOrEqualTo(result[i - 1].x));
      }
    });
  });
}

/// Generate test points in a line with some noise
List<Mappoint> _generateTestPoints(int count) {
  final points = <Mappoint>[];
  final random = Random(42); // Fixed seed for reproducible tests
  
  for (int i = 0; i < count; i++) {
    final x = i.toDouble();
    final y = x + (random.nextDouble() - 0.5) * 0.2; // Add small noise
    points.add(Mappoint(x, y));
  }
  
  return points;
}

/// Generate points following a sine wave pattern
List<Mappoint> _generateSineWavePoints(int count) {
  final points = <Mappoint>[];
  
  for (int i = 0; i < count; i++) {
    final x = i * 0.1;
    final y = sin(x) + sin(x * 3) * 0.3; // Complex sine wave
    points.add(Mappoint(x, y));
  }
  
  return points;
}
