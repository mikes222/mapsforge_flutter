import '../../graphics/position.dart';
import '../../model/maprectangle.dart';
import 'bitmapsrcmixin.dart';
import 'shape.dart';

class ShapeSymbol extends Shape with BitmapSrcMixin {
  Position position = Position.CENTER;

  double theta = 0;

  int level = 0;

  String? id;

  ShapeSymbol.base() : super.base();

  ShapeSymbol.scale(ShapeSymbol base, int zoomLevel)
      : super.scale(base, zoomLevel) {
    bitmapSrcMixinScale(base, zoomLevel);
    position = base.position;
    theta = base.theta;
    level = base.level;
    id = base.id;
  }

  @override
  MapRectangle calculateBoundary() {
    if (boundary != null) return boundary!;

    double halfWidth = getBitmapWidth() / 2;
    double halfHeight = getBitmapHeight() / 2;

    switch (position) {
      case Position.AUTO:
        this.boundary =
            MapRectangle(-halfWidth, -halfHeight, halfWidth, halfHeight);
        break;
      case Position.CENTER:
        this.boundary =
            MapRectangle(-halfWidth, -halfHeight, halfWidth, halfHeight);
        break;
      case Position.BELOW:
        this.boundary = MapRectangle(
            -halfWidth, 0, halfWidth, getBitmapHeight().toDouble());
        break;
      case Position.BELOW_LEFT:
        this.boundary = MapRectangle(
            -getBitmapWidth().toDouble(), 0, 0, getBitmapHeight().toDouble());
        break;
      case Position.BELOW_RIGHT:
        this.boundary = MapRectangle(
            0, 0, getBitmapWidth().toDouble(), getBitmapHeight().toDouble());
        break;
      case Position.ABOVE:
        this.boundary = MapRectangle(
            -halfWidth, -getBitmapHeight().toDouble(), halfWidth, 0);
        break;
      case Position.ABOVE_LEFT:
        this.boundary = MapRectangle(
            -getBitmapWidth().toDouble(), -getBitmapHeight().toDouble(), 0, 0);
        break;
      case Position.ABOVE_RIGHT:
        this.boundary = MapRectangle(
            0, -getBitmapHeight().toDouble(), getBitmapWidth().toDouble(), 0);
        break;
      case Position.LEFT:
        this.boundary = MapRectangle(
            -getBitmapHeight().toDouble(), -halfHeight, 0, halfHeight);
        break;
      case Position.RIGHT:
        this.boundary = MapRectangle(
            -0, -halfHeight, getBitmapHeight().toDouble(), halfHeight);
        break;
    }

    return boundary!;
  }

  @override
  String toString() {
    return 'SymbolContainer{theta: $theta, super ${super.toString()}';
  }

  @override
  String getShapeType() {
    return "Symbol";
  }
}
