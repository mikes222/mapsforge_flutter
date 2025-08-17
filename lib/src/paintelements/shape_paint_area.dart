import 'package:flutter/material.dart';
import 'package:isolate_task_queue/isolate_task_queue.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint.dart';

import '../rendertheme/shape/shape_area.dart';
import '../rendertheme/wayproperties.dart';

class ShapePaintArea extends ShapePaint<ShapeArea> {
  MapPaint? fill;

  MapPaint? stroke;

  static TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintArea._(ShapeArea shape) : super(shape) {
    if (!shape.isFillTransparent() || shape.bitmapSrc != null) fill = createPaint(style: Style.FILL, color: shape.fillColor);

    if (!shape.isStrokeTransparent() && shape.strokeWidth > 0) {
      stroke = createPaint(
          style: Style.STROKE,
          color: shape.strokeColor,
          strokeWidth: shape.strokeWidth,
          cap: shape.strokeCap,
          join: shape.strokeJoin,
          strokeDashArray: shape.strokeDashArray);
    }
  }

  static Future<ShapePaintArea> create(ShapeArea shape, SymbolCache symbolCache) async {
    return _taskQueue.add(() async {
      if (shape.shapePaint != null) return shape.shapePaint! as ShapePaintArea;
      ShapePaintArea shapePaint = ShapePaintArea._(shape);
      await shapePaint.init(symbolCache);
      shape.shapePaint = shapePaint;
      return shapePaint;
    });
  }

  @override
  Future<void> init(SymbolCache symbolCache) async {
    if (shape.bitmapSrc != null) {
      ResourceBitmap? bitmap =
          await createBitmap(symbolCache: symbolCache, bitmapSrc: shape.bitmapSrc!, bitmapWidth: shape.getBitmapWidth(), bitmapHeight: shape.getBitmapHeight());
      if (bitmap != null) {
        if (shape.isStrokeTransparent()) {
          // for bitmaps set the stroke color so that the bitmap is drawn
          fill!.setColor(Colors.black);
        }
        fill!.setBitmapShader(bitmap);
        bitmap.dispose();
      }
    }
  }

  @override
  void renderWay(MapCanvas canvas, WayProperties wayProperties, PixelProjection projection, Mappoint reference, [double rotationRadian = 0]) {
    MapPath path = calculatePath(wayProperties.getCoordinatesAbsolute(projection), reference, shape.dy);

    if (fill != null) canvas.drawPath(path, fill!);
    if (stroke != null) {
      canvas.drawPath(path, stroke!);
    }
  }

  @override
  void renderNode(MapCanvas canvas, Mappoint coordinatesAbsolute, Mappoint reference, [double rotationRadian = 0]) {}
}
