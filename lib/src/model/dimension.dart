import 'mappoint.dart';

class Dimension {
  final double height;
  final double width;

  Dimension(this.width, this.height)
      : assert(width >= 0),
        assert(height >= 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dimension &&
          runtimeType == other.runtimeType &&
          height == other.height &&
          width == other.width;

  @override
  int get hashCode => height.hashCode ^ width.hashCode;

  /**
   * Gets the center point of the dimension.
   *
   * @return the center point
   */
  Mappoint getCenter() {
    return new Mappoint(this.width / 2, this.height / 2);
  }

  @override
  String toString() {
    return 'Dimension{height: $height, width: $width}';
  }
}
