import 'package:mapsforge_flutter/src/paintelements/shape_paint.dart';
import 'package:mapsforge_flutter/src/paintelements/waydecorator.dart';
import 'package:mapsforge_flutter/src/rendertheme/nodeproperties.dart';

import '../../core.dart';
import '../../maps.dart';
import '../../special.dart';
import '../graphics/implementation/paragraph_cache.dart';
import '../graphics/mapcanvas.dart';
import '../graphics/maptextpaint.dart';
import '../model/linestring.dart';
import '../rendertheme/shape/shape_pathtext.dart';
import '../rendertheme/wayproperties.dart';

class ShapePaintPathtext extends ShapePaint<ShapePathtext> {
  late final MapPaint? paintBack;

  late final MapPaint? paintFront;

  late final MapTextPaint mapTextPaint;

  //late final ParagraphEntry front;

  late final ParagraphEntry back;

  LineString? fullPath;

  final String caption;

  ShapePaintPathtext(ShapePathtext shapeSymbol, this.caption)
      : super(shapeSymbol) {
    if (!shapeSymbol.isFillTransparent())
      paintFront = createPaint(style: Style.FILL, color: shapeSymbol.fillColor);
    if (!shapeSymbol.isStrokeTransparent())
      paintBack = createPaint(
          style: Style.STROKE,
          color: shapeSymbol.strokeColor,
          strokeWidth: shapeSymbol.strokeWidth,
          cap: shapeSymbol.strokeCap,
          join: shapeSymbol.strokeJoin,
          strokeDashArray: shapeSymbol.strokeDashArray);
    mapTextPaint = createTextPaint(
        fontFamily: shapeSymbol.fontFamily,
        fontStyle: shapeSymbol.fontStyle,
        fontSize: shapeSymbol.fontSize);
  }

  @override
  Future<void> init(SymbolCache symbolCache) {
    return Future.value();
  }

  void paragraph(String text) {
    // front = ParagraphCache()
    //     .getEntry(text, mapTextPaint, paintFront!, shapeSymbol.maxTextWidth);
    back = ParagraphCache()
        .getEntry(text, mapTextPaint, paintBack!, shape.maxTextWidth);
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
  void renderWay(MapCanvas canvas, WayProperties wayProperties,
      PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]) {
    if (fullPath == null) {
      paragraph(caption);

      fullPath = wayProperties.calculateStringPath(projection, shape.dy);
      if (fullPath == null || fullPath!.segments.isEmpty) return;

      fullPath = WayDecorator.reducePathForText(fullPath!, back.getWidth());
    }
    if (fullPath!.segments.isEmpty) return;

    canvas.drawPathText(caption, fullPath!, leftUpper,
        this.paintBack!, mapTextPaint, shape.maxTextWidth);
    canvas.drawPathText(caption, fullPath!, leftUpper,
        this.paintFront!, mapTextPaint, shape.maxTextWidth);
  }

  @override
  void renderNode(MapCanvas canvas, NodeProperties nodeProperties,
      PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]) {}
}
