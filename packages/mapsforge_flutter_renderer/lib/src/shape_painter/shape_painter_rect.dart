import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_rect.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_render_context.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_shape_painter.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

class ShapePainterRect extends UiShapePainter<RenderinstructionRect> {
  UiPaint? fill;

  late final UiPaint? stroke;

  static final TaskQueue _taskQueue = SimpleTaskQueue(name: "ShapePaintRect");

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

  static Future<ShapePainterRect> create(RenderinstructionRect renderinstruction) async {
    return _taskQueue.add(() async {
      if (renderinstruction.shapePainter != null) return renderinstruction.shapePainter! as ShapePainterRect;
      ShapePainterRect shapePaint = ShapePainterRect._(renderinstruction);
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
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {}

  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    MapRectangle rectangle = wayProperties.getBoundaryAbsolute().offset(renderContext.reference);
    UiRect rect = UiRect(rectangle.left, rectangle.top, rectangle.right, rectangle.bottom);
    if (fill != null) renderContext.canvas.drawRect(rect, fill!);
    if (stroke != null) renderContext.canvas.drawRect(rect, stroke!);
  }
}
