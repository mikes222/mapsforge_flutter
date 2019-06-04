import '../model/mappoint.dart';

import 'align.dart';
import 'bitmap.dart';
import 'cap.dart';
import 'color.dart';
import 'fontfamily.dart';
import 'fontstyle.dart';
import 'join.dart';
import 'style.dart';

abstract class MapPaint {
  int getColor();

  double getStrokeWidth();

  int getTextHeight(String text);

  int getTextWidth(String text);

  bool isTransparent();

  void setBitmapShader(Bitmap bitmap);

  void setBitmapShaderShift(Mappoint origin);

  void setColor(Color color);

  /**
   * The default value is {@link Color#BLACK}.
   */
  void setColorFromNumber(int color);

  void setDashPathEffect(List<double> strokeDasharray);

  /**
   * The default value is {@link Cap#ROUND}.
   */
  void setStrokeCap(Cap cap);

  void setStrokeJoin(Join join);

  void setStrokeWidth(double strokeWidth);

  /**
   * The default value is {@link Style#FILL}.
   */
  void setStyle(Style style);

  void setTextAlign(Align align);

  void setTextSize(double textSize);

  void setTypeface(FontFamily fontFamily, FontStyle fontStyle);
}
