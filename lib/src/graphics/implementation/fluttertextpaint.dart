import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';

/// The properties to draw a text. Normally used in conjunction with a FlutterPaint which defines, color of the text.
class FlutterTextPaint implements MapTextPaint {
  double _textSize = 10;

  MapFontStyle _fontStyle = MapFontStyle.NORMAL;

  MapFontFamily _fontFamily = MapFontFamily.DEFAULT;

  FlutterTextPaint();

  FlutterTextPaint.from(MapTextPaint other) {
    _textSize = other.getTextSize();
    _fontStyle = other.getFontStyle();
    _fontFamily = other.getFontFamily();
  }

  @override
  void setTextSize(double textSize) {
    _textSize = textSize;
  }

  @override
  double getTextSize() {
    return _textSize;
  }

  @override
  void setFontFamily(MapFontFamily fontFamily) {
    this._fontFamily = fontFamily;
  }

  @override
  void setFontStyle(MapFontStyle fontStyle) {
    this._fontStyle = fontStyle;
  }

  @override
  MapFontStyle getFontStyle() {
    return _fontStyle;
  }

  // @override
  // double getTextHeight(String text) {
  //   return _textSize;
  // }

  // @override
  // double getTextWidth(String text) {
  //   return FlutterCanvas.calculateTextWidth(text, this);
  // }

  @override
  MapFontFamily getFontFamily() => _fontFamily;
}
