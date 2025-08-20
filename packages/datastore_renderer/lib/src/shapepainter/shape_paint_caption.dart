import 'dart:math';
import 'dart:ui' as ui;

import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/ui/paragraph_cache.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_text_paint.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintCaption extends ShapePainter<RenderinstructionCaption> {
  // this is the stroke, normally white and represents the "surrounding of the text"
  UiPaint? paintBack;

  /// This is the fill, normally black and represents the text itself
  UiPaint? paintFront;

  late UiTextPaint mapTextPaint;

  ParagraphEntry? front;

  ParagraphEntry? back;

  /// The width of the caption. Since we cannot calculate the width in an isolate (ui calls are not allowed)
  /// we need to set it later on in the ShapePaintCaption
  double _fontWidth = 0;

  /// The height of the caption. Since we cannot calculate the height in an isolate (ui calls are not allowed)
  /// we need to set it later on in the ShapePaintCaption
  double _fontHeight = 0;

  /// The boundary of this object in pixels relative to the center of the
  /// corresponding node or way. This is a cached value.
  MapRectangle? boundary = null;

  static TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintCaption._(ShapeCaption shape, {required String caption}) : super(shape) {
    reinit(caption);
  }

  ShapePaintCaption.forMarker(ShapeCaption shape, {required String caption}) : super(shape) {
    reinit(caption);
  }

  static Future<ShapePaintCaption> create(ShapeCaption shape, SymbolCache symbolCache, {required String caption}) async {
    return _taskQueue.add(() async {
      //if (shape.shapePaint != null) return shape.shapePaint! as ShapePaintCaption;
      ShapePaintCaption shapePaint = ShapePaintCaption._(shape, caption: caption);
      //await shapePaint.init(symbolCache);
      //shape.shapePaint = shapePaint;
      return shapePaint;
    });
  }

  @override
  Future<void> init(SymbolCache symbolCache) {
    return Future.value();
  }

  void reinit(String caption) {
    paintFront = null;
    paintBack = null;
    front = null;
    back = null;
    if (!renderInstruction.isFillTransparent()) paintFront = createPaint(style: Style.FILL, color: renderInstruction.fillColor);
    if (!renderInstruction.isStrokeTransparent())
      paintBack = createPaint(
        style: Style.STROKE,
        color: renderInstruction.strokeColor,
        strokeWidth: renderInstruction.strokeWidth,
        cap: renderInstruction.strokeCap,
        join: renderInstruction.strokeJoin,
        strokeDashArray: renderInstruction.strokeDashArray,
      );
    mapTextPaint = createTextPaint(fontFamily: renderInstruction.fontFamily, fontStyle: renderInstruction.fontStyle, fontSize: renderInstruction.fontSize);
    setCaption(caption);
  }

  void setCaption(String caption) {
    if (paintFront != null) front = ParagraphCache().getEntry(caption, mapTextPaint, paintFront!, renderInstruction.maxTextWidth);
    if (paintBack != null) back = ParagraphCache().getEntry(caption, mapTextPaint, paintBack!, renderInstruction.maxTextWidth);
    _fontWidth = back?.getWidth() ?? front?.getWidth() ?? 0;
    _fontHeight = back?.getHeight() ?? front?.getHeight() ?? 0;
    boundary = renderInstruction.calculateBoundaryWithSymbol(_fontWidth, _fontHeight);
    //print("Boundary for $caption is $boundary and ${shape.position}");
  }

  @override
  MapRectangle calculateBoundary() {
    if (boundary != null) return boundary!;
    return boundary!;
  }

  @override
  void renderNode(MapCanvas canvas, Mappoint coordinatesAbsolute, Mappoint reference, [double rotationRadian = 0]) {
    //print("paint caption: $front $back $shape");
    MapRectangle boundary = calculateBoundary();

    RelativeMappoint relative = coordinatesAbsolute.offset(-reference.x, -reference.y + renderInstruction.dy);
    ui.Canvas? uiCanvas = (canvas as FlutterCanvas).uiCanvas;
    if (rotationRadian != 0) {
      uiCanvas.save();
      uiCanvas.translate(relative.x, relative.y);
      // if the map is rotated 30° clockwise we have to paint the caption -30° (counter-clockwise) so that it is horizontal
      uiCanvas.rotate(2 * pi - rotationRadian);
      uiCanvas.translate(-relative.x, -relative.y);
    }
    // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(relative.x + boundary.left, relative.y + boundary.top,
    //         boundary.getWidth(), boundary.getHeight()),
    //     ui.Paint()..color = Colors.red.withOpacity(0.5));
    if (back != null) uiCanvas.drawParagraph(back!.paragraph, ui.Offset(relative.x + boundary.left, relative.y + boundary.top));
    if (front != null) uiCanvas.drawParagraph(front!.paragraph, ui.Offset(relative.x + boundary.left, relative.y + boundary.top));
    // uiCanvas.drawCircle(ui.Offset(relative.x, relative.y), 10,
    //     ui.Paint()..color = Colors.green.withOpacity(0.5));
    if (rotationRadian != 0) {
      uiCanvas.restore();
    }
  }

  @override
  void renderWay(MapCanvas canvas, WayProperties wayProperties, PixelProjection projection, Mappoint reference, [double rotationRadian = 0]) {
    MapRectangle boundary = calculateBoundary();

    Mappoint relative = wayProperties.getCenterAbsolute(projection);
    relative = relative.offsetAbsolute(-reference.x, -reference.y + renderInstruction.dy);
    //print("paint caption boundar: $boundary $relative ${shape}");

    ui.Canvas? uiCanvas = (canvas as FlutterCanvas).uiCanvas;
    if (rotationRadian != 0) {
      uiCanvas.save();
      uiCanvas.translate(relative.x, relative.y);
      // if the map is rotated 30° clockwise we have to paint the caption -30° (counter-clockwise) so that it is horizontal
      uiCanvas.rotate(2 * pi - rotationRadian);
      uiCanvas.translate(-relative.x, -relative.y);
    }

    // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(relative.x + boundary.left, relative.y + boundary.top,
    //         boundary.getWidth(), boundary.getHeight()),
    //     ui.Paint()..color = Colors.red.withOpacity(0.5));

    if (back != null) uiCanvas.drawParagraph(back!.paragraph, ui.Offset(relative.x + boundary.left, relative.y + boundary.top));
    if (front != null) uiCanvas.drawParagraph(front!.paragraph, ui.Offset(relative.x + boundary.left, relative.y + boundary.top));
    // uiCanvas.drawCircle(ui.Offset(this.xy.x - origin.x, this.xy.y - origin.y),
    //     5, ui.Paint()..color = Colors.blue);
    if (rotationRadian != 0) {
      uiCanvas.restore();
    }
  }
}
