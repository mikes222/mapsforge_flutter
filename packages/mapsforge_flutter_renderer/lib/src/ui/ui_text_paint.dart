import 'dart:ui';

import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_renderer/src/ui/ui_paint.dart';

/// A class that holds the styling information for rendering text.
///
/// This includes properties like font size, font style, and font family.
/// It is used in conjunction with a `UiPaint` which defines the color of the text.
class UiTextPaint {
  double _textSize = 10;

  MapFontStyle _fontStyle = MapFontStyle.NORMAL;

  MapFontFamily _fontFamily = MapFontFamily.DEFAULT;

  UiTextPaint();

  /// Creates a new `UiTextPaint` as a copy of another `UiTextPaint`.
  UiTextPaint.from(UiTextPaint other) {
    _textSize = other.getTextSize();
    _fontStyle = other.getFontStyle();
    _fontFamily = other.getFontFamily();
  }

  /// Sets the text size.
  void setTextSize(double textSize) {
    _textSize = textSize;
  }

  /// Returns the text size.
  double getTextSize() {
    return _textSize;
  }

  /// Sets the font family.
  void setFontFamily(MapFontFamily fontFamily) {
    _fontFamily = fontFamily;
  }

  /// Sets the font style.
  void setFontStyle(MapFontStyle fontStyle) {
    _fontStyle = fontStyle;
  }

  /// Returns the font style.
  MapFontStyle getFontStyle() {
    return _fontStyle;
  }

  /// Returns the font family.
  MapFontFamily getFontFamily() => _fontFamily;

  /// Creates a `ParagraphBuilder` with the text style defined by this `UiTextPaint`
  /// and the given `UiPaint`.
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
