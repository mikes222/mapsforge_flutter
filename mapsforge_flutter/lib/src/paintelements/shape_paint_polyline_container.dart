import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint_container.dart';
import 'package:mapsforge_flutter/src/renderer/rendererutils.dart';

import 'shape/shapecontainer.dart';

class ShapePaintPolylineContainer extends ShapePaintContainer {
  late MapPath path;

  static int count = 0;

  final MapPaint stroke;

  String? bitmapSrc;

  int bitmapWidth;

  int bitmapHeight;

  ShapePaintPolylineContainer(ShapeContainer shapeContainer, this.stroke,
      this.bitmapSrc, this.bitmapWidth, this.bitmapHeight, double dy)
      : super(shapeContainer, dy) {
    path = GraphicFactory().createPath();
  }

  @override
  Future<void> draw(MapCanvas canvas, PixelProjection projection,
      SymbolCache symbolCache) async {
    ++count;
    PolylineContainer polylineContainer = shapeContainer as PolylineContainer;
    this.path.clear();

    for (List<Mappoint> outerList
        in polylineContainer.getCoordinatesRelativeToOrigin(projection)) {
      List<Mappoint> points;
      if (dy != 0) {
        points = RendererUtils.parallelPath(outerList, dy);
      } else {
        points = outerList;
      }
      //print("Drawing ShapePaintPolyline $minMaxMappoint with $paint");
      Mappoint point = points[0];
      this.path.moveTo(point.x, point.y);
      //print("path moveTo $point");
      for (int i = 1; i < points.length; i++) {
        point = points[i];
        this.path.lineTo(point.x, point.y);
        //print("path lineTo $point");
      }
    }

    if (bitmapSrc != null) {
      ResourceBitmap? bitmap =
          await symbolCache.getSymbol(bitmapSrc, bitmapWidth, bitmapHeight);
      if (bitmap != null) {
        if (stroke.isTransparent()) stroke.setColor(Colors.black);
        stroke.setBitmapShader(bitmap);
      }
    }

    canvas.drawPath(this.path, stroke);
  }

  @override
  String toString() {
    return 'ShapePaintPolylineContainer{path: $path}';
  }
}
