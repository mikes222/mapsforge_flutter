import 'dart:math';

import 'package:dart_common/model.dart';

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
    return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2));
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
  RelativeMappoint offset(Mappoint reference) {
    return RelativeMappoint(x - reference.x, y - reference.y);
  }

  @override
  String toString() {
    return 'MapPoint{x: $x, y: $y}';
  }
}
