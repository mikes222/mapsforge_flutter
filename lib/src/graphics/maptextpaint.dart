import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';

abstract class MapTextPaint {
  //double getTextHeight(String text);

  //double getTextWidth(String text);

  void setTextSize(double textSize);

  double getTextSize();

  void setFontFamily(MapFontFamily fontFamily);

  void setFontStyle(MapFontStyle fontStyle);

  MapFontStyle getFontStyle();

  MapFontFamily getFontFamily();
}
