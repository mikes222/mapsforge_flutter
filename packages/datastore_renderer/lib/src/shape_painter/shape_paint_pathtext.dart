import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/model/ui_render_context.dart';
import 'package:datastore_renderer/src/ui/paragraph_cache.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_shape_painter.dart';
import 'package:datastore_renderer/src/ui/ui_text_paint.dart';
import 'package:datastore_renderer/src/util/waydecorator.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintPathtext extends UiShapePainter<RenderinstructionPathtext> {
  late final UiPaint? paintBack;

  late final UiPaint? paintFront;

  late final UiTextPaint textPaint;

  late final ParagraphEntry back;

  late LineSegmentPath fullPath;

  final String caption;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintPathtext._(RenderinstructionPathtext renderinstruction, this.caption, LineSegmentPath stringPath) : super(renderinstruction) {
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

    back = ParagraphCache().getEntry(caption, textPaint, paintBack!, renderinstruction.maxTextWidth);
    fullPath = WayDecorator.reducePathForText(stringPath, back.getWidth());
  }

  static Future<ShapePaintPathtext> create(RenderinstructionPathtext renderinstruction, String caption, LineSegmentPath stringPath) async {
    return _taskQueue.add(() async {
      //if (shape.shapePaint != null) return shape.shapePaint! as ShapePaintPathtext;
      ShapePaintPathtext shapePaint = ShapePaintPathtext._(renderinstruction, caption, stringPath);
      //await shapePaint.init(symbolCache);
      //shape.shapePaint = shapePaint;
      return shapePaint;
    });
  }

  calculateBoundaryAbsolute() {
    // a way text container should always run left to right, but I leave this in because it might matter
    // if we support right-to-left text.
    // we also need to make the container larger by textHeight as otherwise the end points do
    // not correctly reflect the size of the text on screen
    // this.boundaryAbsolute = lineString.getBounds().enlarge(
    //     textHeight / 2, textHeight / 2, textHeight / 2, textHeight / 2);
  }

  @override
  void renderNode(RenderContext renderContext, NodeProperties nodeProperties) {}

  @override
  void renderWay(RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (fullPath.segments.isEmpty) return;

    if (paintBack != null) {
      renderContext.canvas.drawPathText(caption, fullPath, renderContext.reference, this.paintBack!, textPaint, renderinstruction.maxTextWidth);
    }
    if (paintFront != null) {
      renderContext.canvas.drawPathText(caption, fullPath, renderContext.reference, this.paintFront!, textPaint, renderinstruction.maxTextWidth);
    }
  }

  @override
  MapRectangle getBoundary() {
    throw UnimplementedError("Nodes not supported");
  }
}
