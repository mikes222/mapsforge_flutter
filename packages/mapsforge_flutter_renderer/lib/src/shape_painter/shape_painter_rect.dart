import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_rect.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_render_context.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_shape_painter.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// Shape painter for rendering rectangles on the map.
///
/// This painter is responsible for drawing rectangles, which can be used to
/// represent building footprints or other rectangular areas. It supports both
/// solid fill colors and bitmap pattern fills, along with optional stroke outlines.
class ShapePainterRect extends UiShapePainter<RenderinstructionRect> {
  static final _log = Logger('ShapePainterRect');

  /// The paint used for the rectangle fill. Null if the fill is transparent.
  UiPaint? fill;

  /// The paint used for the rectangle stroke. Null if the stroke is transparent.
  late final UiPaint? stroke;

  static final TaskQueue _taskQueue = SimpleTaskQueue(name: "ShapePainterRect");

  /// Creates a new rectangle shape painter.
  ShapePainterRect._(RenderinstructionRect renderinstruction) : super(renderinstruction) {
    if (!renderinstruction.isFillTransparent()) {
      fill = UiPaint.fill(color: renderinstruction.fillColor);
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

  /// Creates a new rectangle shape painter with asynchronous initialization.
  ///
  /// Uses a task queue to ensure thread-safe creation and caches the result
  /// in the rendering instruction to avoid duplicate creation.
  static Future<ShapePainterRect> create(RenderinstructionRect renderinstruction) {
    return _taskQueue.add(() async {
      ShapePainterRect? shapePainter = PainterFactory().getPainterForSerial(renderinstruction.serial) as ShapePainterRect?;
      if (shapePainter != null) return shapePainter;
      shapePainter = ShapePainterRect._(renderinstruction);
      await shapePainter.init();
      PainterFactory().setPainterForSerial(renderinstruction.serial, shapePainter);
      return shapePainter;
    });
  }

  /// Initializes the shape painter by loading the bitmap pattern if specified.
  Future<void> init() async {
    if (renderinstruction.bitmapSrc != null) {
      try {
        SymbolImage? symbolImage = await SymbolCacheMgr().getOrCreateSymbol(
          renderinstruction.bitmapSrc!,
          renderinstruction.getBitmapWidth(),
          renderinstruction.getBitmapHeight(),
        );
        if (symbolImage == null) return;
        fill ??= UiPaint.fill();
        fill!.setBitmapShader(symbolImage);
        //symbolImage.dispose();
      } catch (error) {
        _log.warning("Error loading bitmap ${renderinstruction.bitmapSrc}", error);
      }
    }
  }

  /// Rectangles are not rendered for nodes.
  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {}

  /// Renders a rectangle for a way.
  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    MapRectangle rectangle = wayProperties.getBoundaryAbsolute().offset(renderContext.reference);
    UiRect rect = UiRect(rectangle.left, rectangle.top, rectangle.right, rectangle.bottom);
    if (fill != null) renderContext.canvas.drawRect(rect, fill!);
    if (stroke != null) renderContext.canvas.drawRect(rect, stroke!);
  }
}
