import '../graphics/mappaint.dart';
import '../renderer/shapecontainer.dart';

class ShapePaintContainer {
  final double dy;
  final MapPaint paint;
  final ShapeContainer shapeContainer;

  ShapePaintContainer(this.shapeContainer, this.paint, this.dy);
}
