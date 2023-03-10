import 'dart:math';
import 'dart:ui' as ui;

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape_caption.dart';
import 'package:mapsforge_flutter/src/rendertheme/wayproperties.dart';

import '../../maps.dart';
import '../../special.dart';
import '../graphics/implementation/fluttercanvas.dart';
import '../graphics/implementation/paragraph_cache.dart';
import '../graphics/maptextpaint.dart';
import '../model/maprectangle.dart';
import '../rendertheme/nodeproperties.dart';
import '../rendertheme/noderenderinfo.dart';
import '../rendertheme/renderinfo.dart';
import '../rendertheme/wayrenderinfo.dart';

class ShapePaintCaption extends ShapePaint<ShapeCaption> {
  // this is the stroke, normally white and represents the "surrounding of the text"
  MapPaint? paintBack;

  /// This is the fill, normally black and represents the text itself
  MapPaint? paintFront;

  late final MapTextPaint mapTextPaint;

  ParagraphEntry? front;

  ParagraphEntry? back;

  ShapePaintCaption(ShapeCaption shape, {RenderInfo? renderInfo})
      : super(shape) {
    if (!shape.isFillTransparent())
      paintFront = createPaint(
        style: Style.FILL,
        color: shape.fillColor,
      );
    if (!shape.isStrokeTransparent())
      paintBack = createPaint(
          style: Style.STROKE,
          color: shape.strokeColor,
          strokeWidth: shape.strokeWidth,
          cap: shape.strokeCap,
          join: shape.strokeJoin,
          strokeDashArray: shape.strokeDashArray);
    mapTextPaint = createTextPaint(
        fontFamily: shape.fontFamily,
        fontStyle: shape.fontStyle,
        fontSize: shape.fontSize);
    if (renderInfo != null) {
      if (paintFront != null)
        front = ParagraphCache().getEntry(
            renderInfo.caption!, mapTextPaint, paintFront!, shape.maxTextWidth);
      if (paintBack != null)
        back = ParagraphCache().getEntry(
            renderInfo.caption!, mapTextPaint, paintBack!, shape.maxTextWidth);
      double boxWidth = back?.getWidth() ?? front?.getWidth() ?? 0;
      double boxHeight = back?.getHeight() ?? front?.getWidth() ?? 0;
      shape.setTextBoundary(boxWidth, boxHeight);
    }
  }

  @override
  Future<void> init(SymbolCache symbolCache) {
    return Future.value();
  }

  @override
  void renderNode(MapCanvas canvas, NodeProperties nodeProperties,
      PixelProjection projection, Mappoint leftUpper, NodeRenderInfo renderInfo,
      [double rotationRadian = 0]) {
    MapRectangle boundary = shape.calculateBoundary();

    //print("paint caption boundar: $boundary $front $back");
    Mappoint point =
        nodeProperties.getCoordinateRelativeToLeftUpper(projection, leftUpper);
    // print(
    //     "drawing ${renderInfo.caption} with fontsize ${shapeContainer.fontSize} and width ${shapeContainer.strokeWidth}");
    // // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(
    //         this.xy.x - origin.x + boundary!.left,
    //         this.xy.y - origin.y + boundary!.top,
    //         front.getWidth(),
    //         front.getHeight()),
    //     ui.Paint()..color = Colors.red.withOpacity(0.5));
    // uiCanvas.drawCircle(
    //     ui.Offset(this.xy.x - origin.x + boundary!.left,
    //         this.xy.y - origin.y + boundary!.top),
    //     10,
    //     ui.Paint()..color = Colors.green);
    ui.Canvas? uiCanvas = (canvas as FlutterCanvas).uiCanvas;
    if (rotationRadian != 0) {
      uiCanvas.save();
      uiCanvas.translate(point.x + boundary.left, point.y + boundary.top);
      // if the map is rotated 30° clockwise we have to paint the caption -30° (counter-clockwise) so that it is horizontal
      uiCanvas.rotate(2 * pi - rotationRadian);
      uiCanvas.translate(-point.x + boundary.left, -point.y + boundary.top);
    }
    if (back != null)
      uiCanvas.drawParagraph(back!.paragraph,
          ui.Offset(point.x + boundary.left, point.y + boundary.top));
    if (front != null)
      uiCanvas.drawParagraph(front!.paragraph,
          ui.Offset(point.x + boundary.left, point.y + boundary.top));
    // uiCanvas.drawCircle(ui.Offset(this.xy.x - origin.x, this.xy.y - origin.y),
    //     5, ui.Paint()..color = Colors.blue);
    if (rotationRadian != 0) {
      uiCanvas.restore();
    }
  }

  @override
  void renderWay(
      MapCanvas canvas,
      WayProperties wayProperties,
      PixelProjection projection,
      Mappoint leftUpper,
      WayRenderInfo renderInfo) {
    MapRectangle boundary = shape.calculateBoundary();

    //print("paint caption boundar: $boundary $front $back");
    Mappoint point = wayProperties.getCenterRelativeToLeftUpper(
        projection, leftUpper, shape.dy);
    // print(
    //     "drawing ${renderInfo.caption} with fontsize ${shapeContainer.fontSize} and width ${shapeContainer.strokeWidth}");
    // // uiCanvas.drawRect(
    //     ui.Rect.fromLTWH(
    //         this.xy.x - origin.x + boundary!.left,
    //         this.xy.y - origin.y + boundary!.top,
    //         front.getWidth(),
    //         front.getHeight()),
    //     ui.Paint()..color = Colors.red.withOpacity(0.5));
    // uiCanvas.drawCircle(
    //     ui.Offset(this.xy.x - origin.x + boundary!.left,
    //         this.xy.y - origin.y + boundary!.top),
    //     10,
    //     ui.Paint()..color = Colors.green);
    ui.Canvas? uiCanvas = (canvas as FlutterCanvas).uiCanvas;
    if (back != null)
      uiCanvas.drawParagraph(back!.paragraph,
          ui.Offset(point.x + boundary.left, point.y + boundary.top));
    if (front != null)
      uiCanvas.drawParagraph(front!.paragraph,
          ui.Offset(point.x + boundary.left, point.y + boundary.top));
    // uiCanvas.drawCircle(ui.Offset(this.xy.x - origin.x, this.xy.y - origin.y),
    //     5, ui.Paint()..color = Colors.blue);
  }
}
