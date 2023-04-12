import 'dart:math';

import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';

import '../../../core.dart';
import '../../graphics/mapfontstyle.dart';
import '../../renderer/paintmixin.dart';

class TextSrcMixin {
  /// stroke will be drawn thicker at or above this zoomlevel
  int _textMinZoomLevel = DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT;

  double _maxFontSize = 50;

  double _fontSize = 10;

  MapFontFamily _fontFamily = MapFontFamily.DEFAULT;

  MapFontStyle _fontStyle = MapFontStyle.NORMAL;

  /// The maximum width of a text as defined in the displaymodel
  double maxTextWidth = 200;

  void textSrcMixinClone(TextSrcMixin base) {
    _textMinZoomLevel = base._textMinZoomLevel;
    _fontSize = base._fontSize;
    _fontFamily = base._fontFamily;
    _fontStyle = base._fontStyle;
    maxTextWidth = base.maxTextWidth;
  }

  void textSrcMixinScale(TextSrcMixin base, int zoomLevel) {
    textSrcMixinClone(base);
    if (zoomLevel >= _textMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - _textMinZoomLevel + 1;
      double scaleFactor =
      pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      _fontSize = min(_fontSize * scaleFactor, _maxFontSize);
    }
  }

  void setFontFamily(MapFontFamily fontFamily) {
    this._fontFamily = fontFamily;
  }

  void setFontStyle(MapFontStyle fontStyle) {
    this._fontStyle = fontStyle;
  }

  void setFontSize(double fontSize) {
    this._fontSize = fontSize;
  }

  MapFontStyle get fontStyle => _fontStyle;

  MapFontFamily get fontFamily => _fontFamily;

  double get fontSize => _fontSize;
}
