import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_render_context.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_shape_painter.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// Shape painter for rendering circles on the map.
///
/// This painter is responsible for drawing circles, typically for POIs, with
/// specified fill and stroke properties.
class ShapePainterCircle extends UiShapePainter<RenderinstructionCircle> {
  /// The paint used for the circle fill. Null if the fill is transparent.
  late final UiPaint? fill;

  /// The paint used for the circle stroke. Null if the stroke is transparent.
  late final UiPaint? stroke;

  static final TaskQueue _taskQueue = SimpleTaskQueue(name: "ShapePainterCircle");

  /// Creates a new circle shape painter.
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

  /// Creates a new circle shape painter with asynchronous initialization.
  ///
  /// Uses a task queue to ensure thread-safe creation and caches the result
  /// in the rendering instruction to avoid duplicate creation.
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
  /// Renders a circle for a node (e.g., a POI).
  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    MappointRelative relative = nodeProperties.getCoordinatesAbsolute().offset(renderContext.reference);
    relative = relative.offset(0, renderinstruction.dy);
    if (fill != null) renderContext.canvas.drawCircle(relative.dx, relative.dy, renderinstruction.radius, fill!);
    if (stroke != null) renderContext.canvas.drawCircle(relative.dx, relative.dy, renderinstruction.radius, stroke!);
  }

  /// Circles are not rendered for ways.
  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {}
}
