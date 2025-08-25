import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/cache/symbol_cache_mgr.dart';
import 'package:datastore_renderer/src/model/ui_render_context.dart';
import 'package:datastore_renderer/src/ui/symbol_image.dart';
import 'package:datastore_renderer/src/ui/ui_matrix.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_shape_painter.dart';
import 'package:logging/logging.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintLinesymbol extends UiShapePainter<RenderinstructionLinesymbol> {
  static final _log = Logger('ShapePaintLinesymbol');

  late final UiPaint fill;

  SymbolImage? symbolImage;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintLinesymbol._(RenderinstructionLinesymbol renderinstruction) : super(renderinstruction) {
    fill = UiPaint.fill(color: 0xff000000);
  }

  Future<void> init() async {
    try {
      symbolImage = await SymbolCacheMgr().getOrCreateSymbol(
        renderinstruction.bitmapSrc!,
        renderinstruction.getBitmapWidth(),
        renderinstruction.getBitmapHeight(),
      );
    } catch (error) {
      _log.warning("Error loading bitmap ${renderinstruction.bitmapSrc}", error);
    }
  }

  void dispose() {
    symbolImage?.dispose();
  }

  static Future<ShapePaintLinesymbol> create(RenderinstructionLinesymbol renderinstruction) async {
    return _taskQueue.add(() async {
      if (renderinstruction.shapePainter != null) return renderinstruction.shapePainter! as ShapePaintLinesymbol;
      ShapePaintLinesymbol shapePaint = ShapePaintLinesymbol._(renderinstruction);
      await shapePaint.init();
      renderinstruction.shapePainter = shapePaint;
      return shapePaint;
    });
  }

  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {
    if (symbolImage == null) return;
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (renderInfo is! RenderInfoNode) throw Exception("renderInfo is not RenderInfoNode ${renderInfo.runtimeType}");

    Mappoint previous = nodeProperties.getCoordinatesAbsolute();
    MapRectangle boundary = symbolImage!.getBoundary();

    RelativeMappoint relative = previous.offset(renderContext.reference).offset(0, renderinstruction.dy);

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

  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {}
}
