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

class ShapePaintAreaContainer extends ShapePaintContainer<PolylineContainer> {
  static int count = 0;

  final MapPaint? fill;

  final MapPaint? stroke;

  final String? bitmapSrc;

  final int bitmapWidth;

  final int bitmapHeight;

  ShapePaintAreaContainer(
      PolylineContainer shapeContainer,
      this.fill,
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

    if (fill != null && fill!.getBitmapShader() == null && bitmapSrc != null) {
      // print(
      //     "fill not null and bitmapSrc is $bitmapSrc + $bitmapWidth + $bitmapHeight");
      ResourceBitmap? bitmap =
          await symbolCache.getSymbol(bitmapSrc, bitmapWidth, bitmapHeight);
      if (bitmap != null) {
        if (fill!.isTransparent()) fill!.setColor(Colors.black);
        fill!.setBitmapShader(bitmap);
      }
    }

    if (fill != null) canvas.drawPath(path, fill!);
    if (stroke != null) canvas.drawPath(path, stroke!);
  }
}
