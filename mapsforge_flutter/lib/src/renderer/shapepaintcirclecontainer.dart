import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/renderer/circlecontainer.dart';
import 'package:mapsforge_flutter/src/renderer/shapepaintcontainer.dart';

import '../graphics/mappaint.dart';
import '../renderer/shapecontainer.dart';

class ShapePaintCircleContainer extends ShapePaintContainer {
  static int count = 0;

  const ShapePaintCircleContainer(
      ShapeContainer shapeContainer, MapPaint paint, double dy)
      : super(shapeContainer, paint, dy);

  @override
  void draw(MapCanvas canvas, PixelProjection projection) {
    CircleContainer circleContainer = shapeContainer as CircleContainer;
    Mappoint point = circleContainer.point;
    canvas.drawCircle(point.x, point.y,
        circleContainer.radius, paint);
    ++count;
  }
}
