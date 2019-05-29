import 'mappoint.dart';

class Dimension {
  final int height;
  final int width;

  Dimension(this.width, this.height) {
    if (width < 0) {
      throw new Exception("width must not be negative: $width");
    } else if (height < 0) {
      throw new Exception("height must not be negative: $height");
    }
  }

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
