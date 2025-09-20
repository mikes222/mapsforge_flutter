import 'dart:math';
import 'dart:ui' as ui;

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

/// Shape painter for rendering text captions on the map.
///
/// This painter is responsible for drawing text labels for nodes (e.g., POIs)
/// and ways (e.g., streets). It handles text styling, including fill and stroke
/// (for halo effects), font properties, and positioning. It also manages text
/// rotation to ensure labels remain horizontal even when the map is rotated.
class ShapePainterCaption extends UiShapePainter<RenderinstructionCaption> {
  /// The paint used for the text stroke (halo). Null if the stroke is transparent.
  UiPaint? paintBack;

  /// The paint used for the text fill. Null if the fill is transparent.
  UiPaint? paintFront;

  late UiTextPaint textPaint;

  static final TaskQueue _taskQueue = SimpleTaskQueue(name: "ShapePainterCaption");

  ShapePainterCaption._(super.renderinstruction) {
    reinit();
  }

  // ShapePaintCaption.forMarker(ShapeCaption shape, {required String caption}) : super(shape) {
  //   reinit(caption);
  // }

  /// Creates a new caption shape painter with asynchronous initialization.
  ///
  /// Uses a task queue to ensure thread-safe creation and caches the result
  /// in the rendering instruction to avoid duplicate creation.
  static Future<ShapePainterCaption> create(RenderinstructionCaption renderinstruction) async {
    return _taskQueue.add(() async {
      ShapePainterCaption? shapePainter = PainterFactory().getPainterForSerial(renderinstruction.serial) as ShapePainterCaption?;
      if (shapePainter != null) return shapePainter;
      shapePainter = ShapePainterCaption._(renderinstruction);
      PainterFactory().setPainterForSerial(renderinstruction.serial, shapePainter);
      return shapePainter;
    });
  }

  /// (Re)Initializes the paint objects based on the current render instruction.
  void reinit() {
    paintFront = null;
    paintBack = null;
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

  /// Renders a caption for a node (e.g., a POI).
  ///
  /// The caption is drawn at the node's coordinates, adjusted for rotation
  /// to remain horizontal.
  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    //print("paint caption: $front $back $shape");

    MappointRelative relative = nodeProperties.getCoordinatesAbsolute().offset(renderContext.reference).offset(0, renderinstruction.dy);
    ui.Canvas? uiCanvas = renderContext.canvas.expose();
    if (renderContext.rotationRadian != 0) {
      uiCanvas.save();
      uiCanvas.translate(relative.dx, relative.dy);
      // if the map is rotated 30° clockwise we have to paint the caption -30° (counter-clockwise) so that it is horizontal
      uiCanvas.rotate(-renderContext.rotationRadian);
      uiCanvas.translate(-relative.dx, -relative.dy);
    }

    ParagraphEntry? front;
    ParagraphEntry? back;
    if (paintFront != null) front = ParagraphCacheMgr().getEntry(renderInfo.caption!, textPaint, paintFront!, renderinstruction.getMaxTextWidth());
    if (paintBack != null) back = ParagraphCacheMgr().getEntry(renderInfo.caption!, textPaint, paintBack!, renderinstruction.getMaxTextWidth());

    MapRectangle boundary = renderinstruction.calculateBoundaryWithSymbol(
      renderinstruction.position,
      back?.getWidth() ?? front?.getWidth() ?? 0,
      back?.getHeight() ?? front?.getHeight() ?? 0,
    );
    // print(
    //   "paint caption boundar: $boundary, symbolboundary: ${renderinstruction.symbolBoundary}, ${renderInfo.caption} and position ${renderinstruction.position}",
    // );
    // uiCanvas.drawRect(
    //   ui.Rect.fromLTWH(relative.dx + boundary.left, relative.dy + boundary.top, boundary.getWidth(), boundary.getHeight()),
    //   ui.Paint()..color = Colors.red.withOpacity(0.5),
    // );
    if (back != null) uiCanvas.drawParagraph(back.paragraph, ui.Offset(relative.dx + boundary.left, relative.dy + boundary.top));
    if (front != null) uiCanvas.drawParagraph(front.paragraph, ui.Offset(relative.dx + boundary.left, relative.dy + boundary.top));
    //uiCanvas.drawCircle(ui.Offset(relative.dx, relative.dy), 10, ui.Paint()..color = Colors.green.withOpacity(0.5));
    if (renderContext.rotationRadian != 0) {
      uiCanvas.restore();
    }
  }

  /// Renders a caption for a way (e.g., a street name).
  ///
  /// The caption is drawn at the center of the way's bounding box, adjusted
  /// for rotation to remain horizontal.
  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    MappointRelative relative = wayProperties.getCenterAbsolute(renderContext.projection).offset(renderContext.reference).offset(0, renderinstruction.dy);
    //print("paint caption boundar: $boundary $relative ${shape}");

    ui.Canvas? uiCanvas = renderContext.canvas.expose();
    if (renderContext.rotationRadian != 0) {
      uiCanvas.save();
      uiCanvas.translate(relative.dx, relative.dy);
      // if the map is rotated 30° clockwise we have to paint the caption -30° (counter-clockwise) so that it is horizontal
      uiCanvas.rotate(2 * pi - renderContext.rotationRadian);
      uiCanvas.translate(-relative.dx, -relative.dy);
    }

    ParagraphEntry? front;
    ParagraphEntry? back;
    if (paintFront != null) front = ParagraphCacheMgr().getEntry(renderInfo.caption!, textPaint, paintFront!, renderinstruction.getMaxTextWidth());
    if (paintBack != null) back = ParagraphCacheMgr().getEntry(renderInfo.caption!, textPaint, paintBack!, renderinstruction.getMaxTextWidth());

    MapRectangle boundary = renderinstruction.calculateBoundaryWithSymbol(
      renderinstruction.position,
      back?.getWidth() ?? front?.getWidth() ?? 0,
      back?.getHeight() ?? front?.getHeight() ?? 0,
    );
    // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(relative.x + boundary.left, relative.y + boundary.top,
    //         boundary.getWidth(), boundary.getHeight()),
    //     ui.Paint()..color = Colors.red.withOpacity(0.5));

    if (back != null) uiCanvas.drawParagraph(back.paragraph, ui.Offset(relative.dx + boundary.left, relative.dy + boundary.top));
    if (front != null) uiCanvas.drawParagraph(front.paragraph, ui.Offset(relative.dx + boundary.left, relative.dy + boundary.top));
    // uiCanvas.drawCircle(ui.Offset(this.xy.x - origin.x, this.xy.y - origin.y),
    //     5, ui.Paint()..color = Colors.blue);
    if (renderContext.rotationRadian != 0) {
      uiCanvas.restore();
    }
  }
}
