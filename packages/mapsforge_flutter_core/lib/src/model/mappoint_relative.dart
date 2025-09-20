import 'package:mapsforge_flutter_core/src/model/mappoint.dart';

/// An immutable pair of relative double coordinates in map pixels.
///
/// This is used to represent an offset from a reference point.
class MappointRelative {
  /// The x coordinate of this point in pixels. Positive values points towards
  /// the right side of the screen.
  final double dx;

  /// The y coordinate of this point in pixels. Positive values points to
  /// the bottom of the screen.
  final double dy;

  /// Creates a new `MappointRelative`.
  const MappointRelative(this.dx, this.dy);

  /// Creates a new `MappointRelative` at the origin (0,0).
  const MappointRelative.zero() : dx = 0, dy = 0;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Mappoint && runtimeType == other.runtimeType && dx == other.x && dy == other.y;

  @override
  int get hashCode => dx.hashCode ^ dy.hashCode;

  /// Creates a new `MappointRelative` that is offset by the given dx and dy values.
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
