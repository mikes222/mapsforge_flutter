import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/circlecontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint_container.dart';

import '../graphics/mappaint.dart';

class ShapePaintCircleContainer extends ShapePaintContainer<CircleContainer> {
  static int count = 0;

  final MapPaint? fill;

  final MapPaint? stroke;

  const ShapePaintCircleContainer(
      CircleContainer shapeContainer, this.fill, this.stroke, double dy)
      : super(shapeContainer, dy);

  @override
  Future<void> draw(MapCanvas canvas, PixelProjection projection,
      SymbolCache symbolCache) async {
    Mappoint point = shapeContainer.point;
    if (fill != null)
      canvas.drawCircle(point.x, point.y, shapeContainer.radius, fill!);
    if (stroke != null)
      canvas.drawCircle(point.x, point.y, shapeContainer.radius, stroke!);
    ++count;
  }
}
