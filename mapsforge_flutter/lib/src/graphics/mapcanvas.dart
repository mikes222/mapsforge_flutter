import 'package:mapsforge_flutter/src/graphics/filter.dart';
import 'package:mapsforge_flutter/src/graphics/matrix.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/rectangle.dart';
import 'package:meta/meta.dart';

import '../model/dimension.dart';
import 'bitmap.dart';
import 'color.dart';
import 'mappaint.dart';
import 'mappath.dart';

abstract class MapCanvas {
  void destroy();

  Dimension getDimension();

  int getHeight();

  int getWidth();

  Future<Bitmap> finalizeBitmap();

  void drawBitmap(
      {@required Bitmap bitmap,
      @required double left,
      @required double top,
      @required MapPaint paint,
      int srcLeft,
      int srcTop,
      int srcRight,
      int srcBottom,
      int dstLeft,
      int dstTop,
      int dstRight,
      int dstBottom,
      Matrix matrix,
      Filter filter});

  void drawCircle(int x, int y, int radius, MapPaint paint);

  void drawLine(int x1, int y1, int x2, int y2, MapPaint paint);

  void drawPath(MapPath path, MapPaint paint);

  void drawPathText(String text, LineString lineString, Mappoint origin, MapPaint paint);

  void drawText(String text, int x, int y, double fontSize, MapPaint paint);

  void drawTextRotated(String text, int x1, int y1, int x2, int y2, MapPaint paint);

  void fillColor(Color color);

  void fillColorFromNumber(int color);

  bool isAntiAlias();

  bool isFilterBitmap();

  void resetClip();

  void setAntiAlias(bool aa);

  void setClip(int left, int top, int width, int height);

  void setClipDifference(int left, int top, int width, int height);

  void setFilterBitmap(bool filter);

  /// Shade whole map tile when tileRect is null (and bitmap, shadeRect are null).
  /// Shade tileRect neutral if bitmap is null (and shadeRect).
  /// Shade tileRect with bitmap otherwise.
  void shadeBitmap(Bitmap bitmap, Rectangle shadeRect, Rectangle tileRect, double magnitude);
}
