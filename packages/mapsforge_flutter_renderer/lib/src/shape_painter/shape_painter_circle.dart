import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_render_context.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_shape_painter.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

class ShapePainterCircle extends UiShapePainter<RenderinstructionCircle> {
  late final UiPaint? fill;

  late final UiPaint? stroke;

  static final TaskQueue _taskQueue = SimpleTaskQueue(name: "ShapePainterCircle");

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
      ShapePainterCircle? shapePainter = PainterFactory().getPainterForSerial(renderinstruction.serial) as ShapePainterCircle?;
      if (shapePainter != null) return shapePainter;
      shapePainter = ShapePainterCircle._(renderinstruction);
      PainterFactory().setPainterForSerial(renderinstruction.serial, shapePainter);
      return shapePainter;
    });
  }

  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    MappointRelative relative = nodeProperties.getCoordinatesAbsolute().offset(renderContext.reference);
    relative = relative.offset(0, renderinstruction.dy);
    if (fill != null) renderContext.canvas.drawCircle(relative.dx, relative.dy, renderinstruction.radius, fill!);
    if (stroke != null) renderContext.canvas.drawCircle(relative.dx, relative.dy, renderinstruction.radius, stroke!);
  }

  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {}
}
