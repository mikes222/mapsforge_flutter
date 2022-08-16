import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint_container.dart';

class ShapePaintPolylineContainer
    extends ShapePaintContainer<PolylineContainer> {
  final MapPaint stroke;

  ShapePaintPolylineContainer(PolylineContainer shapeContainer, this.stroke,
      double dy, PixelProjection projection)
      : super(shapeContainer, dy) {
    shapeContainer.getCoordinatesRelativeToOrigin(projection);
  }

  @override
  void draw(MapCanvas canvas) {
    MapPath path = shapeContainer.calculatePath(dy);

    canvas.drawPath(path, stroke);
  }
}
