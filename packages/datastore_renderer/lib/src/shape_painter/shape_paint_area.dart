import 'package:dart_common/src/model/maprectangle.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/cache/symbol_cache_mgr.dart';
import 'package:datastore_renderer/src/model/ui_render_context.dart';
import 'package:datastore_renderer/src/ui/symbol_image.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_path.dart';
import 'package:datastore_renderer/src/ui/ui_shape_painter.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintArea extends UiShapePainter<RenderinstructionArea> {
  UiPaint? fill;

  late final UiPaint? stroke;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintArea._(RenderinstructionArea renderinstruction) : super(renderinstruction) {
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

  static Future<ShapePaintArea> create(RenderinstructionArea renderinstruction) async {
    return _taskQueue.add(() async {
      if (renderinstruction.shapePainter != null) return renderinstruction.shapePainter! as ShapePaintArea;
      ShapePaintArea shapePaint = ShapePaintArea._(renderinstruction);
      await shapePaint.init();
      renderinstruction.shapePainter = shapePaint;
      return shapePaint;
    });
  }

  Future<void> init() async {
    if (renderinstruction.bitmapSrc != null) {
      SymbolImage? symbolImage = await SymbolCacheMgr().getOrCreateSymbol(
        renderinstruction.bitmapSrc!,
        renderinstruction.getBitmapWidth(),
        renderinstruction.getBitmapHeight(),
      );
      if (symbolImage == null) return;
      fill ??= UiPaint.fill();
      fill!.setBitmapShader(symbolImage);
      symbolImage.dispose();
    }
  }

  @override
  void renderNode(RenderContext renderContext, NodeProperties nodeProperties) {}

  @override
  void renderWay(RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    UiPath path = calculatePath(wayProperties.getCoordinatesAbsolute(), renderContext.reference, renderinstruction.dy);
    if (fill != null) renderContext.canvas.drawPath(path, fill!);
    if (stroke != null) renderContext.canvas.drawPath(path, stroke!);
  }

  @override
  MapRectangle getBoundary() {
    throw UnimplementedError("Nodes not supported");
  }
}
