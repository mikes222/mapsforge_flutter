import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/ui/ui_canvas.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_shape_painter.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintCircle extends UiShapePainter<RenderinstructionCircle> {
  late final UiPaint? fill;

  late final UiPaint? stroke;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintCircle._(RenderinstructionCircle renderinstruction) : super(renderinstruction) {
    if (!renderinstruction.isFillTransparent()) fill = UiPaint.fill(color: renderinstruction.fillColor);
    if (!renderinstruction.isStrokeTransparent()) {
      stroke = UiPaint.stroke(
        color: renderinstruction.strokeColor,
        strokeWidth: renderinstruction.strokeWidth,
        cap: renderinstruction.strokeCap,
        join: renderinstruction.strokeJoin,
        strokeDasharray: renderinstruction.strokeDashArray,
      );
    }
  }

  static Future<ShapePaintCircle> create(RenderinstructionCircle renderinstruction) async {
    return _taskQueue.add(() async {
      if (renderinstruction.shapePainter != null) return renderinstruction.shapePainter! as ShapePaintCircle;
      ShapePaintCircle shapePaint = ShapePaintCircle._(renderinstruction);
      renderinstruction.shapePainter = shapePaint;
      return shapePaint;
    });
  }

  @override
  void renderNode(RenderContext renderContext, NodeProperties nodeProperties) {
    RelativeMappoint relative = nodeProperties.getCoordinatesAbsolute().offset(renderContext.reference);
    relative = relative.offset(0, renderinstruction.dy);
    if (fill != null) renderContext.canvas.drawCircle(relative.x, relative.y, renderinstruction.radius, fill!);
    if (stroke != null) renderContext.canvas.drawCircle(relative.x, relative.y, renderinstruction.radius, stroke!);
  }

  @override
  void renderWay(RenderContext renderContext, WayProperties wayProperties) {}
}
