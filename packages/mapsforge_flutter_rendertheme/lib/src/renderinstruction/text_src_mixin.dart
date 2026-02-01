import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/map_font_family.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/map_font_style.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/text_transform.dart';
import 'package:mapsforge_flutter_rendertheme/src/renderinstruction/font_width_helper.dart';

mixin TextSrcMixin {
  /// stroke will be drawn thicker at or above this zoomlevel
  int _textMinZoomLevel = MapsforgeSettingsMgr().strokeMinZoomlevelText;

  /// The maximum allowed font size when zooming
  double _maxFontSize = 50;

  double _fontSize = 10;

  MapFontFamily _fontFamily = MapFontFamily.DEFAULT;

  MapFontStyle _fontStyle = MapFontStyle.NORMAL;

  /// The maximum width of a text
  double _maxTextWidth = MapsforgeSettingsMgr().maxTextWidth;

  TextTransform _textTransform = TextTransform.none;

  void textSrcMixinClone(TextSrcMixin base) {
    _textMinZoomLevel = base._textMinZoomLevel;
    _fontSize = base._fontSize;
    _fontFamily = base._fontFamily;
    _fontStyle = base._fontStyle;
    _maxTextWidth = base._maxTextWidth;
    _textTransform = base._textTransform;
  }

  void textSrcMixinScale(TextSrcMixin base, int zoomlevel) {
    textSrcMixinClone(base);
    if (zoomlevel >= _textMinZoomLevel) {
      double scaleFactor = MapsforgeSettingsMgr().calculateScaleFactor(zoomlevel, _textMinZoomLevel);
      _fontSize = min(_fontSize * scaleFactor, _maxFontSize);
    }
  }

  void setFontFamily(MapFontFamily fontFamily) {
    _fontFamily = fontFamily;
  }

  void setFontStyle(MapFontStyle fontStyle) {
    _fontStyle = fontStyle;
  }

  void setFontSize(double fontSize) {
    _fontSize = fontSize * MapsforgeSettingsMgr().getFontScaleFactor();
  }

  void setMaxFontSize(double maxFontSize) {
    _maxFontSize = maxFontSize;
  }

  void setMaxTextWidth(double maxTextWidth) {
    _maxTextWidth = maxTextWidth;
  }

  double getMaxTextWidth() {
    return _maxTextWidth;
  }

  MapSize getEstimatedTextBoundary(String caption, double strokeWidth) {
    return FontWidthHelper().getBoundaryForText(caption, fontFamily, fontStyle, fontSize, strokeWidth, _maxTextWidth);
  }

  MapFontStyle get fontStyle => _fontStyle;

  MapFontFamily get fontFamily => _fontFamily;

  double get fontSize => _fontSize;

  void setTextMinZoomLevel(int textMinZoomLevel) {
    _textMinZoomLevel = textMinZoomLevel;
  }

  TextTransform get textTransform => _textTransform;

  void setTextTransform(TextTransform textTransform) {
    _textTransform = textTransform;
  }
}
