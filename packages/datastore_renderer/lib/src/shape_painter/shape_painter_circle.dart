import 'package:dart_common/model.dart';
import 'package:dart_common/task_queue.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_render_context.dart';
import 'package:datastore_renderer/src/ui/ui_shape_painter.dart';

class ShapePainterCircle extends UiShapePainter<RenderinstructionCircle> {
  late final UiPaint? fill;

  late final UiPaint? stroke;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePainterCircle._(RenderinstructionCircle renderinstruction) : super(renderinstruction) {
    if (!renderinstruction.isFillTransparent()) {
      fill = UiPaint.fill(color: renderinstruction.fillColor);
    } else {
      fill = null;
    }
    if (!renderinstruction.isStrokeTransparent()) {
      stroke = UiPaint.stroke(
        color: renderinstruction.strokeColor,
        strokeWidth: renderinstruction.strokeWidth,
        cap: renderinstruction.strokeCap,
        join: renderinstruction.strokeJoin,
        strokeDasharray: renderinstruction.strokeDashArray,
      );
    } else {
      stroke = null;
    }
  }

  static Future<ShapePainterCircle> create(RenderinstructionCircle renderinstruction) async {
    return _taskQueue.add(() async {
      if (renderinstruction.shapePainter != null) return renderinstruction.shapePainter! as ShapePainterCircle;
      ShapePainterCircle shapePaint = ShapePainterCircle._(renderinstruction);
      renderinstruction.shapePainter = shapePaint;
      return shapePaint;
    });
  }

  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    RelativeMappoint relative = nodeProperties.getCoordinatesAbsolute().offset(renderContext.reference);
    relative = relative.offset(0, renderinstruction.dy);
    if (fill != null) renderContext.canvas.drawCircle(relative.dx, relative.dy, renderinstruction.radius, fill!);
    if (stroke != null) renderContext.canvas.drawCircle(relative.dx, relative.dy, renderinstruction.radius, stroke!);
  }

  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {}
}
