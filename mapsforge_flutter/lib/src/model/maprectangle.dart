import 'mappoint.dart';

/**
 * A Rectangle represents an immutable set of four double coordinates.
 */
class MapRectangle {
  final double bottom;
  final double left;
  final double right;
  final double top;

  const MapRectangle(this.left, this.top, this.right, this.bottom)
      : assert(left <= right),
        assert(bottom >= top);

  /**
   * @return true if this Rectangle contains the given point, false otherwise.
   */
  bool contains(Mappoint point) {
    return this.left <= point.x &&
        this.right >= point.x &&
        this.top <= point.y &&
        this.bottom >= point.y;
  }

  /**
   * Enlarges the Rectangle sides individually
   * @param left left enlargement
   * @param top top enlargement
   * @param right right enlargement
   * @param bottom bottom enlargement
   * @return
   */
  MapRectangle enlarge(double left, double top, double right, double bottom) {
    return new MapRectangle(this.left - left, this.top - top,
        this.right + right, this.bottom + bottom);
  }

  MapRectangle envelope(double padding) {
    return new MapRectangle(this.left - padding, this.top - padding,
        this.right + padding, this.bottom + padding);
  }

  /**
   * @return a new Point at the horizontal and vertical center of this Rectangle.
   */
  Mappoint getCenter() {
    return new Mappoint(getCenterX(), getCenterY());
  }

  /**
   * @return the horizontal center of this Rectangle.
   */
  double getCenterX() {
    return (this.left + this.right) / 2;
  }

  /**
   * @return the vertical center of this Rectangle.
   */
  double getCenterY() {
    return (this.top + this.bottom) / 2;
  }

  double getHeight() {
    return this.bottom - this.top;
  }

  double getWidth() {
    return this.right - this.left;
  }

  /**
   * @return true if this Rectangle intersects with the given Rectangle, false otherwise.
   */
  bool intersects(MapRectangle rectangle) {
    if (this == rectangle) {
      return true;
    }

    // return !(rectangle.left > right ||
    //     rectangle.right < left ||
    //     rectangle.top > bottom ||
    //     rectangle.bottom < top);
    return left <= rectangle.right &&
        right >= rectangle.left &&
        top <= rectangle.bottom &&
        bottom >= rectangle.top;
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
    return cornerDistanceX * cornerDistanceX +
            cornerDistanceY * cornerDistanceY <=
        radius * radius;
  }

  MapRectangle shift(Mappoint origin) {
    if (origin.x == 0 && origin.y == 0) {
      return this;
    }
    return MapRectangle(this.left + origin.x, this.top + origin.y,
        this.right + origin.x, this.bottom + origin.y);
  }

  @override
  String toString() {
    return 'Rectangle{left: $left, top: $top, right: $right, bottom: $bottom}';
  }
}
