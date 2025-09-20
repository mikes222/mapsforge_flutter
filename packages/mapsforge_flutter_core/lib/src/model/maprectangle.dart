import 'package:mapsforge_flutter_core/model.dart';

/// An immutable rectangle defined by four double coordinates in map pixels.
class MapRectangle {
  final double bottom;
  final double left;
  final double right;
  final double top;

  /// Creates a new `MapRectangle`.
  const MapRectangle(this.left, this.top, this.right, this.bottom) : assert(left <= right, "left ($left) > right ($right)"), assert(bottom >= top);

  /// Creates a new `MapRectangle` at the origin with zero width and height.
  const MapRectangle.zero() : this(0, 0, 0, 0);

  /// Creates a new `MapRectangle` that encloses all the given points.
  factory MapRectangle.from(List<Mappoint> mp1) {
    assert(mp1.isNotEmpty);
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

  /// Returns true if this rectangle contains the given [point].
  bool contains(Mappoint point) {
    return left <= point.x && right >= point.x && top <= point.y && bottom >= point.y;
  }

  /// Creates a new `MapRectangle` by enlarging this rectangle by the given amounts.
  MapRectangle enlarge(double left, double top, double right, double bottom) {
    return MapRectangle(this.left - left, this.top - top, this.right + right, this.bottom + bottom);
  }

  /// Creates a new `MapRectangle` by adding a [padding] to all sides.
  MapRectangle envelope(double padding) {
    return MapRectangle(left - padding, top - padding, right + padding, bottom + padding);
  }

  /// Returns the center point of this rectangle.
  Mappoint getCenter() {
    return Mappoint(getCenterX(), getCenterY());
  }

  /// Returns the horizontal center of this rectangle.
  double getCenterX() {
    return (left + right) / 2;
  }

  /// Returns the vertical center of this rectangle.
  double getCenterY() {
    return (top + bottom) / 2;
  }

  /// Returns the height of this rectangle.
  double getHeight() {
    return bottom - top;
  }

  /// Returns the width of this rectangle.
  double getWidth() {
    return right - left;
  }

  /// Returns true if this rectangle intersects with the given [rectangle].
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

  /// Returns true if this rectangle intersects with a circle defined by its center
  /// ([pointX], [pointY]) and [radius].
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

  /// Creates a new `MapRectangle` by shifting this rectangle by the given [reference] point.
  MapRectangle shift(Mappoint reference) {
    if (reference.x == 0 && reference.y == 0) {
      return this;
    }
    return MapRectangle(left + reference.x, top + reference.y, right + reference.x, bottom + reference.y);
  }

  /// Creates a new `MapRectangle` by offsetting this rectangle by the given [reference] point.
  MapRectangle offset(Mappoint reference) {
    if (reference.x == 0 && reference.y == 0) {
      return this;
    }
    return MapRectangle(left - reference.x, top - reference.y, right - reference.x, bottom - reference.y);
  }

  /// Returns the top-left corner of this rectangle.
  Mappoint getLeftUpper() {
    return Mappoint(left, top);
  }

  /// Returns the bottom-right corner of this rectangle.
  Mappoint getRightLower() {
    return Mappoint(right, bottom);
  }

  @override
  String toString() {
    return 'Rectangle{left: $left, top: $top, right: $right, bottom: $bottom}';
  }
}
