import '../model/mappoint.dart';

import 'align.dart';
import 'bitmap.dart';
import 'cap.dart';
import 'color.dart';
import 'mapfontfamily.dart';
import 'mapfontstyle.dart';
import 'join.dart';
import 'style.dart';

abstract class MapPaint {
  ///
  /// disposes that class. The class is not usable afterwards.
  ///
  void dispose();

  int getColor();

  double getStrokeWidth();

  int getTextHeight(String text);

  int getTextWidth(String text);

  bool isTransparent();

  void setAntiAlias(bool value);

  bool getAntiAlias();

  /// sets the bitmap shader. Note that the shader uses the opaquicity of the color currently set so make sure the color is not transparent
  ///
  void setBitmapShader(Bitmap bitmap);

  Bitmap? getBitmapShader();

//  void setBitmapShaderShift(Mappoint origin);

  void setColor(Color color);

  /// The default value is {@link Color#BLACK}. The [color] is a 32 bit ARGB format, eg. 0xff003300 (opaquicity, red, green, blue)
  void setColorFromNumber(int color);

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

  //void setTextAlign(Align align);

  void setTextSize(double textSize);

  double getTextSize();

  void setTypeface(MapFontFamily fontFamily, MapFontStyle fontStyle);

  MapFontStyle getFontStyle();

  void setStrokeDasharray(List<double>? strokeDasharray);

  List<double>? getStrokeDasharray();
}
