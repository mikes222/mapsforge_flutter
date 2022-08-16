import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint_container.dart';

class ShapePaintAreaContainer extends ShapePaintContainer<PolylineContainer> {
  final MapPaint? fill;

  final MapPaint? stroke;

  ShapePaintAreaContainer(PolylineContainer shapeContainer, this.fill,
      this.stroke, double dy, PixelProjection projection)
      : super(shapeContainer, dy) {
    shapeContainer.getCoordinatesRelativeToOrigin(projection);
  }

  @override
  void draw(MapCanvas canvas) {
    MapPath path = shapeContainer.calculatePath(dy);

    if (fill != null) canvas.drawPath(path, fill!);
    if (stroke != null) canvas.drawPath(path, stroke!);
  }
}
