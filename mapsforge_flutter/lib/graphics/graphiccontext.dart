import '../model/rectangle.dart';

import 'bitmap.dart';
import 'color.dart';
import 'filter.dart';
import 'matrix.dart';
import 'paint.dart';
import 'path.dart';

abstract class GraphicContext {
  void drawBitmap(
      {Bitmap bitmap,
      int left,
      int top,
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

  void drawCircle(int x, int y, int radius, Paint paint);

  void drawLine(int x1, int y1, int x2, int y2, Paint paint);

  void drawPath(Path path, Paint paint);

  void drawPathText(String text, Path path, Paint paint);

  void drawText(String text, int x, int y, Paint paint);

  void drawTextRotated(
      String text, int x1, int y1, int x2, int y2, Paint paint);

  void fillColor(Color color);

  void fillColorFromNumber(int color);

  bool isAntiAlias();

  bool isFilterBitmap();

  void resetClip();

  void setAntiAlias(bool aa);

  void setClip(int left, int top, int width, int height);

  void setClipDifference(int left, int top, int width, int height);

  void setFilterBitmap(bool filter);

  /**
   * Shade whole map tile when tileRect is null (and bitmap, shadeRect are null).
   * Shade tileRect neutral if bitmap is null (and shadeRect).
   * Shade tileRect with bitmap otherwise.
   */
  void shadeBitmap(
      Bitmap bitmap, Rectangle shadeRect, Rectangle tileRect, double magnitude);
}
