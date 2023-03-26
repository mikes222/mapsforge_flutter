import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint.dart';
import 'package:mapsforge_flutter/src/rendertheme/nodeproperties.dart';

import '../rendertheme/shape/shape_area.dart';
import '../rendertheme/wayproperties.dart';

class ShapePaintArea extends ShapePaint<ShapeArea> {
  MapPaint? fill;

  MapPaint? stroke;

  ShapePaintArea(ShapeArea symbol) : super(symbol) {
    if (!symbol.isFillTransparent() || symbol.bitmapSrc != null)
      fill = createPaint(style: Style.FILL, color: symbol.fillColor);
    if (!symbol.isStrokeTransparent() && symbol.strokeWidth > 0) {
      stroke = createPaint(
          style: Style.STROKE,
          color: symbol.strokeColor,
          strokeWidth: symbol.strokeWidth,
          cap: symbol.strokeCap,
          join: symbol.strokeJoin,
          strokeDashArray: symbol.strokeDashArray);
    }
  }

  @override
  Future<void> init(SymbolCache symbolCache) async {
    if (shape.bitmapSrc != null) {
      ResourceBitmap? bitmap = await createBitmap(
          symbolCache: symbolCache,
          bitmapSrc: shape.bitmapSrc!,
          bitmapWidth: shape.getBitmapWidth(),
          bitmapHeight: shape.getBitmapHeight());
      if (bitmap != null) {
        if (shape.isStrokeTransparent()) {
          fill!.setColor(Colors.black);
        }
        fill!.setBitmapShader(bitmap);
        bitmap.dispose();
      }
    }
  }

  @override
  void renderWay(MapCanvas canvas, WayProperties wayProperties,
      PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]) {
    MapPath path = calculatePath(wayProperties
        .getCoordinatesRelativeToLeftUpper(projection, leftUpper, shape.dy));

    if (fill != null) canvas.drawPath(path, fill!);
    if (stroke != null) canvas.drawPath(path, stroke!);
  }

  @override
  void renderNode(MapCanvas canvas, NodeProperties nodeProperties,
      PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]) {}
}
