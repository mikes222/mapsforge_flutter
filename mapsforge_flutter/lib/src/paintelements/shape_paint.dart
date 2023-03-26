import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';

import '../../core.dart';
import '../../maps.dart';
import '../../special.dart';
import '../graphics/cap.dart';
import '../graphics/join.dart';
import '../graphics/maptextpaint.dart';
import '../graphics/resourcebitmap.dart';
import '../model/maprectangle.dart';
import '../rendertheme/nodeproperties.dart';
import '../rendertheme/shape/shape.dart';
import '../rendertheme/wayproperties.dart';

/// A container which holds a shape and is able to draw the shape to the canvas (=Tile)
abstract class ShapePaint<T extends Shape> {
  final T shape;

  const ShapePaint(this.shape);

  /// Returns the boundary of the underlying shape. This can be used if the boundary
  /// of the shape is dependent on other parameters like the caption in renderInfo
  MapRectangle calculateBoundary() {
    return shape.calculateBoundary();
  }

  void renderNode(MapCanvas canvas, NodeProperties nodeProperties,
      PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]);

  void renderWay(MapCanvas canvas, WayProperties wayProperties,
      PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]);

  Future<void> init(SymbolCache symbolCache);

  MapPaint createPaint(
      {required Style style,

      /// The color of the paint. Default is black
      int color = 0xff000000,

      /// strokeWidth must be zero for fillers when used for text. See [ParagraphEntry]
      double? strokeWidth,
      Cap cap = Cap.ROUND,
      Join join = Join.ROUND,
      List<double>? strokeDashArray}) {
    MapPaint result = GraphicFactory().createPaint();
    result.setStyle(style);
    result.setColorFromNumber(color);
    result.setStrokeWidth(strokeWidth ?? (style == Style.STROKE ? 1 : 0));
    result.setStrokeCap(cap);
    result.setStrokeJoin(join);
    result.setStrokeDasharray(strokeDashArray);
    result.setAntiAlias(true);
    return result;
  }

  Future<ResourceBitmap?> createBitmap(
      {required SymbolCache symbolCache,
      required String bitmapSrc,
      required int bitmapWidth,
      required int bitmapHeight}) async {
    ResourceBitmap? resourceBitmap = await symbolCache.getOrCreateSymbol(
        bitmapSrc, bitmapWidth, bitmapHeight);
    return resourceBitmap;
  }

  MapTextPaint createTextPaint(
      {MapFontFamily fontFamily = MapFontFamily.DEFAULT,
      MapFontStyle fontStyle = MapFontStyle.NORMAL,
      double fontSize = 10}) {
    MapTextPaint result = GraphicFactory().createTextPaint();
    result.setFontFamily(fontFamily);
    result.setFontStyle(fontStyle);
    result.setTextSize(fontSize);
    return result;
  }

  MapPath calculatePath(List<List<Mappoint>> coordinatesRelativeToTile) {
    MapPath _path = GraphicFactory().createPath();

    for (List<Mappoint> outerList in coordinatesRelativeToTile) {
      List<Mappoint> points = outerList;
      //print("Drawing ShapePaintPolyline $minMaxMappoint with $paint");
      Mappoint point = points[0];
      _path.moveTo(point.x, point.y);
      //print("path moveTo $point");
      for (int i = 1; i < points.length; i++) {
        point = points[i];
        _path.lineTo(point.x, point.y);
        //print("path lineTo $point");
      }
    }
    return _path;
  }
}
