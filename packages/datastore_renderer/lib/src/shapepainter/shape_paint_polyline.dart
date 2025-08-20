import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:flutter/material.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintPolyline extends ShapePainter<RenderinstructionPolyline> {
  late final UiPaint? stroke;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintPolyline._(ShapePolyline shapePolyline) : super(shapePolyline) {
    if (!shapePolyline.isStrokeTransparent() || shapePolyline.bitmapSrc != null)
      stroke = createPaint(
        style: Style.STROKE,
        color: shapePolyline.strokeColor,
        strokeWidth: shapePolyline.strokeWidth,
        cap: shapePolyline.strokeCap,
        join: shapePolyline.strokeJoin,
        strokeDashArray: shapePolyline.strokeDashArray,
      );
  }

  static Future<ShapePaintPolyline> create(ShapePolyline shape, SymbolCache symbolCache) async {
    return _taskQueue.add(() async {
      if (shape.shapePaint != null) return shape.shapePaint! as ShapePaintPolyline;
      ShapePaintPolyline shapePaint = ShapePaintPolyline._(shape);
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
          stroke!.setColor(Colors.black);
        }
        stroke!.setBitmapShader(bitmap);
        bitmap.dispose();
      }
    }
  }

  @override
  void renderWay(MapCanvas canvas, WayProperties wayProperties, PixelProjection projection, Mappoint reference, [double rotationRadian = 0]) {
    if (stroke == null) return;
    MapPath path = calculatePath(wayProperties.getCoordinatesAbsolute(projection), reference, renderInstruction.dy);
    canvas.drawPath(path, stroke!);

    // if (debug) {
    //   Mappoint point =
    //       wayProperties.getCenterRelativeToLeftUpper(projection, leftUpper, 0);
    //   MapTextPaint mapTextPaint = FlutterTextPaint()..setTextSize(50);
    //   MapPaint mapPaint = GraphicFactory().createPaint()
    //     ..setColor(Colors.black);
    //   canvas.drawText(
    //       "${shape.level}", point.x, point.y, mapPaint, mapTextPaint, 300);
    // }
  }

  @override
  void renderNode(MapCanvas canvas, Mappoint coordinatesAbsolute, Mappoint reference, [double rotationRadian = 0]) {}
}
