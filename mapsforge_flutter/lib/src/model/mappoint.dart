import 'dart:math';

/**
 * A Point represents an immutable pair of double coordinates in screen pixels.
 */
class Mappoint implements Comparable<Mappoint> {
  /// The x coordinate of this point in pixels.
  final double x;

  /// The y coordinate of this point in pixels.
  final double y;

  /// @param x the x coordinate of this point.
  /// @param y the y coordinate of this point.
  Mappoint(this.x, this.y) {}

  @override
  int compareTo(Mappoint point) {
    if (this.x > point.x) {
      return 1;
    } else if (this.x < point.x) {
      return -1;
    } else if (this.y > point.y) {
      return 1;
    } else if (this.y < point.y) {
      return -1;
    }
    return 0;
  }

  /**
   * @return the euclidian distance from this point to the given point.
   */
  double distance(Mappoint point) {
    return sqrt(pow(this.x - point.x, 2) + pow(this.y - point.y, 2));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Mappoint && runtimeType == other.runtimeType && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Mappoint offset(double dx, double dy) {
    if (0 == dx && 0 == dy) {
      return this;
    }
    return new Mappoint(this.x + dx, this.y + dy);
  }

  @override
  String toString() {
    return 'Point{x: $x, y: $y}';
  }
}
