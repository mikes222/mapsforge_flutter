import 'package:mapsforge_flutter/src/paintelements/shape/shapecontainer.dart';

import '../../model/mappoint.dart';

class CircleContainer implements ShapeContainer {
  /// the absolute point of the center of the cirlce in pixels
  final Mappoint point;

  /// the radius of the circle in pixels
  final double radius;

  const CircleContainer(this.point, this.radius);
}
