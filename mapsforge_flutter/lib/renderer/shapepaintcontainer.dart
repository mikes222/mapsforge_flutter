import '../graphics/paint.dart';
import '../renderer/shapecontainer.dart';

class ShapePaintContainer {
  final double dy;
  final Paint paint;
  final ShapeContainer shapeContainer;

  ShapePaintContainer(this.shapeContainer, this.paint, this.dy);
}
