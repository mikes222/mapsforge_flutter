import 'package:mapsforge_flutter_core/src/model/mappoint.dart';

/// A Point represents an immutable pair of double coordinates in map pixels.
class MappointRelative {
  /// The x coordinate of this point in pixels. Positive values points towards
  /// the right side of the screen.
  final double dx;

  /// The y coordinate of this point in pixels. Positive values points to
  /// the bottom of the screen.
  final double dy;

  /// @param x the x coordinate of this point.
  /// @param y the y coordinate of this point.
  const MappointRelative(this.dx, this.dy);

  @override
  bool operator ==(Object other) => identical(this, other) || other is Mappoint && runtimeType == other.runtimeType && dx == other.x && dy == other.y;

  @override
  int get hashCode => dx.hashCode ^ dy.hashCode;

  MappointRelative offset(double dx, double dy) {
    if (0 == dx && 0 == dy) {
      return this;
    }
    return MappointRelative(this.dx + dx, this.dy + dy);
  }

  @override
  String toString() {
    return 'RelativeMappoint{x: $dx, y: $dy}';
  }
}
