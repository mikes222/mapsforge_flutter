import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/renderer/paintmixin.dart';

class BitmapSrcMixin {
  /**
   * Default size is 20x20px (400px) at baseline mdpi (160dpi).
   */
  static final int DEFAULT_SIZE = 20;

  String? bitmapSrc;

  int _bitmapWidth = DEFAULT_SIZE;

  int _bitmapHeight = DEFAULT_SIZE;

  int _bitmapPercent = 100;

  MapPaint? _bitmapPaint;

  final Map<int, int> _widths = {};

  final Map<int, int> _heights = {};

  /// stroke will be drawn thicker at or above this zoomlevel
  late int strokeMinZoomLevel;

  void initBitmapSrcMixin(int strokeMinZoomLevel) {
    this.strokeMinZoomLevel = strokeMinZoomLevel;
  }

  void prepareScaleBitmapSrcMixin(int zoomLevel) {}

  int getBitmapHeight(int zoomLevel) {
    if (_heights[zoomLevel] != null) return _heights[zoomLevel]!;
    if (_bitmapPercent > 0 && _bitmapPercent != 100) {
      _heights[zoomLevel] = (_bitmapHeight * _bitmapPercent / 100.0).round();
    } else {
      _heights[zoomLevel] = _bitmapHeight;
    }
    if (zoomLevel >= strokeMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - strokeMinZoomLevel + 1;
      double scaleFactor =
          pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      //print("scaling $zoomLevel to $scaleFactor and $strokeMinZoomLevel");
      _heights[zoomLevel] = (_heights[zoomLevel]! * scaleFactor).round();
    }
    return _heights[zoomLevel]!;
  }

  int getBitmapWidth(int zoomLevel) {
    if (_widths[zoomLevel] != null) return _widths[zoomLevel]!;
    if (_bitmapPercent > 0 && _bitmapPercent != 100) {
      _widths[zoomLevel] = (_bitmapWidth * _bitmapPercent / 100.0).round();
    } else {
      _widths[zoomLevel] = _bitmapWidth;
    }
    if (zoomLevel >= strokeMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - strokeMinZoomLevel + 1;
      double scaleFactor =
          pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      _widths[zoomLevel] = (_widths[zoomLevel]! * scaleFactor).round();
    }
    return _widths[zoomLevel]!;
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

  MapPaint getBitmapPaint() {
    if (_bitmapPaint == null) {
      _bitmapPaint = GraphicFactory().createPaint();
      _bitmapPaint!.setColorFromNumber(0xff000000);
    }
    return _bitmapPaint!;
  }
}
