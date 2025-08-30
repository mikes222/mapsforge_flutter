import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';

/// A Point represents an immutable pair of absolute double coordinates in map pixels. 0/0 represents the
/// upper-left corner of the complete map (=lat/lon 90/-180).
class Mappoint {
  /// The x coordinate of this point in pixels. Positive values points towards
  /// the right side of the screen.
  final double x;

  /// The y coordinate of this point in pixels. Positive values points to
  /// the bottom of the screen.
  final double y;

  /// @param x the x coordinate of this point.
  /// @param y the y coordinate of this point.
  const Mappoint(this.x, this.y);

  /// @return the euclidian distance from this point to the given point.
  double distance(Mappoint point) {
    return sqrt((x - point.x) * (x - point.x) + (y - point.y) * (y - point.y));
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Mappoint && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Mappoint offsetAbsolute(double dx, double dy) {
    if (0 == dx && 0 == dy) {
      return this;
    }
    return Mappoint(x + dx, y + dy);
  }

  /// Returns a mappoint which represents a relative offset in map-coordinates
  MappointRelative offset(Mappoint reference) {
    return MappointRelative(x - reference.x, y - reference.y);
  }

  /// Returns the radians to the other object.
  /// 0 rad if point2 is to the right of point1
  // π/2 rad if point2 is above point1
  // -π/2 rad if point2 is below point1
  // π rad if point2 is directly left of point1
  double radiansTo(Mappoint other) {
    return atan2(other.y - y, other.x - x);
  }

  @override
  String toString() {
    return 'MapPoint{x: $x, y: $y}';
  }
}
