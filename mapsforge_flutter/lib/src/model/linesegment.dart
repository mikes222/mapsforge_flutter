import 'dart:math';

import 'mappoint.dart';

/**
 * A directed line segment between two Points.
 */
class LineSegment {
  static int INSIDE = 0; // 0000
  static int LEFT = 1; // 0001
  static int RIGHT = 2; // 0010
  static int BOTTOM = 4; // 0100
  static int TOP = 8; // 1000

  final Mappoint start;
  final Mappoint end;

  double? _angle;

  double? _theta;

  double? _length;

  /**
   * Ctor with given start and end point
   *
   * @param start start point
   * @param end   end point
   */
  LineSegment(this.start, this.end);

  /**
   * Ctor with given start point, a point that defines the direction of the line and a length
   *
   * @param start     start point
   * @param direction point that defines the direction (a line from start to direction point)
   * @param distance  how long to move along the line between start and direction
   */
  LineSegment.direction(this.start, Mappoint direction, double distance)
      : end = new LineSegment(start, direction).pointAlongLineSegment(distance);

  /// Returns the degree of this segment. 0 means vector to the right side -->
  /// Since positive values in y-direction points towards the bottom of the screen
  /// the angle runs clockwise.
  double getAngle() {
    if (_angle != null) return _angle!;
    _angle = atan2(this.end.y - this.start.y, this.end.x - this.start.x);
    _angle = toDegrees(_angle!);
    return _angle!;
  }

  /// Returns the theta of this segment in radians. 0 means vector to the right side -->
  /// Since positive values in y-direction points towards the bottom of the screen
  /// the angle runs clockwise.
  /// see https://de.wikipedia.org/wiki/Arkustangens_und_Arkuskotangens#/media/Datei:Arctangent.svg
  double getTheta() {
    if (_theta != null) return _theta!;
    if (end == start) return 0;
    _theta = end.x != start.x
        ? atan((end.y - start.y) / (end.x - start.x))
        : end.y > end.x
            ? pi / 2
            : -pi / 2;
    return _theta!;
  }

  /**
   * Computes the angle between this LineSegment and another one.
   *
   * @param other the other LineSegment
   * @return angle in degrees
   */
  double angleTo(LineSegment other) {
    double angle1 = getTheta();
    double angle2 = other.getTheta();
    double angle = toDegrees(angle1 - angle2);
    return angle;
  }

  /// Returns the degree given by the radian value
  double toDegrees(double var0) {
    double result = var0 * 180.0 / pi;
    if (result < 0) result += 360;
    return result;
  }

  /**
   * Intersection of this LineSegment with the Rectangle as another LineSegment.
   * <p/>
   * Algorithm is Cohen-Sutherland, see https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm .
   *
   * @param r the rectangle to clip to.
   * @return the LineSegment that falls into the Rectangle, null if there is no intersection.
   */
  LineSegment? clipToRectangle(Rectangle r) {
    Mappoint a = this.start;
    Mappoint b = this.end;

    int codeStart = code(r, a);
    int codeEnd = code(r, b);

    while (true) {
      if (0 == (codeStart | codeEnd)) {
// both points are inside, intersection is the computed line
        return new LineSegment(a, b);
      } else if (0 != (codeStart & codeEnd)) {
// both points are either below, above, left or right of the box, no intersection
        return null;
      } else {
        double newX;
        double newY;
// At least one endpoint is outside the clip rectangle; pick it.
        int outsideCode = (0 != codeStart) ? codeStart : codeEnd;

        if (0 != (outsideCode & TOP)) {
// point is above the clip rectangle
          newX = a.x + (b.x - a.x) * (r.top - a.y) / (b.y - a.y);
          newY = r.top as double;
        } else if (0 != (outsideCode & BOTTOM)) {
// point is below the clip rectangle
          newX = a.x + (b.x - a.x) * (r.bottom - a.y) / (b.y - a.y);
          newY = r.bottom as double;
        } else if (0 != (outsideCode & RIGHT)) {
// point is to the right of clip rectangle
          newY = a.y + (b.y - a.y) * (r.right - a.x) / (b.x - a.x);
          newX = r.right as double;
        } else if (0 != (outsideCode & LEFT)) {
// point is to the left of clip rectangle
          newY = a.y + (b.y - a.y) * (r.left - a.x) / (b.x - a.x);
          newX = r.left as double;
        } else {
          throw new Exception("Should not get here");
        }
// Now we move outside point to intersection point to clip
// and get ready for next pass.
        if (outsideCode == codeStart) {
          a = new Mappoint(newX, newY);
          codeStart = code(r, a);
        } else {
          b = new Mappoint(newX, newY);
          codeEnd = code(r, b);
        }
      }
    }
  }

  /**
   * Returns a fast computation if the line intersects the rectangle or bias if there
   * is no fast way to compute the intersection.
   *
   * @param r    retangle to test
   * @param bias the result if no fast computation is possible
   * @return either the fast and correct result or the bias (which might be wrong).
   */

  bool intersectsRectangle(Rectangle r, bool bias) {
    int codeStart = code(r, this.start);
    int codeEnd = code(r, this.end);

    if (0 == (codeStart | codeEnd)) {
// both points are inside, trivial case
      return true;
    } else if (0 != (codeStart & codeEnd)) {
// both points are either below, above, left or right of the box, no intersection
      return false;
    }
    return bias;
  }

  /**
   * Euclidian distance between start and end.
   *
   * @return the length of the segment.
   */
  double length() {
    if (_length != null) return _length!;
    _length = start.distance(end);
    return _length!;
  }

  /**
   * Computes a Point along the line segment with a given distance to the start Point.
   *
   * @param distance distance from start point
   * @return point at given distance from start point
   */
  Mappoint pointAlongLineSegment(double distance) {
    if (start.x == end.x) {
// we have a vertical line
      if (start.y > end.y) {
        return new Mappoint(start.x, start.y - distance);
      } else {
        return new Mappoint(start.x, start.y + distance);
      }
    } else {
      double slope = (end.y - start.y) / (end.x - start.x);
      double fraction = distance / length();
      double dx = (end.x - start.x) * fraction;
      return new Mappoint(start.x + dx, start.y + slope * dx);
    }
  }

  /**
   * New line segment with start and end reversed.
   *
   * @return new LineSegment with start and end reversed
   */
  LineSegment reverse() {
    return new LineSegment(this.end, this.start);
  }

  /**
   * LineSegment that starts at offset from start and runs for length towards end point
   *
   * @param offset offset applied at begin of line
   * @param length length of the new segment
   * @return new LineSegment computed
   */
  LineSegment subSegment(double offset, double length) {
    Mappoint subSegmentStart = pointAlongLineSegment(offset);
    Mappoint subSegmentEnd = pointAlongLineSegment(offset + length);
    return new LineSegment(subSegmentStart, subSegmentEnd);
  }

  /**
   * Computes the location code according to Cohen-Sutherland,
   * see https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm.
   */
  static int code(Rectangle r, Mappoint p) {
    int code = INSIDE;
    if (p.x < r.left) {
// to the left of clip window
      code |= LEFT;
    } else if (p.x > r.right) {
// to the right of clip window
      code |= RIGHT;
    }

    if (p.y > r.bottom) {
// below the clip window
      code |= BOTTOM;
    } else if (p.y < r.top) {
// above the clip window
      code |= TOP;
    }
    return code;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineSegment &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() {
    return 'LineSegment{start: $start, end: $end}';
  }
}
