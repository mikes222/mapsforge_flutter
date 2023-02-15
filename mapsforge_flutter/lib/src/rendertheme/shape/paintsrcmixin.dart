import 'dart:math';

import '../../../core.dart';
import '../../graphics/cap.dart';
import '../../graphics/join.dart';
import '../../renderer/paintmixin.dart';

class PaintSrcMixin {
  /// For texts the fillColor is the inner color, whereas the strokeColor is the surrounding "frame" of the text
  int fillColor = 0xff000000;

  int strokeColor = 0xff000000;

  double _strokeWidth = 0;

  Cap _strokeCap = Cap.ROUND;

  Join _strokeJoin = Join.ROUND;

  List<double>? _strokeDashArray;

  int _strokeMinZoomLevel = DisplayModel.STROKE_MIN_ZOOMLEVEL;

  void setFillColorFromNumber(int color) {
    fillColor = color;
  }

  void setStrokeColorFromNumber(int color) {
    strokeColor = color;
  }

  void setStrokeWidth(double strokeWidth) {
    assert(strokeWidth >= 0);
    this._strokeWidth = strokeWidth;
  }

  double get strokeWidth => _strokeWidth;

  Cap get strokeCap => _strokeCap;

  Join get strokeJoin => _strokeJoin;

  List<double>? get strokeDashArray => _strokeDashArray;

  int get strokeMinZoomLevel => _strokeMinZoomLevel;

  void paintSrcMixinClone(PaintSrcMixin base) {
    fillColor = base.fillColor;
    strokeColor = base.strokeColor;
    _strokeWidth = base._strokeWidth;
    _strokeCap = base._strokeCap;
    _strokeJoin = base._strokeJoin;
    _strokeDashArray = base._strokeDashArray;
    _strokeMinZoomLevel = base._strokeMinZoomLevel;
  }

  void paintSrcMixinScale(PaintSrcMixin base, int zoomLevel) {
    paintSrcMixinClone(base);
    if (zoomLevel >= _strokeMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - _strokeMinZoomLevel + 1;
      double scaleFactor =
          pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      _strokeWidth = _strokeWidth * scaleFactor;
      if (_strokeDashArray != null) {
        List<double> newStrokeDashArray = [];
        _strokeDashArray!.forEach((element) {
          newStrokeDashArray.add(element * scaleFactor);
        });
        _strokeDashArray = newStrokeDashArray;
      }
    }
  }

  bool isFillTransparent() {
    return fillColor == 0x00000000;
  }

  bool isStrokeTransparent() {
    return strokeColor == 0x00000000;
  }

  static int transparent() => 0x00000000;

  void setStrokeCap(Cap cap) {
    this._strokeCap = cap;
  }

  void setStrokeJoin(Join join) {
    this._strokeJoin = join;
  }

  void setStrokeDashArray(List<double>? strokeDashArray) {
    this._strokeDashArray = strokeDashArray;
  }

  void setStrokeMinZoomLevel(int strokeMinZoomLevel) {
    this._strokeMinZoomLevel = strokeMinZoomLevel;
  }
}
