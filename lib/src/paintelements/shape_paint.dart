import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/src/graphics/fillrule.dart';
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
import '../rendertheme/wayproperties.dart';

/// A container which holds a shape and is able to draw the shape to the canvas (=Tile)
abstract class ShapePaint<T extends Shape> {
  final T shape;

  const ShapePaint(this.shape);

  /// Returns the boundary of the underlying shape in pixels relative to the center of the
  //   /// corresponding node or way. This can be used if the boundary
  /// of the shape is dependent on other parameters like for example a caption.
  MapRectangle calculateBoundary() {
    return shape.calculateBoundary();
  }

  void renderNode(MapCanvas canvas, Mappoint coordinatesAbsolute, Mappoint reference, [double rotationRadian = 0]);

  void renderWay(MapCanvas canvas, WayProperties wayProperties, PixelProjection projection, Mappoint reference, [double rotationRadian = 0]);

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
      {required SymbolCache symbolCache, required String bitmapSrc, required int bitmapWidth, required int bitmapHeight}) async {
    ResourceBitmap? resourceBitmap = await symbolCache.getOrCreateSymbol(bitmapSrc, bitmapWidth, bitmapHeight);
    return resourceBitmap;
  }

  MapTextPaint createTextPaint({MapFontFamily fontFamily = MapFontFamily.DEFAULT, MapFontStyle fontStyle = MapFontStyle.NORMAL, double fontSize = 10}) {
    MapTextPaint result = GraphicFactory().createTextPaint();
    result.setFontFamily(fontFamily);
    result.setFontStyle(fontStyle);
    result.setTextSize(fontSize);
    return result;
  }

  MapPath calculatePath(List<List<Mappoint>> coordinatesAbsolute, Mappoint reference, double dy) {
    MapPath _path = GraphicFactory().createPath();
    // omit holes in the area. Without this the hole is also drawn.
    _path.setFillRule(FillRule.EVEN_ODD);
    coordinatesAbsolute.forEach((List<Mappoint> outerList) {
      outerList.forEachIndexed((int idx, Mappoint point) {
        if (idx == 0)
          _path.moveToMappoint(point.offset(-reference.x, -reference.y + dy));
        else
          _path.lineToMappoint(point.offset(-reference.x, -reference.y + dy));
      });
    });
    return _path;
  }
}
