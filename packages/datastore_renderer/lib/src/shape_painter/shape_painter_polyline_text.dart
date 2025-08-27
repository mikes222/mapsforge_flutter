import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/model/ui_render_context.dart';
import 'package:datastore_renderer/src/ui/paragraph_cache.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_shape_painter.dart';
import 'package:datastore_renderer/src/ui/ui_text_paint.dart';
import 'package:task_queue/task_queue.dart';

class ShapePainterPolylineText extends UiShapePainter<RenderinstructionPolylineText> {
  late final UiPaint? paintBack;

  late final UiPaint? paintFront;

  late final UiTextPaint textPaint;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePainterPolylineText._(RenderinstructionPolylineText renderinstruction) : super(renderinstruction) {
    if (!renderinstruction.isFillTransparent()) {
      paintFront = UiPaint.fill(color: renderinstruction.fillColor);
    } else {
      paintFront = null;
    }
    if (!renderinstruction.isStrokeTransparent()) {
      paintBack = UiPaint.stroke(
        color: renderinstruction.strokeColor,
        strokeWidth: renderinstruction.strokeWidth,
        cap: renderinstruction.strokeCap,
        join: renderinstruction.strokeJoin,
        strokeDasharray: renderinstruction.strokeDashArray,
      );
    } else {
      paintBack = null;
    }
    textPaint = UiTextPaint();
    textPaint.setFontFamily(renderinstruction.fontFamily);
    textPaint.setFontStyle(renderinstruction.fontStyle);
    textPaint.setTextSize(renderinstruction.fontSize);
  }

  static Future<ShapePainterPolylineText> create(RenderinstructionPolylineText renderinstruction) async {
    return _taskQueue.add(() async {
      //if (shape.shapePaint != null) return shape.shapePaint! as ShapePaintPathtext;
      ShapePainterPolylineText shapePaint = ShapePainterPolylineText._(renderinstruction);
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

  /// PolylineTextMarker uses this method
  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (renderInfo is! RenderInfoWay) throw Exception("renderInfo is not RenderInfoWay ${renderInfo.runtimeType}");

    LineSegmentPath? lineSegmentPath = wayProperties.calculateStringPath(renderinstruction.dy);
    if (lineSegmentPath == null || lineSegmentPath.segments.isEmpty) {
      return;
    }

    double widthEstimated = renderinstruction.maxTextWidth;
    lineSegmentPath = lineSegmentPath.reducePathForText(widthEstimated, renderinstruction.repeatStart, renderinstruction.repeatGap);
    if (lineSegmentPath.segments.isEmpty) return;

    for (var segment in lineSegmentPath.segments) {
      // So text isn't upside down
      bool doInvert = segment.end.x <= segment.start.x;
      Mappoint start;
      double diff = (segment.length() - widthEstimated) / 2;
      if (doInvert) {
        start = segment.pointAlongLineSegment(diff + widthEstimated);
      } else {
        start = segment.pointAlongLineSegment(diff);
      }

      if (paintBack != null) {
        ParagraphEntry entry = ParagraphCache().getEntry(renderInfo.caption!, textPaint, paintBack!, renderinstruction.maxTextWidth);
        renderContext.canvas.drawTextRotated(entry.paragraph, renderContext.rotationRadian + segment.getTheta(), start.offset(renderContext.reference));
      }
      if (paintFront != null) {
        ParagraphEntry entry = ParagraphCache().getEntry(renderInfo.caption!, textPaint, paintFront!, renderinstruction.maxTextWidth);
        renderContext.canvas.drawTextRotated(entry.paragraph, renderContext.rotationRadian + segment.getTheta(), start.offset(renderContext.reference));
      }
    }
  }
}
