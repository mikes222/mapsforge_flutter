import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/renderer/circlecontainer.dart';
import 'package:mapsforge_flutter/src/renderer/shapepaintcontainer.dart';

import '../graphics/mappaint.dart';
import '../renderer/shapecontainer.dart';

class ShapePaintCircleContainer extends ShapePaintContainer {
  static int count = 0;

  final MapPaint? fill;

  final MapPaint? stroke;

  const ShapePaintCircleContainer(
      ShapeContainer shapeContainer, this.fill, this.stroke, double dy)
      : super(shapeContainer, dy);

  @override
  void draw(MapCanvas canvas, PixelProjection projection) {
    CircleContainer circleContainer = shapeContainer as CircleContainer;
    Mappoint point = circleContainer.point;
    if (fill != null)
      canvas.drawCircle(point.x, point.y, circleContainer.radius, fill!);
    if (stroke != null)
      canvas.drawCircle(point.x, point.y, circleContainer.radius, stroke!);
    ++count;
  }
}
