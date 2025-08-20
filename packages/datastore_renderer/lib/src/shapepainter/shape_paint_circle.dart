import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintCircle extends ShapePainter<RenderinstructionCircle> {
  late final UiPaint? fill;

  late final UiPaint? stroke;

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
        strokeDashArray: shapeSymbol.strokeDashArray,
      );
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
    RelativeMappoint relative = coordinatesAbsolute.offset(-reference.x, -reference.y + renderInstruction.dy);
    if (fill != null) canvas.drawCircle(relative.x, relative.y, renderInstruction.radius, fill!);
    if (stroke != null) canvas.drawCircle(relative.x, relative.y, renderInstruction.radius, stroke!);
  }

  @override
  void renderWay(MapCanvas canvas, WayProperties wayProperties, PixelProjection projection, Mappoint reference, [double rotationRadian = 0]) {}
}
