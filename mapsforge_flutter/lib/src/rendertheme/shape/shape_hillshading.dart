import 'package:mapsforge_flutter/src/rendertheme/shape/shape.dart';

import '../../model/maprectangle.dart';
import '../../rendertheme/wayproperties.dart';

class ShapeHillshading extends Shape {
  final double magnitude;
  final MapRectangle? hillsRect;
  final MapRectangle? tileRect;

  WayProperties? container;

  ShapeHillshading.base()
      : magnitude = 0,
        hillsRect = null,
        tileRect = null,
        super.base();

  ShapeHillshading.scale(ShapeHillshading base, int zoomLevel)
      : magnitude = 0,
        hillsRect = null,
        tileRect = null,
        super.scale(base, zoomLevel) {}

  @override
  String toString() {
    return 'HillshadingContainer{magnitude: $magnitude, hillsRect: $hillsRect, tileRect: $tileRect}';
  }

  @override
  String getShapeType() {
    return "Hillshading";
  }
}
