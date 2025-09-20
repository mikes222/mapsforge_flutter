import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_renderer/shape_painter.dart';
import 'package:mapsforge_flutter_renderer/src/ui/paragraph_cache_mgr.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_render_context.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_shape_painter.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_text_paint.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/renderinstruction.dart';

/// Shape painter for rendering text along a polyline.
///
/// This painter is responsible for drawing text that follows the path of a line,
/// such as a street name. It handles text styling, including fill and stroke
/// (for halo effects), and calculates the correct position and rotation for the
/// text along the line.
class ShapePainterPolylineText extends UiShapePainter<RenderinstructionPolylineText> {
  /// The paint used for the text stroke (halo). Null if the stroke is transparent.
  late final UiPaint? paintBack;

  /// The paint used for the text fill. Null if the fill is transparent.
  late final UiPaint? paintFront;

  late final UiTextPaint textPaint;

  static final TaskQueue _taskQueue = SimpleTaskQueue(name: "ShapePainterPolylineText");

  /// Creates a new polyline text shape painter.
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

  /// Creates a new polyline text shape painter with asynchronous initialization.
  ///
  /// Uses a task queue to ensure thread-safe creation and caches the result
  /// in the rendering instruction to avoid duplicate creation.
  static Future<ShapePainterPolylineText> create(RenderinstructionPolylineText renderinstruction) async {
    return _taskQueue.add(() async {
      ShapePainterPolylineText? shapePainter = PainterFactory().getPainterForSerial(renderinstruction.serial) as ShapePainterPolylineText?;
      if (shapePainter != null) return shapePainter;
      shapePainter = ShapePainterPolylineText._(renderinstruction);
      PainterFactory().setPainterForSerial(renderinstruction.serial, shapePainter);
      return shapePainter;
    });
  }

  @override
  /// Renders text for a node.
  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (renderInfo is! RenderInfoNode) throw Exception("renderInfo is not RenderInfoNode ${renderInfo.runtimeType}");

    MappointRelative relative = nodeProperties.getCoordinatesAbsolute().offset(renderContext.reference).offset(0, renderinstruction.dy);
    if (paintBack != null) {
      ParagraphEntry entry = ParagraphCacheMgr().getEntry(renderInfo.caption!, textPaint, paintBack!, renderinstruction.getMaxTextWidth());
      renderContext.canvas.drawTextRotated(entry.paragraph, renderInfo.rotateRadians, relative);
    }
    if (paintFront != null) {
      ParagraphEntry entry = ParagraphCacheMgr().getEntry(renderInfo.caption!, textPaint, paintFront!, renderinstruction.getMaxTextWidth());
      renderContext.canvas.drawTextRotated(entry.paragraph, renderInfo.rotateRadians, relative);
    }
  }

  /// Renders text along a way.
  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    if (renderInfo is! RenderInfoWay) throw Exception("renderInfo is not RenderInfoWay ${renderInfo.runtimeType}");

    LineSegmentPath? lineSegmentPath = wayProperties.calculateStringPath(renderinstruction.dy);
    if (lineSegmentPath == null || lineSegmentPath.segments.isEmpty) {
      return;
    }

    MapSize textSize = renderinstruction.getEstimatedTextBoundary(renderInfo.caption!, renderinstruction.strokeWidth);
    lineSegmentPath = lineSegmentPath.reducePathForText(textSize.width, renderinstruction.repeatStart, renderinstruction.repeatGap);
    if (lineSegmentPath.segments.isEmpty) return;

    for (var segment in lineSegmentPath.segments) {
      // So text isn't upside down
      bool doInvert = segment.end.x <= segment.start.x;
      Mappoint start;
      double diff = (segment.length() - textSize.width) / 2;
      if (doInvert) {
        start = segment.pointAlongLineSegment(diff + textSize.width);
      } else {
        start = segment.pointAlongLineSegment(diff);
      }

      if (paintBack != null) {
        ParagraphEntry entry = ParagraphCacheMgr().getEntry(renderInfo.caption!, textPaint, paintBack!, renderinstruction.getMaxTextWidth());
        renderContext.canvas.drawTextRotated(entry.paragraph, renderContext.rotationRadian + segment.getTheta(), start.offset(renderContext.reference));
      }
      if (paintFront != null) {
        ParagraphEntry entry = ParagraphCacheMgr().getEntry(renderInfo.caption!, textPaint, paintFront!, renderinstruction.getMaxTextWidth());
        renderContext.canvas.drawTextRotated(entry.paragraph, renderContext.rotationRadian + segment.getTheta(), start.offset(renderContext.reference));
      }
    }
  }
}
