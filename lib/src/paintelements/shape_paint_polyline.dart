import 'package:flutter/material.dart';
import 'package:isolate_task_queue/isolate_task_queue.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_polyline.dart';

import '../../core.dart';
import '../graphics/resourcebitmap.dart';
import '../rendertheme/wayproperties.dart';

class ShapePaintPolyline extends ShapePaint<ShapePolyline> {
  late final MapPaint? stroke;

  static TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintPolyline._(ShapePolyline shapePolyline) : super(shapePolyline) {
    if (!shapePolyline.isStrokeTransparent() || shapePolyline.bitmapSrc != null)
      stroke = createPaint(
          style: Style.STROKE,
          color: shapePolyline.strokeColor,
          strokeWidth: shapePolyline.strokeWidth,
          cap: shapePolyline.strokeCap,
          join: shapePolyline.strokeJoin,
          strokeDashArray: shapePolyline.strokeDashArray);
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
    if (shape.bitmapSrc != null) {
      ResourceBitmap? bitmap =
          await createBitmap(symbolCache: symbolCache, bitmapSrc: shape.bitmapSrc!, bitmapWidth: shape.getBitmapWidth(), bitmapHeight: shape.getBitmapHeight());
      if (bitmap != null) {
        if (shape.isStrokeTransparent()) {
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
    MapPath path = calculatePath(wayProperties.getCoordinatesAbsolute(projection), reference, shape.dy);
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
