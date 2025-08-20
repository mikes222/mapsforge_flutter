import 'dart:ui';

import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';

/// The properties to draw a text. Normally used in conjunction with a FlutterPaint which defines, color of the text.
class UiTextPaint {
  double _textSize = 10;

  MapFontStyle _fontStyle = MapFontStyle.NORMAL;

  MapFontFamily _fontFamily = MapFontFamily.DEFAULT;

  UiTextPaint();

  UiTextPaint.from(UiTextPaint other) {
    _textSize = other.getTextSize();
    _fontStyle = other.getFontStyle();
    _fontFamily = other.getFontFamily();
  }

  void setTextSize(double textSize) {
    _textSize = textSize;
  }

  double getTextSize() {
    return _textSize;
  }

  void setFontFamily(MapFontFamily fontFamily) {
    _fontFamily = fontFamily;
  }

  void setFontStyle(MapFontStyle fontStyle) {
    _fontStyle = fontStyle;
  }

  MapFontStyle getFontStyle() {
    return _fontStyle;
  }

  MapFontFamily getFontFamily() => _fontFamily;

  ParagraphBuilder getParagraphBuilder(UiPaint paint) {
    String fontFamily = _fontFamily.name.toLowerCase();

    ParagraphBuilder builder = ParagraphBuilder(
      ParagraphStyle(
        fontSize: _textSize,
        //textAlign: TextAlign.center,
        fontStyle: _fontStyle == MapFontStyle.BOLD_ITALIC || _fontStyle == MapFontStyle.ITALIC ? FontStyle.italic : FontStyle.normal,
        fontWeight: _fontStyle == MapFontStyle.BOLD || _fontStyle == MapFontStyle.BOLD_ITALIC ? FontWeight.bold : FontWeight.normal,
        fontFamily: fontFamily,
      ),
    );

    if (paint.getStrokeWidth() == 0) {
      builder.pushStyle(TextStyle(color: paint.getColor(), fontFamily: fontFamily));
    } else {
      builder.pushStyle(
        TextStyle(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = paint.getStrokeWidth()
            ..color = paint.getColor(),
          fontFamily: fontFamily,
        ),
      );
    }

    return builder;
  }
}
