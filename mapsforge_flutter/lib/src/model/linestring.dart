import 'dart:math';

import 'maprectangle.dart';

import 'linesegment.dart';
import 'mappoint.dart';

class LineString {
  final List<LineSegment> segments = [];

  MapRectangle? _bounds;

  /**
   * Creates a new LineString that consists of only the part between startDistance and endDistance.
   */
  LineString extractPart(double startDistance, double endDistance) {
    LineString result = new LineString();

    for (int i = 0;
        i < this.segments.length;
        startDistance -= this.segments.elementAt(i).length(),
        endDistance -= this.segments.elementAt(i).length(),
        i++) {
      LineSegment segment = this.segments.elementAt(i);

      // Skip first segments that we don't need
      double length = segment.length();
      if (length < startDistance) {
        continue;
      }

      Mappoint? startPoint, endPoint;
      if (startDistance >= 0) {
        // This will be our starting point
        startPoint = segment.pointAlongLineSegment(startDistance);
      }
      if (endDistance < length) {
        // this will be our ending point
        endPoint = segment.pointAlongLineSegment(endDistance);
      }

      if (startPoint != null && endPoint == null) {
        // This ist the starting segment, end will come in a later segment
        result.segments.add(new LineSegment(startPoint, segment.end));
      } else if (startPoint == null && endPoint == null) {
        // Center segment between start and end segment, add completely
        result.segments.add(segment);
      } else if (startPoint == null && endPoint != null) {
        // End segment, start was in earlier segment
        result.segments.add(new LineSegment(segment.start, endPoint));
      } else if (startPoint != null && endPoint != null) {
        // Start and end on same segment
        result.segments.add(new LineSegment(startPoint, endPoint));
      }

      if (endPoint != null) break;
    }

    return result;
  }

  MapRectangle getBounds() {
    if (_bounds != null) return _bounds!;

    double minX = double.maxFinite;
    double minY = double.maxFinite;
    double maxX = double.minPositive;
    double maxY = double.minPositive;

    for (LineSegment segment in this.segments) {
      minX = min(minX, min(segment.start.x, segment.end.x));
      minY = min(minY, min(segment.start.y, segment.end.y));
      maxX = max(maxX, max(segment.start.x, segment.end.x));
      maxY = max(maxY, max(segment.start.y, segment.end.y));
    }
    _bounds = MapRectangle(minX, minY, maxX, maxY);
    return _bounds!;
  }

  /**
   * Interpolates on the segment and returns the coordinate of the interpolation result.
   * Returns null if distance is < 0 or > length().
   */
  Mappoint? interpolate(double distance) {
    if (distance < 0) {
      return null;
    }

    for (LineSegment segment in this.segments) {
      double length = segment.length();
      if (distance <= length) {
        return segment.pointAlongLineSegment(distance);
      }
      distance -= length;
    }
    return null;
  }

  double length() {
    double result = 0;
    for (LineSegment segment in this.segments) {
      result += segment.length();
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineString &&
          runtimeType == other.runtimeType &&
          segments == other.segments;

  @override
  int get hashCode => segments.hashCode;
}
