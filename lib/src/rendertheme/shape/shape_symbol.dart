import '../../graphics/position.dart';
import '../../model/maprectangle.dart';
import '../nodeproperties.dart';
import '../noderenderinfo.dart';
import '../rendercontext.dart';
import '../wayproperties.dart';
import '../wayrenderinfo.dart';
import '../xml/symbol_finder.dart';
import 'bitmapsrcmixin.dart';
import 'shape.dart';

class ShapeSymbol extends Shape with BitmapSrcMixin {
  Position position = Position.CENTER;

  double theta = 0;

  String? id;

  ShapeSymbol.base(int level) : super.base(level: level);

  ShapeSymbol.scale(ShapeSymbol base, int zoomLevel, SymbolFinder symbolFinder)
      : super.scale(base, zoomLevel) {
    bitmapSrcMixinScale(base, zoomLevel);
    position = base.position;
    theta = base.theta;
    id = base.id;
    if (id != null) {
      symbolFinder.add(id!, this);
    }
  }

  @override
  MapRectangle calculateBoundary() {
    if (boundary != null) return boundary!;

    double halfWidth = getBitmapWidth() / 2;
    double halfHeight = getBitmapHeight() / 2;

    switch (position) {
      case Position.AUTO:
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

    //print("boundary: $boundary $id $bitmapSrc");
    return boundary!;
  }

  @override
  String toString() {
    return 'ShapeSymbol{level: $level, position: $position, theta: $theta, id: $id}';
  }

  @override
  String getShapeType() {
    return "Symbol";
  }

  @override
  void renderNode(RenderContext renderContext, NodeProperties nodeProperties) {
    if (bitmapSrc == null) return;
    renderContext.labels.add(NodeRenderInfo(nodeProperties, this));
  }

  @override
  void renderWay(
      final RenderContext renderContext, WayProperties wayProperties) {
    if (bitmapSrc == null) return;

    if (wayProperties.getCoordinatesAbsolute(renderContext.projection).length ==
        0) return;

    renderContext.addToClashDrawingLayer(
        level, WayRenderInfo(wayProperties, this));
  }
}
