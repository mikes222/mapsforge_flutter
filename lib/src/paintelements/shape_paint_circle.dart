import 'package:isolate_task_queue/isolate_task_queue.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/relative_mappoint.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_circle.dart';
import 'package:mapsforge_flutter/src/rendertheme/wayproperties.dart';

import '../../maps.dart';
import '../../special.dart';

class ShapePaintCircle extends ShapePaint<ShapeCircle> {
  late final MapPaint? fill;

  late final MapPaint? stroke;

  static TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintCircle._(ShapeCircle shapeSymbol) : super(shapeSymbol) {
    if (!shapeSymbol.isFillTransparent()) fill = createPaint(style: Style.FILL, color: shapeSymbol.fillColor);
    if (!shapeSymbol.isStrokeTransparent())
      stroke = createPaint(
          style: Style.STROKE,
          color: shapeSymbol.strokeColor,
          strokeWidth: shapeSymbol.strokeWidth,
          cap: shapeSymbol.strokeCap,
          join: shapeSymbol.strokeJoin,
          strokeDashArray: shapeSymbol.strokeDashArray);
    else
      stroke = null;
  }

  static Future<ShapePaintCircle> create(ShapeCircle shape, SymbolCache symbolCache) async {
    return _taskQueue.add(() async {
      if (shape.shapePaint != null) return shape.shapePaint! as ShapePaintCircle;
      ShapePaintCircle shapePaint = ShapePaintCircle._(shape);
      //await shapePaint.init(symbolCache);
      shape.shapePaint = shapePaint;
      return shapePaint;
    });
  }

  @override
  Future<void> init(SymbolCache symbolCache) {
    return Future.value();
  }

  @override
  void renderNode(MapCanvas canvas, Mappoint coordinatesAbsolute, Mappoint reference, [double rotationRadian = 0]) {
    RelativeMappoint relative = coordinatesAbsolute.offset(-reference.x, -reference.y + shape.dy);
    if (fill != null) canvas.drawCircle(relative.x, relative.y, shape.radius, fill!);
    if (stroke != null) canvas.drawCircle(relative.x, relative.y, shape.radius, stroke!);
  }

  @override
  void renderWay(MapCanvas canvas, WayProperties wayProperties, PixelProjection projection, Mappoint reference, [double rotationRadian = 0]) {}
}
