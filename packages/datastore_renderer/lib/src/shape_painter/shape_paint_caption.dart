import 'dart:math';
import 'dart:ui' as ui;

import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/model/ui_render_context.dart';
import 'package:datastore_renderer/src/ui/paragraph_cache.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_shape_painter.dart';
import 'package:datastore_renderer/src/ui/ui_text_paint.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintCaption extends UiShapePainter<RenderinstructionCaption> {
  // this is the stroke, normally white and represents the "surrounding of the text"
  UiPaint? paintBack;

  /// This is the fill, normally black and represents the text itself
  UiPaint? paintFront;

  late UiTextPaint textPaint;

  ParagraphEntry? front;

  ParagraphEntry? back;

  /// The width of the caption. Since we cannot calculate the width in an isolate (ui calls are not allowed)
  /// we need to set it later on in the ShapePaintCaption
  double _fontWidth = 0;

  /// The height of the caption. Since we cannot calculate the height in an isolate (ui calls are not allowed)
  /// we need to set it later on in the ShapePaintCaption
  double _fontHeight = 0;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintCaption._(RenderinstructionCaption renderinstruction, {required String caption}) : super(renderinstruction) {
    reinit(caption);
  }

  // ShapePaintCaption.forMarker(ShapeCaption shape, {required String caption}) : super(shape) {
  //   reinit(caption);
  // }

  static Future<ShapePaintCaption> create(RenderinstructionCaption renderinstructionCaption, {required String caption}) async {
    return _taskQueue.add(() async {
      //if (shape.shapePaint != null) return shape.shapePaint! as ShapePaintCaption;
      ShapePaintCaption shapePaint = ShapePaintCaption._(renderinstructionCaption, caption: caption);
      //await shapePaint.init(symbolCache);
      //shape.shapePaint = shapePaint;
      return shapePaint;
    });
  }

  void reinit(String caption) {
    paintFront = null;
    paintBack = null;
    front = null;
    back = null;
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
    setCaption(caption);
  }

  void setCaption(String caption) {
    if (paintFront != null) front = ParagraphCache().getEntry(caption, textPaint, paintFront!, renderinstruction.maxTextWidth);
    if (paintBack != null) back = ParagraphCache().getEntry(caption, textPaint, paintBack!, renderinstruction.maxTextWidth);
    _fontWidth = back?.getWidth() ?? front?.getWidth() ?? 0;
    _fontHeight = back?.getHeight() ?? front?.getHeight() ?? 0;
  }

  @override
  void renderNode(RenderInfo renderInfo, RenderContext renderContext, NodeProperties nodeProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    //print("paint caption: $front $back $shape");

    RelativeMappoint relative = nodeProperties.getCoordinatesAbsolute().offset(renderContext.reference).offset(0, renderinstruction.dy);
    ui.Canvas? uiCanvas = renderContext.canvas.expose();
    if (renderContext.rotationRadian != 0) {
      uiCanvas.save();
      uiCanvas.translate(relative.dx, relative.dy);
      // if the map is rotated 30° clockwise we have to paint the caption -30° (counter-clockwise) so that it is horizontal
      uiCanvas.rotate(2 * pi - renderContext.rotationRadian);
      uiCanvas.translate(-relative.dx, -relative.dy);
    }
    MapRectangle boundary = renderinstruction.calculateBoundaryWithSymbol(
      renderinstruction.position,
      back?.getWidth() ?? front?.getWidth() ?? 0,
      back?.getHeight() ?? front?.getHeight() ?? 0,
    );
    // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(relative.x + boundary.left, relative.y + boundary.top,
    //         boundary.getWidth(), boundary.getHeight()),
    //     ui.Paint()..color = Colors.red.withOpacity(0.5));
    if (back != null) uiCanvas.drawParagraph(back!.paragraph, ui.Offset(relative.dx + boundary.left, relative.dy + boundary.top));
    if (front != null) uiCanvas.drawParagraph(front!.paragraph, ui.Offset(relative.dx + boundary.left, relative.dy + boundary.top));
    // uiCanvas.drawCircle(ui.Offset(relative.x, relative.y), 10,
    //     ui.Paint()..color = Colors.green.withOpacity(0.5));
    if (renderContext.rotationRadian != 0) {
      uiCanvas.restore();
    }
  }

  @override
  void renderWay(RenderInfo renderInfo, RenderContext renderContext, WayProperties wayProperties) {
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    RelativeMappoint relative = wayProperties.getCenterAbsolute(renderContext.projection).offset(renderContext.reference).offset(0, renderinstruction.dy);
    //print("paint caption boundar: $boundary $relative ${shape}");

    ui.Canvas? uiCanvas = renderContext.canvas.expose();
    if (renderContext.rotationRadian != 0) {
      uiCanvas.save();
      uiCanvas.translate(relative.dx, relative.dy);
      // if the map is rotated 30° clockwise we have to paint the caption -30° (counter-clockwise) so that it is horizontal
      uiCanvas.rotate(2 * pi - renderContext.rotationRadian);
      uiCanvas.translate(-relative.dx, -relative.dy);
    }

    MapRectangle boundary = renderinstruction.calculateBoundaryWithSymbol(
      renderinstruction.position,
      back?.getWidth() ?? front?.getWidth() ?? 0,
      back?.getHeight() ?? front?.getHeight() ?? 0,
    );
    // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(relative.x + boundary.left, relative.y + boundary.top,
    //         boundary.getWidth(), boundary.getHeight()),
    //     ui.Paint()..color = Colors.red.withOpacity(0.5));

    if (back != null) uiCanvas.drawParagraph(back!.paragraph, ui.Offset(relative.dx + boundary.left, relative.dy + boundary.top));
    if (front != null) uiCanvas.drawParagraph(front!.paragraph, ui.Offset(relative.dx + boundary.left, relative.dy + boundary.top));
    // uiCanvas.drawCircle(ui.Offset(this.xy.x - origin.x, this.xy.y - origin.y),
    //     5, ui.Paint()..color = Colors.blue);
    if (renderContext.rotationRadian != 0) {
      uiCanvas.restore();
    }
  }
}
