import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_matrix.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_render_context.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_shape_painter.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// Shape painter for rendering symbols along a line.
///
/// This painter is responsible for drawing a symbol at each node of a way.
/// The symbol can be rotated to align with the direction of the line.
class ShapePainterLinesymbol extends UiShapePainter<RenderinstructionLinesymbol> {
  static final _log = Logger('ShapePainterLinesymbol');

  late final UiPaint fill;

  SymbolImage? symbolImage;

  static final TaskQueue _taskQueue = SimpleTaskQueue(name: "ShapePainterLinesymbol");

  ShapePainterLinesymbol._(super.renderinstruction) {
    fill = UiPaint.fill(color: 0xff000000);
  }

  /// Initializes the shape painter by loading the symbol from the cache.
  Future<void> init() async {
    try {
      symbolImage =
          await SymbolCacheMgr().getOrCreateSymbol(renderinstruction.bitmapSrc!, renderinstruction.getBitmapWidth(), renderinstruction.getBitmapHeight())
            ?..clone();
    } catch (error) {
      _log.warning("Error loading bitmap ${renderinstruction.bitmapSrc}", error);
    }
  }

  @override
  /// Disposes the [symbolImage].
  @override
  void dispose() {
    symbolImage?.dispose();
    symbolImage = null;
  }

  /// Creates a new linesymbol shape painter with asynchronous initialization.
  ///
  /// Uses a task queue to ensure thread-safe creation and caches the result
  /// in the rendering instruction to avoid duplicate creation.
  static Future<ShapePainterLinesymbol> create(RenderinstructionLinesymbol renderinstruction) {
    return _taskQueue.add(() async {
      ShapePainterLinesymbol? shapePainter = PainterFactory().getPainterForSerial(renderinstruction.serial) as ShapePainterLinesymbol?;
      if (shapePainter != null) return shapePainter;
      shapePainter = ShapePainterLinesymbol._(renderinstruction);
      await shapePainter.init();
      PainterFactory().setPainterForSerial(renderinstruction.serial, shapePainter);
      return shapePainter;
    });
  }

  /// Renders a symbol for a node.
  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {
    if (symbolImage == null) return;
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (renderInfo is! RenderInfoNode) throw Exception("renderInfo is not RenderInfoNode ${renderInfo.runtimeType}");

    Mappoint previous = nodeProperties.getCoordinatesAbsolute();
    MapRectangle boundary = symbolImage!.getBoundary();

    MappointRelative relative = previous.offset(renderContext.reference).offset(0, renderinstruction.dy);

    UiMatrix? matrix;
    if (renderinstruction.rotate) {
      // if we do not rotate theta will be 0, which is correct
      double radians = renderInfo.rotateRadians;
      if (radians != 0) {
        matrix = UiMatrix();
        matrix.rotate(radians, pivotX: boundary.left, pivotY: boundary.top);
      }
    }

    renderContext.canvas.drawPicture(
      symbolImage: symbolImage!,
      matrix: matrix,
      left: relative.dx + boundary.left,
      top: relative.dy + boundary.top,
      paint: fill,
    );

    // renderContext.canvas.drawCircle(relative.dx + boundary.left, relative.dy + boundary.top, 5, UiPaint.fill(color: 0xffff0000));
    // renderContext.canvas.drawCircle(relative.dx, relative.dy, boundary.getWidth() / 2, UiPaint.stroke(color: 0x80ff0000));
  }

  /// Line symbols are rendered per node, not for the entire way at once.
  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {}
}
