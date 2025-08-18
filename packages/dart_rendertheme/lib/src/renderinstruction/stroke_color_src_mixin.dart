import 'dart:math';

import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/model/cap.dart';
import 'package:dart_rendertheme/src/model/join.dart';

mixin StrokeColorSrcMixin {
  int strokeColor = transparent();

  double _strokeWidth = 0;

  Cap _strokeCap = Cap.ROUND;

  Join _strokeJoin = Join.ROUND;

  List<double>? _strokeDashArray;

  int _strokeMinZoomLevel = MapsforgeSettingsMgr().strokeMinZoomlevel;

  static final double STROKE_INCREASE = 1.5;

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

  void strokeColorSrcMixinClone(StrokeColorSrcMixin base) {
    strokeColor = base.strokeColor;
    _strokeWidth = base._strokeWidth;
    _strokeCap = base._strokeCap;
    _strokeJoin = base._strokeJoin;
    _strokeDashArray = base._strokeDashArray;
    _strokeMinZoomLevel = base._strokeMinZoomLevel;
  }

  void strokeColorSrcMixinScale(StrokeColorSrcMixin base, int zoomLevel) {
    strokeColorSrcMixinClone(base);
    if (zoomLevel >= _strokeMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - _strokeMinZoomLevel + 1;
      double scaleFactor = pow(STROKE_INCREASE, zoomLevelDiff) as double;
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

  bool isStrokeTransparent() {
    return strokeColor == transparent();
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
