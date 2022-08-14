import 'dart:math';

/// A Point represents an immutable pair of double coordinates in screen pixels.
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
    return sqrt(pow(this.x - point.x, 2) + pow(this.y - point.y, 2));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mappoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Mappoint offset(double dx, double dy) {
    if (0 == dx && 0 == dy) {
      return this;
    }
    return Mappoint(this.x + dx, this.y + dy);
  }

  @override
  String toString() {
    return 'Point{x: $x, y: $y}';
  }
}
