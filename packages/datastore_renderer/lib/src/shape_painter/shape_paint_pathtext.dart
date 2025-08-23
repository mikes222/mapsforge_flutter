import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/model/ui_render_context.dart';
import 'package:datastore_renderer/src/ui/paragraph_cache.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_shape_painter.dart';
import 'package:datastore_renderer/src/ui/ui_text_paint.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintPathtext extends UiShapePainter<RenderinstructionPathtext> {
  late final UiPaint? paintBack;

  late final UiPaint? paintFront;

  late final UiTextPaint textPaint;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintPathtext._(RenderinstructionPathtext renderinstruction) : super(renderinstruction) {
    if (!renderinstruction.isFillTransparent()) paintFront = UiPaint.fill(color: renderinstruction.fillColor);
    if (!renderinstruction.isStrokeTransparent()) {
      paintBack = UiPaint.stroke(
        color: renderinstruction.strokeColor,
        strokeWidth: renderinstruction.strokeWidth,
        cap: renderinstruction.strokeCap,
        join: renderinstruction.strokeJoin,
        strokeDasharray: renderinstruction.strokeDashArray,
      );
    }
    textPaint = UiTextPaint();
    textPaint.setFontFamily(renderinstruction.fontFamily);
    textPaint.setFontStyle(renderinstruction.fontStyle);
    textPaint.setTextSize(renderinstruction.fontSize);
  }

  static Future<ShapePaintPathtext> create(RenderinstructionPathtext renderinstruction) async {
    return _taskQueue.add(() async {
      //if (shape.shapePaint != null) return shape.shapePaint! as ShapePaintPathtext;
      ShapePaintPathtext shapePaint = ShapePaintPathtext._(renderinstruction);
      //await shapePaint.init(symbolCache);
      renderinstruction.shapePainter = shapePaint;
      return shapePaint;
    });
  }

  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (renderInfo is! RenderInfoNode) throw Exception("renderInfo is not RenderInfoNode ${renderInfo.runtimeType}");

    RelativeMappoint relative = nodeProperties.getCoordinatesAbsolute().offset(renderContext.reference).offset(0, renderinstruction.dy);
    if (paintBack != null) {
      ParagraphEntry entry = ParagraphCache().getEntry(renderInfo.caption!, textPaint, paintBack!, renderinstruction.maxTextWidth);
      renderContext.canvas.drawTextRotated(entry.paragraph, renderInfo.rotateRadians, relative);
    }
    if (paintFront != null) {
      ParagraphEntry entry = ParagraphCache().getEntry(renderInfo.caption!, textPaint, paintFront!, renderinstruction.maxTextWidth);
      renderContext.canvas.drawTextRotated(entry.paragraph, renderInfo.rotateRadians, relative);
    }
  }

  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {}
}
