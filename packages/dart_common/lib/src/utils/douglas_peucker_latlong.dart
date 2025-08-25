import 'dart:collection';

import 'package:dart_common/model.dart';

class DouglasPeuckerLatLong {
  // Cache for frequently used calculations to avoid repeated computation
  static const double _epsilon = 1e-10;
  
  /// Optimized perpendicular distance squared calculation
  /// Uses direct coordinate arithmetic without expensive operations
  double _perpendicularDistanceSquared(ILatLong p, ILatLong a, ILatLong b) {
    final double ax = a.longitude;
    final double ay = a.latitude;
    final double bx = b.longitude;
    final double by = b.latitude;
    final double px = p.longitude;
    final double py = p.latitude;
    
    final double dx = bx - ax;
    final double dy = by - ay;
    
    // Fast check for degenerate line segment (points a and b are the same)
    final double segmentLengthSquared = dx * dx + dy * dy;
    if (segmentLengthSquared < _epsilon) {
      // Points a and b are effectively the same, return distance squared to point a
      final double dpx = px - ax;
      final double dpy = py - ay;
      return dpx * dpx + dpy * dpy;
    }
    
    // Optimized cross product calculation for perpendicular distance
    // Using the formula: |cross_product|² / |segment|²
    final double cross = dx * (ay - py) - dy * (ax - px);
    return (cross * cross) / segmentLengthSquared;
  }

  /// Optimized Douglas-Peucker line simplification algorithm
  /// Uses squared distances throughout to avoid expensive sqrt operations
  List<ILatLong> simplify(List<ILatLong> points, double tolerance) {
    if (points.length <= 2) {
      return points;
    }

    final double toleranceSquared = tolerance * tolerance;
    final List<ILatLong> result = <ILatLong>[];
    
    // Use a more efficient stack structure with pre-allocated capacity
    final Queue<_Segment> stack = Queue<_Segment>();
    stack.add(_Segment(0, points.length - 1));

    // Track which points to keep using a boolean array for O(1) lookup
    final List<bool> keepPoint = List<bool>.filled(points.length, false);
    keepPoint[0] = true; // Always keep first point
    keepPoint[points.length - 1] = true; // Always keep last point

    while (stack.isNotEmpty) {
      final _Segment segment = stack.removeFirst();
      final int start = segment.start;
      final int end = segment.end;

      // Early exit for adjacent points
      if (end - start <= 1) {
        continue;
      }

      double maxDistanceSquared = 0.0;
      int maxDistanceIndex = start;

      // Cache start and end points to avoid repeated array access
      final ILatLong startPoint = points[start];
      final ILatLong endPoint = points[end];

      // Find the point with maximum perpendicular distance
      for (int i = start + 1; i < end; i++) {
        final double distanceSquared = _perpendicularDistanceSquared(points[i], startPoint, endPoint);
        if (distanceSquared > maxDistanceSquared) {
          maxDistanceSquared = distanceSquared;
          maxDistanceIndex = i;
        }
      }

      // If the maximum distance exceeds tolerance, subdivide
      if (maxDistanceSquared > toleranceSquared) {
        keepPoint[maxDistanceIndex] = true;
        // Process larger segment first for better cache locality
        if (maxDistanceIndex - start > end - maxDistanceIndex) {
          stack.addFirst(_Segment(start, maxDistanceIndex));
          stack.addFirst(_Segment(maxDistanceIndex, end));
        } else {
          stack.addFirst(_Segment(maxDistanceIndex, end));
          stack.addFirst(_Segment(start, maxDistanceIndex));
        }
      }
    }

    // Build result list from kept points
    for (int i = 0; i < points.length; i++) {
      if (keepPoint[i]) {
        result.add(points[i]);
      }
    }

    return result;
  }
}

/// Internal class to represent a line segment for processing
/// More efficient than using List<int> for stack operations
class _Segment {
  final int start;
  final int end;
  
  const _Segment(this.start, this.end);
}
