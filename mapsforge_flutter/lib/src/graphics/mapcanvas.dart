import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/matrix.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

import 'bitmap.dart';
import 'mappaint.dart';
import 'mappath.dart';
import 'maprect.dart';

///
/// The abstract representation of a canvas. In flutter the canvas is shown in the widget
abstract class MapCanvas {
  const MapCanvas();

  void destroy();

  // Dimension getDimension();
  //
  // int getHeight();
  //
  // int getWidth();

  Future<Bitmap> finalizeBitmap();

  void drawBitmap({
    required Bitmap bitmap,
    required double left,
    required double top,
    required MapPaint paint,
    Matrix? matrix,
  });

  /// Draws a circle whereas the center of the circle is denoted by [x] and [y]
  void drawCircle(double x, double y, double radius, MapPaint paint);

  void drawLine(double x1, double y1, double x2, double y2, MapPaint paint);

  void drawPath(MapPath path, MapPaint paint);

  void drawRect(MapRect rect, MapPaint paint);

  void drawPathText(String text, LineString lineString, Mappoint origin,
      MapPaint paint, MapTextPaint mapTextPaint, double maxTextWidth);

  void drawText(String text, double x, double y, MapPaint paint,
      MapTextPaint mapTextPaint, double maxTextWidth);

  // void drawTextRotated(String text, int x1, int y1, int x2, int y2, MapPaint paint);
  //
  // void fillColor(Color color);

  void fillColorFromNumber(int color);

  // bool isAntiAlias();
  //
  // bool isFilterBitmap();
  //
  // void resetClip();
  //
  // void setAntiAlias(bool aa);
  //
  void setClip(double left, double top, double width, double height);

  // void setClipDifference(int left, int top, int width, int height);
  //
  // void setFilterBitmap(bool filter);

  /// Shade whole map tile when tileRect is null (and bitmap, shadeRect are null).
  /// Shade tileRect neutral if bitmap is null (and shadeRect).
  /// Shade tileRect with bitmap otherwise.
//  void shadeBitmap(Bitmap bitmap, Rectangle shadeRect, Rectangle tileRect, double magnitude);

  void scale(Mappoint focalPoint, double scale);
}
