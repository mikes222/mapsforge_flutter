import 'dart:ui';

import 'bitmap.dart';
import 'cap.dart';
import 'join.dart';
import 'style.dart';

abstract class MapPaint {
  ///
  /// disposes that class. The class is not usable afterwards.
  ///
  void dispose();

  int getColorAsNumber();

  double getStrokeWidth();

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

  Color getColor();

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

  void setStrokeDasharray(List<double>? strokeDasharray);

  List<double>? getStrokeDasharray();
}
