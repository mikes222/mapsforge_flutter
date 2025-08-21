import 'dart:math';

import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_color_src_mixin.dart';

mixin BitmapSrcMixin {
  /// Default size is 20x20px (400px) at baseline mdpi (160dpi).
  static final int DEFAULT_SIZE = 20;

  String? bitmapSrc;

  int _bitmapWidth = DEFAULT_SIZE;

  int _bitmapHeight = DEFAULT_SIZE;

  int _bitmapPercent = 100;

  /// stroke will be drawn thicker at or above this zoomlevel
  int _bitmapMinZoomLevel = MapsforgeSettingsMgr().strokeMinZoomlevel;

  int _color = StrokeColorSrcMixin.transparent();

  void bitmapSrcMixinClone(BitmapSrcMixin base) {
    bitmapSrc = base.bitmapSrc;
    _bitmapWidth = base._bitmapWidth;
    _bitmapHeight = base._bitmapHeight;
    _bitmapPercent = base._bitmapPercent;
    _bitmapMinZoomLevel = base._bitmapMinZoomLevel;
    _color = base._color;
  }

  void bitmapSrcMixinScale(BitmapSrcMixin base, int zoomlevel) {
    bitmapSrcMixinClone(base);
    if (zoomlevel >= _bitmapMinZoomLevel) {
      int zoomLevelDiff = zoomlevel - _bitmapMinZoomLevel + 1;
      double scaleFactor = pow(StrokeColorSrcMixin.STROKE_INCREASE, zoomLevelDiff) as double;
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
    _color = color;
  }

  void setBitmapMinZoomLevel(int bitmapMinZoomLevel) {
    _bitmapMinZoomLevel = bitmapMinZoomLevel;
  }

  String bitmapSrcMixinToString() {
    return 'BitmapSrcMixin{bitmapSrc: $bitmapSrc, _bitmapWidth: $_bitmapWidth, _bitmapHeight: $_bitmapHeight, _bitmapPercent: $_bitmapPercent, _bitmapMinZoomLevel: $_bitmapMinZoomLevel, color: 0x${_color.toRadixString(16)}}';
  }
}
