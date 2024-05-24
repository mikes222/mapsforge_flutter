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

  late LineString fullPath;

  final String caption;

  ShapePaintPathtext(
      ShapePathtext shapePathtext, this.caption, LineString stringPath)
      : super(shapePathtext) {
    if (!shapePathtext.isFillTransparent())
      paintFront =
          createPaint(style: Style.FILL, color: shapePathtext.fillColor);
    if (!shapePathtext.isStrokeTransparent())
      paintBack = createPaint(
          style: Style.STROKE,
          color: shapePathtext.strokeColor,
          strokeWidth: shapePathtext.strokeWidth,
          cap: shapePathtext.strokeCap,
          join: shapePathtext.strokeJoin,
          strokeDashArray: shapePathtext.strokeDashArray);
    mapTextPaint = createTextPaint(
        fontFamily: shapePathtext.fontFamily,
        fontStyle: shapePathtext.fontStyle,
        fontSize: shapePathtext.fontSize);
    back = ParagraphCache()
        .getEntry(caption, mapTextPaint, paintBack!, shape.maxTextWidth);
    fullPath = WayDecorator.reducePathForText(stringPath, back.getWidth());
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
  void renderWay(MapCanvas canvas, WayProperties wayProperties,
      PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]) {
    if (fullPath.segments.isEmpty) return;

    if (paintBack != null)
      canvas.drawPathText(caption, fullPath, leftUpper, this.paintBack!,
          mapTextPaint, shape.maxTextWidth);
    if (paintFront != null)
      canvas.drawPathText(caption, fullPath, leftUpper, this.paintFront!,
          mapTextPaint, shape.maxTextWidth);
  }

  @override
  void renderNode(MapCanvas canvas, NodeProperties nodeProperties,
      PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]) {}
}
