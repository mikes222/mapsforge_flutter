import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/src/cache/symbolcache.dart';
import 'package:datastore_renderer/src/shapepainter/shape_paint.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:flutter/material.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintArea extends ShapePainter<RenderinstructionArea> {
  UiPaint? fill;

  UiPaint? stroke;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintArea._(RenderinstructionArea shape) : super(shape) {
    if (!shape.isFillTransparent() || shape.bitmapSrc != null) fill = createPaint(style: Style.FILL, color: shape.fillColor);

    if (!shape.isStrokeTransparent() && shape.strokeWidth > 0) {
      stroke = createPaint(
        style: Style.STROKE,
        color: shape.strokeColor,
        strokeWidth: shape.strokeWidth,
        cap: shape.strokeCap,
        join: shape.strokeJoin,
        strokeDashArray: shape.strokeDashArray,
      );
    }
  }

  static Future<ShapePaintArea> create(RenderinstructionArea shape, SymbolCache symbolCache) async {
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
    if (renderInstruction.bitmapSrc != null) {
      ResourceBitmap? bitmap = await createBitmap(
        symbolCache: symbolCache,
        bitmapSrc: renderInstruction.bitmapSrc!,
        bitmapWidth: renderInstruction.getBitmapWidth(),
        bitmapHeight: renderInstruction.getBitmapHeight(),
      );
      if (bitmap != null) {
        if (renderInstruction.isStrokeTransparent()) {
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
    MapPath path = calculatePath(wayProperties.getCoordinatesAbsolute(projection), reference, renderInstruction.dy);

    if (fill != null) canvas.drawPath(path, fill!);
    if (stroke != null) {
      canvas.drawPath(path, stroke!);
    }
  }

  @override
  void renderNode(MapCanvas canvas, Mappoint coordinatesAbsolute, Mappoint reference, [double rotationRadian = 0]) {}
}
