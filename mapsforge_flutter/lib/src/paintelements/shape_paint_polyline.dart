import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint.dart';
import 'package:mapsforge_flutter/src/rendertheme/nodeproperties.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_polyline.dart';

import '../../core.dart';
import '../graphics/resourcebitmap.dart';
import '../rendertheme/wayproperties.dart';

class ShapePaintPolyline extends ShapePaint<ShapePolyline> {
  late final MapPaint? stroke;

  ShapePaintPolyline(ShapePolyline shapeSymbol) : super(shapeSymbol) {
    if (!shapeSymbol.isStrokeTransparent()) {
      stroke = createPaint(
          style: Style.STROKE,
          color: shapeSymbol.strokeColor,
          strokeWidth: shapeSymbol.strokeWidth,
          cap: shapeSymbol.strokeCap,
          join: shapeSymbol.strokeJoin,
          strokeDashArray: shapeSymbol.strokeDashArray);
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
          stroke!.setColor(Colors.black);
        }
        stroke!.setBitmapShader(bitmap);
        bitmap.dispose();
      }
    }
  }

  @override
  void renderWay(MapCanvas canvas, WayProperties wayProperties,
      PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]) {
    if (shape.isStrokeTransparent()) return;

    MapPath path = calculatePath(wayProperties
        .getCoordinatesRelativeToLeftUpper(projection, leftUpper, shape.dy));
    canvas.drawPath(path, stroke!);
  }

  @override
  void renderNode(MapCanvas canvas, NodeProperties nodeProperties,
      PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]) {}
}
