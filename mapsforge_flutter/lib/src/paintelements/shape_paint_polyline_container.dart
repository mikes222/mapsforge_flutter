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

class ShapePaintPolylineContainer
    extends ShapePaintContainer<PolylineContainer> {
  static int count = 0;

  final MapPaint stroke;

  final String? bitmapSrc;

  final int bitmapWidth;

  final int bitmapHeight;

  ShapePaintPolylineContainer(
      PolylineContainer shapeContainer,
      this.stroke,
      this.bitmapSrc,
      this.bitmapWidth,
      this.bitmapHeight,
      double dy,
      PixelProjection projection)
      : super(shapeContainer, dy) {
    shapeContainer.getCoordinatesRelativeToOrigin(projection);
  }

  @override
  Future<void> draw(MapCanvas canvas, SymbolCache symbolCache) async {
    ++count;
    MapPath path = shapeContainer.calculatePath(dy);

    if (bitmapSrc != null && stroke.getBitmapShader() == null) {
      ResourceBitmap? bitmap =
          await symbolCache.getSymbol(bitmapSrc, bitmapWidth, bitmapHeight);
      if (bitmap != null) {
        if (stroke.isTransparent()) stroke.setColor(Colors.black);
        stroke.setBitmapShader(bitmap);
      }
    }

    canvas.drawPath(path, stroke);
  }
}
