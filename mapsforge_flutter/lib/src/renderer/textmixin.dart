import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontfamily.dart';
import 'package:mapsforge_flutter/src/graphics/mapfontstyle.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttertextpaint.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';

class TextMixin {
  late MapTextPaint _textPaint;

  final Map<int, MapTextPaint> _textPaints = {};

  late int _strokeMinZoomLevel;

  void initTextMixin(int strokeMinZoomLevel) {
    this._strokeMinZoomLevel = strokeMinZoomLevel;
    _textPaint = GraphicFactory().createTextPaint();
    this._textPaint.setTextSize(10);
  }

  void setFontFamily(String fontFamily) {
    switch (fontFamily.toLowerCase()) {
      case "serif":
        _textPaint.setFontFamily(MapFontFamily.SERIF);
        break;
      default:
        _textPaint.setFontFamily(MapFontFamily.DEFAULT);
        break;
    }
  }

  void setFontStyle(MapFontStyle fontStyle) {
    _textPaint.setFontStyle(fontStyle);
    _textPaints.clear();
  }

  MapTextPaint getTextPaint(int zoomLevel) {
    MapTextPaint? paint = _textPaints[zoomLevel];
    paint ??= _textPaint;
    return paint;
  }

  void prepareScaleTextMixin(int zoomLevel) {
    if (_textPaints[zoomLevel] != null) return;
    if (zoomLevel >= _strokeMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - _strokeMinZoomLevel + 1;
      double scaleFactor =
          pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      MapTextPaint t = FlutterTextPaint.from(_textPaint);
      t.setTextSize(_textPaint.getTextSize() * scaleFactor);
      _textPaints[zoomLevel] = t;
    } else {
      _textPaints[zoomLevel] = _textPaint;
    }
  }

  double getFontSize() {
    return _textPaint.getTextSize();
  }

  void setFontSize(double value) {
    _textPaint.setTextSize(value);
    // next call of [scaleMixinTextSize] will refill these values
    _textPaints.clear();
  }

  void disposeTextMixin() {
    _textPaints.clear();
  }
}
