import '../model/mappoint.dart';
import '../renderer/shapecontainer.dart';
import '../renderer/shapetype.dart';

class CircleContainer implements ShapeContainer {
  final Mappoint point;
  final double radius;

  CircleContainer(this.point, this.radius);

  @override
  ShapeType getShapeType() {
    return ShapeType.CIRCLE;
  }
}
