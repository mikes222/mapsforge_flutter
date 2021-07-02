import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';

import '../graphics/mappaint.dart';
import '../renderer/shapecontainer.dart';

abstract class ShapePaintContainer {
  final double dy;
  final MapPaint paint;
  final ShapeContainer shapeContainer;

  const ShapePaintContainer(this.shapeContainer, this.paint, this.dy);

  void draw(MapCanvas canvas, PixelProjection projection);
}
