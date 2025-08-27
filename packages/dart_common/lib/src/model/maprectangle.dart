import 'package:dart_common/model.dart';

/// A Rectangle represents an immutable set of four double coordinates in mappixels.
class MapRectangle {
  final double bottom;
  final double left;
  final double right;
  final double top;

  const MapRectangle(this.left, this.top, this.right, this.bottom) : assert(left <= right), assert(bottom >= top);

  const MapRectangle.zero() : this(0, 0, 0, 0);

  factory MapRectangle.from(List<Mappoint> mp1) {
    double bottom = -1;
    double left = double.maxFinite;
    double right = -1;
    double top = double.maxFinite;
    for (var element in mp1) {
      if (left > element.x) left = element.x;
      if (top > element.y) top = element.y;
      if (right < element.x) right = element.x;
      if (bottom < element.y) bottom = element.y;
    }
    return MapRectangle(left, top, right, bottom);
  }

  /// @return true if this Rectangle contains the given point, false otherwise.
  bool contains(Mappoint point) {
    return left <= point.x && right >= point.x && top <= point.y && bottom >= point.y;
  }

  /// Enlarges the Rectangle sides individually
  /// @param left left enlargement
  /// @param top top enlargement
  /// @param right right enlargement
  /// @param bottom bottom enlargement
  /// @return
  MapRectangle enlarge(double left, double top, double right, double bottom) {
    return MapRectangle(this.left - left, this.top - top, this.right + right, this.bottom + bottom);
  }

  MapRectangle envelope(double padding) {
    return MapRectangle(left - padding, top - padding, right + padding, bottom + padding);
  }

  /// @return a new Point at the horizontal and vertical center of this Rectangle.
  Mappoint getCenter() {
    return Mappoint(getCenterX(), getCenterY());
  }

  /// @return the horizontal center of this Rectangle.
  double getCenterX() {
    return (left + right) / 2;
  }

  /// @return the vertical center of this Rectangle.
  double getCenterY() {
    return (top + bottom) / 2;
  }

  double getHeight() {
    return bottom - top;
  }

  double getWidth() {
    return right - left;
  }

  /// @return true if this Rectangle intersects with the given Rectangle, false otherwise.
  bool intersects(MapRectangle rectangle) {
    if (this == rectangle) {
      return true;
    }

    // return !(rectangle.left > right ||
    //     rectangle.right < left ||
    //     rectangle.top > bottom ||
    //     rectangle.bottom < top);
    return left <= rectangle.right && right >= rectangle.left && top <= rectangle.bottom && bottom >= rectangle.top;
  }

  bool intersectsCircle(double pointX, double pointY, double radius) {
    double halfWidth = getWidth() / 2;
    double halfHeight = getHeight() / 2;

    double centerDistanceX = (pointX - getCenterX()).abs();
    double centerDistanceY = (pointY - getCenterY()).abs();

    // is the circle is far enough away from the rectangle?
    if (centerDistanceX > halfWidth + radius) {
      return false;
    } else if (centerDistanceY > halfHeight + radius) {
      return false;
    }

    // is the circle close enough to the rectangle?
    if (centerDistanceX <= halfWidth) {
      return true;
    } else if (centerDistanceY <= halfHeight) {
      return true;
    }

    double cornerDistanceX = centerDistanceX - halfWidth;
    double cornerDistanceY = centerDistanceY - halfHeight;
    return cornerDistanceX * cornerDistanceX + cornerDistanceY * cornerDistanceY <= radius * radius;
  }

  MapRectangle shift(Mappoint reference) {
    if (reference.x == 0 && reference.y == 0) {
      return this;
    }
    return MapRectangle(left + reference.x, top + reference.y, right + reference.x, bottom + reference.y);
  }

  MapRectangle offset(Mappoint reference) {
    if (reference.x == 0 && reference.y == 0) {
      return this;
    }
    return MapRectangle(left - reference.x, top - reference.y, right - reference.x, bottom - reference.y);
  }

  Mappoint getLeftUpper() {
    return Mappoint(left, top);
  }

  Mappoint getRightLower() {
    return Mappoint(right, bottom);
  }

  @override
  String toString() {
    return 'Rectangle{left: $left, top: $top, right: $right, bottom: $bottom}';
  }
}
