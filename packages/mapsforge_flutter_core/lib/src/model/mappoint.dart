import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';

/// An immutable pair of absolute double coordinates in map pixels.
///
/// 0/0 represents the upper-left corner of the complete map (latitude 90, longitude -180).
class Mappoint {
  /// The x coordinate of this point in pixels. Positive values points towards
  /// the right side of the screen.
  final double x;

  /// The y coordinate of this point in pixels. Positive values points to
  /// the bottom of the screen.
  final double y;

  /// Creates a new `Mappoint`.
  const Mappoint(this.x, this.y) : assert(x >= 0, "x ($x) must be >= 0"), assert(y >= 0, "y ($y) must be >= 0");

  /// Creates a new `Mappoint` at the origin (0,0).
  const Mappoint.zero() : x = 0, y = 0;

  /// Calculates the Euclidean distance from this point to the given [point].
  double distance(Mappoint point) {
    return sqrt((x - point.x) * (x - point.x) + (y - point.y) * (y - point.y));
  }

  double distanceSquared(Mappoint point) {
    return (x - point.x) * (x - point.x) + (y - point.y) * (y - point.y);
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Mappoint && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  /// Creates a new `Mappoint` that is offset by the given dx and dy values.
  Mappoint offsetAbsolute(double dx, double dy) {
    if (0 == dx && 0 == dy) {
      return this;
    }
    return Mappoint(x + dx, y + dy);
  }

  /// Creates a `MappointRelative` that represents the offset from a given
  /// [reference] point.
  MappointRelative offset(Mappoint reference) {
    return MappointRelative(x - reference.x, y - reference.y);
  }

  /// Calculates the angle in radians from this point to the [other] point.
  ///
  /// The angle is measured counter-clockwise from the positive x-axis.
  double radiansTo(Mappoint other) {
    return atan2(other.y - y, other.x - x);
  }

  @override
  String toString() {
    return 'MapPoint{x: $x, y: $y}';
  }
}
