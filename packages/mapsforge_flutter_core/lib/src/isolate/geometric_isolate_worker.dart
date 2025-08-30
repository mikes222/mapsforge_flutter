import 'dart:collection';
import 'dart:isolate';

import 'package:mapsforge_flutter_core/model.dart';

/// Isolate worker for CPU-intensive geometric calculations
/// Handles Douglas-Peucker line simplification in separate isolate
class GeometricIsolateWorker {
  static const int _minPointsForIsolate = 1000; // Threshold for using isolate

  /// Simplify points using Douglas-Peucker algorithm
  /// Automatically decides whether to use isolate based on point count
  static Future<List<Mappoint>> simplifyPoints(List<Mappoint> points, double tolerance) async {
    if (points.length < _minPointsForIsolate) {
      // Use main thread for small datasets
      return _douglasPeuckerSync(points, tolerance);
    }

    // Use isolate for large datasets
    return _douglasPeuckerIsolate(points, tolerance);
  }

  /// Synchronous Douglas-Peucker for small datasets
  static List<Mappoint> _douglasPeuckerSync(List<Mappoint> points, double tolerance) {
    if (points.length <= 2) return points;

    final toleranceSquared = tolerance * tolerance;
    final result = <Mappoint>[];
    final stack = Queue<_Segment>();

    stack.add(_Segment(0, points.length - 1));

    while (stack.isNotEmpty) {
      final segment = stack.removeFirst();
      final start = segment.start;
      final end = segment.end;

      double maxDistanceSquared = 0.0;
      int maxDistanceIndex = start;

      for (int i = start + 1; i < end; i++) {
        final distanceSquared = _perpendicularDistanceSquared(points[i], points[start], points[end]);
        if (distanceSquared > maxDistanceSquared) {
          maxDistanceSquared = distanceSquared;
          maxDistanceIndex = i;
        }
      }

      if (maxDistanceSquared > toleranceSquared) {
        stack.addFirst(_Segment(maxDistanceIndex, end));
        stack.addFirst(_Segment(start, maxDistanceIndex));
      } else {
        if (result.isEmpty) result.add(points[start]);
        result.add(points[end]);
      }
    }

    return result;
  }

  /// Asynchronous Douglas-Peucker using isolate for large datasets
  static Future<List<Mappoint>> _douglasPeuckerIsolate(List<Mappoint> points, double tolerance) async {
    final receivePort = ReceivePort();

    try {
      // Spawn isolate with entry point
      await Isolate.spawn(_isolateEntryPoint, _IsolateMessage(sendPort: receivePort.sendPort, points: points, tolerance: tolerance));

      // Wait for result from isolate
      final result = await receivePort.first as List<Mappoint>;
      return result;
    } finally {
      receivePort.close();
    }
  }

  /// Entry point for isolate execution
  static void _isolateEntryPoint(_IsolateMessage message) {
    final result = _douglasPeuckerSync(message.points, message.tolerance);
    message.sendPort.send(result);
  }

  /// Calculate squared perpendicular distance from point p to line segment ab
  static double _perpendicularDistanceSquared(Mappoint p, Mappoint a, Mappoint b) {
    if (a.x == b.x && a.y == b.y) {
      final dx = p.x - a.x;
      final dy = p.y - a.y;
      return dx * dx + dy * dy;
    }

    final area = (b.x - a.x) * (a.y - p.y) - (a.x - p.x) * (b.y - a.y);
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final abDistSquared = dx * dx + dy * dy;

    return (area * area) / abDistSquared;
  }
}

/// Message structure for isolate communication
class _IsolateMessage {
  final SendPort sendPort;
  final List<Mappoint> points;
  final double tolerance;

  const _IsolateMessage({required this.sendPort, required this.points, required this.tolerance});
}

/// Internal segment representation
class _Segment {
  final int start;
  final int end;

  const _Segment(this.start, this.end);
}
