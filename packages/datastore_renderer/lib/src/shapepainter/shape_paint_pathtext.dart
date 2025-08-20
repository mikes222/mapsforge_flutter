import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/model/linestring.dart';
import 'package:datastore_renderer/src/ui/paragraph_cache.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_text_paint.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintPathtext extends ShapePainter<RenderinstructionPathtext> {
  late final UiPaint? paintBack;

  late final UiPaint? paintFront;

  late final UiTextPaint mapTextPaint;

  //late final ParagraphEntry front;

  late final ParagraphEntry back;

  late LineString fullPath;

  final String caption;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintPathtext._(ShapePathtext shapePathtext, this.caption, LineString stringPath) : super(shapePathtext) {
    if (!shapePathtext.isFillTransparent()) paintFront = createPaint(style: Style.FILL, color: shapePathtext.fillColor);
    if (!shapePathtext.isStrokeTransparent())
      paintBack = createPaint(
        style: Style.STROKE,
        color: shapePathtext.strokeColor,
        strokeWidth: shapePathtext.strokeWidth,
        cap: shapePathtext.strokeCap,
        join: shapePathtext.strokeJoin,
        strokeDashArray: shapePathtext.strokeDashArray,
      );
    mapTextPaint = createTextPaint(fontFamily: shapePathtext.fontFamily, fontStyle: shapePathtext.fontStyle, fontSize: shapePathtext.fontSize);
    back = ParagraphCache().getEntry(caption, mapTextPaint, paintBack!, renderInstruction.maxTextWidth);
    fullPath = WayDecorator.reducePathForText(stringPath, back.getWidth());
  }

  static Future<ShapePaintPathtext> create(ShapePathtext shape, SymbolCache symbolCache, String caption, LineString stringPath) async {
    return _taskQueue.add(() async {
      //if (shape.shapePaint != null) return shape.shapePaint! as ShapePaintPathtext;
      ShapePaintPathtext shapePaint = ShapePaintPathtext._(shape, caption, stringPath);
      //await shapePaint.init(symbolCache);
      //shape.shapePaint = shapePaint;
      return shapePaint;
    });
  }

  @override
  Future<void> init(SymbolCache symbolCache) {
    return Future.value();
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
  void renderWay(MapCanvas canvas, WayProperties wayProperties, PixelProjection projection, Mappoint reference, [double rotationRadian = 0]) {
    if (fullPath.segments.isEmpty) return;

    if (paintBack != null) canvas.drawPathText(caption, fullPath, reference, this.paintBack!, mapTextPaint, renderInstruction.maxTextWidth);
    if (paintFront != null) canvas.drawPathText(caption, fullPath, reference, this.paintFront!, mapTextPaint, renderInstruction.maxTextWidth);
  }

  @override
  void renderNode(MapCanvas canvas, Mappoint coordinatesAbsolute, Mappoint reference, [double rotationRadian = 0]) {}
}
