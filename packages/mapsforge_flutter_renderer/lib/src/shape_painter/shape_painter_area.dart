import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_path.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_render_context.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_shape_painter.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// Shape painter for rendering filled polygon areas on the map canvas.
///
/// This painter handles the rendering of closed polygon areas such as buildings,
/// parks, water bodies, and other filled regions. It supports both solid fill
/// colors and bitmap pattern fills, along with optional stroke outlines.
///
/// Key features:
/// - Solid color fills and bitmap pattern fills
/// - Stroke outlines with customizable properties
/// - Asynchronous initialization for bitmap loading
/// - Task queue management for thread safety
class ShapePainterArea extends UiShapePainter<RenderinstructionArea> {
  static final _log = Logger('ShapePainterArea');

  /// Paint object for area fill rendering, null if transparent.
  UiPaint? fill;

  /// Paint object for area stroke rendering, null if transparent.
  late final UiPaint? stroke;

  /// Task queue for managing asynchronous painter creation.
  static final TaskQueue _taskQueue = SimpleTaskQueue(name: "ShapePainterArea");

  /// Private constructor for creating area shape painters.
  ///
  /// Initializes fill and stroke paint objects based on the rendering instruction
  /// configuration. Transparent fills and strokes are set to null for optimization.
  ///
  /// [renderinstruction] Area rendering instruction with styling parameters
  ShapePainterArea._(RenderinstructionArea renderinstruction) : super(renderinstruction) {
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

  /// Creates a new area shape painter with asynchronous initialization.
  ///
  /// Uses a task queue to ensure thread-safe creation and caches the result
  /// in the rendering instruction to avoid duplicate creation.
  ///
  /// [renderinstruction] Area rendering instruction to create painter for
  /// Returns initialized area shape painter
  static Future<ShapePainterArea> create(RenderinstructionArea renderinstruction) async {
    return _taskQueue.add(() async {
      ShapePainterArea? shapePainter = PainterFactory().getPainterForSerial(renderinstruction.serial) as ShapePainterArea?;
      if (shapePainter != null) return shapePainter;
      shapePainter = ShapePainterArea._(renderinstruction);
      await shapePainter.init();
      PainterFactory().setPainterForSerial(renderinstruction.serial, shapePainter);
      return shapePainter;
    });
  }

  /// Initializes the shape painter by loading bitmap patterns if specified.
  ///
  /// Loads bitmap images from the symbol cache for pattern fills and
  /// configures the fill paint accordingly.
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

  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {}

  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    UiPath path = calculatePath(wayProperties.getCoordinatesAbsolute(), renderContext.reference, renderinstruction.dy);
    if (fill != null) renderContext.canvas.drawPath(path, fill!);
    if (stroke != null) renderContext.canvas.drawPath(path, stroke!);
  }
}
