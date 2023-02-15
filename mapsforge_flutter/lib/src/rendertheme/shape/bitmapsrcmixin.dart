import 'dart:math';

import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';

import '../../../core.dart';

class BitmapSrcMixin {
  /**
   * Default size is 20x20px (400px) at baseline mdpi (160dpi).
   */
  static final int DEFAULT_SIZE = 20;

  String? bitmapSrc;

  int _bitmapWidth = DEFAULT_SIZE;

  int _bitmapHeight = DEFAULT_SIZE;

  int _bitmapPercent = 100;

  /// stroke will be drawn thicker at or above this zoomlevel
  int _bitmapMinZoomLevel = DisplayModel.STROKE_MIN_ZOOMLEVEL;

  int color = 0xff000000;

  void bitmapSrcMixinClone(BitmapSrcMixin base) {
    bitmapSrc = base.bitmapSrc;
    _bitmapWidth = base._bitmapWidth;
    _bitmapHeight = base._bitmapHeight;
    _bitmapPercent = base._bitmapPercent;
    _bitmapMinZoomLevel = base._bitmapMinZoomLevel;
    color = base.color;
  }

  void bitmapSrcMixinScale(BitmapSrcMixin base, int zoomLevel) {
    bitmapSrcMixinClone(base);
    if (zoomLevel >= _bitmapMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - _bitmapMinZoomLevel + 1;
      double scaleFactor =
          pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      _bitmapWidth = (_bitmapWidth * scaleFactor).round();
      _bitmapHeight = (_bitmapHeight * scaleFactor).round();
    }
  }

  int getBitmapHeight() {
    if (_bitmapPercent > 0 && _bitmapPercent != 100) {
      return (_bitmapHeight * _bitmapPercent / 100.0).round();
    }
    return _bitmapHeight;
  }

  int getBitmapWidth() {
    if (_bitmapPercent > 0 && _bitmapPercent != 100) {
      return (_bitmapWidth * _bitmapPercent / 100.0).round();
    }
    return _bitmapWidth;
  }

  void setBitmapSrc(String bitmapSrc) {
    this.bitmapSrc = bitmapSrc;
  }

  void setBitmapPercent(int bitmapPercent) {
    _bitmapPercent = bitmapPercent;
  }

  void setBitmapWidth(int bitmapWidth) {
    _bitmapWidth = bitmapWidth;
  }

  void setBitmapHeight(int bitmapHeight) {
    _bitmapHeight = bitmapHeight;
  }

  void setBitmapColorFromNumber(int color) {
    this.color = color;
  }

  void setBitmapMinZoomLevel(int bitmapMinZoomLevel) {
    _bitmapMinZoomLevel = bitmapMinZoomLevel;
  }
}
