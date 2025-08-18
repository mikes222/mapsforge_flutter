import 'dart:math';

import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/model/mapfontfamily.dart';
import 'package:dart_rendertheme/src/model/mapfontstyle.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_color_src_mixin.dart';

mixin TextSrcMixin {
  /// stroke will be drawn thicker at or above this zoomlevel
  int _textMinZoomLevel = MapsforgeSettingsMgr().strokeMinZoomlevelText;

  double _maxFontSize = 50;

  double _fontSize = 10;

  MapFontFamily _fontFamily = MapFontFamily.DEFAULT;

  MapFontStyle _fontStyle = MapFontStyle.NORMAL;

  /// The maximum width of a text as defined in the displaymodel
  double maxTextWidth = 300;

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
      double scaleFactor = pow(StrokeColorSrcMixin.STROKE_INCREASE, zoomLevelDiff) as double;
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
