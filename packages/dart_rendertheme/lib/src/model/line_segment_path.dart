import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:dart_rendertheme/src/model/line_segment.dart';

/// A list of Linesegments which consists of segments in screen-pixels.
class LineSegmentPath {
  static final double MAX_LABEL_CORNER_ANGLE = 10;

  final List<LineSegment> segments = [];

  MapRectangle? _bounds;

  /// Creates a new LineString that consists of only the part between startDistance and endDistance.
  LineSegmentPath extractPart(double startDistance, double endDistance) {
    LineSegmentPath result = LineSegmentPath();

    for (int i = 0; i < segments.length; startDistance -= segments.elementAt(i).length(), endDistance -= segments.elementAt(i).length(), i++) {
      LineSegment segment = segments.elementAt(i);

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
        result.segments.add(LineSegment(startPoint, segment.end));
      } else if (startPoint == null && endPoint == null) {
        // Center segment between start and end segment, add completely
        result.segments.add(segment);
      } else if (startPoint == null && endPoint != null) {
        // End segment, start was in earlier segment
        result.segments.add(LineSegment(segment.start, endPoint));
      } else if (startPoint != null && endPoint != null) {
        // Start and end on same segment
        result.segments.add(LineSegment(startPoint, endPoint));
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

    for (LineSegment segment in segments) {
      minX = min(minX, min(segment.start.x, segment.end.x));
      minY = min(minY, min(segment.start.y, segment.end.y));
      maxX = max(maxX, max(segment.start.x, segment.end.x));
      maxY = max(maxY, max(segment.start.y, segment.end.y));
    }
    _bounds = MapRectangle(minX, minY, maxX, maxY);
    return _bounds!;
  }

  /// Interpolates on the segment and returns the coordinate of the interpolation result.
  /// Returns null if distance is < 0 or > length().
  Mappoint? interpolate(double distance) {
    if (distance < 0) {
      return null;
    }

    for (LineSegment segment in segments) {
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
    for (LineSegment segment in segments) {
      result += segment.length();
    }
    return result;
  }

  LineSegmentPath reducePathForText(double textWidth, double repeatStart, double repeatGap) {
    LineSegmentPath result = LineSegmentPath();
    LineSegmentPath path = LineSegmentPath();
    LineSegmentPath longestPath = LineSegmentPath();
    double preLength = repeatStart;
    for (LineSegment segment in segments) {
      if (path.length() > preLength + textWidth && path.segments.first.start != path.segments.last.end) {
        // the length of all previous tiny paths is in sum long enough to fit the text
        result.segments.add(LineSegment(path.segments.first.start, path.segments.last.end));
        path = LineSegmentPath();
      }
      while (segment.length() >= preLength + textWidth) {
        // we found a segment which is long enough
        result.segments.add(segment.subSegment(preLength, textWidth));
        segment = segment.subSegment(preLength + textWidth);
        preLength = repeatGap;
        // ignore the tiny paths from previous iterations
        path.segments.clear();
      }
      if (segment.length() > 10) {
        if (path.segments.isEmpty || path.segments.last.angleTo(segment).abs() < MAX_LABEL_CORNER_ANGLE) {
          // the angle to the last segment is small enough to be part of the same path
          path.segments.add(segment);
        } else {
          path.segments.clear();
          if (longestPath.length() < path.length()) longestPath = path;
        }
      }
    }
    if (result.segments.isEmpty && longestPath.segments.isNotEmpty && longestPath.length() > textWidth * 2 / 3) {
      // we do not have a sufficient length for the text but the remaining path is 2/3 of what we need so use it
      if (longestPath.segments.first.start != longestPath.segments.last.end) {
        result.segments.add(LineSegment(longestPath.segments.first.start, longestPath.segments.last.end));
      }
    }
    return result;
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is LineSegmentPath && runtimeType == other.runtimeType && segments == other.segments;

  @override
  int get hashCode => segments.hashCode;
}
