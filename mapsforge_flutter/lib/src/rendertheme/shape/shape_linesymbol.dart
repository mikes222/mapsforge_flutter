import 'dart:math';

import 'package:mapsforge_flutter/core.dart';

import '../../renderer/paintmixin.dart';
import '../renderinstruction/renderinstruction.dart';
import 'shape_symbol.dart';

/// A PolylineContainer encapsulates the way data retrieved from a map file.
/// <p/>
/// The class uses deferred evaluation for computing the absolute and relative
/// pixel coordinates of the way as many ways will not actually be rendered on a
/// map. In order to save memory, after evaluation, the internally stored way is
/// released.
class ShapeLinesymbol extends ShapeSymbol {
  double dy = 0;

  bool repeat = true;

  late double _repeatGap;

  late double repeatStart;

  bool rotate = true;

  Scale scale = Scale.STROKE;

  bool alignCenter = false;

  int _lineSymbolMinZoomLevel = DisplayModel.STROKE_MIN_ZOOMLEVEL_TEXT;

  ShapeLinesymbol.base() : super.base();

  ShapeLinesymbol.scale(ShapeLinesymbol base, int zoomLevel)
      : super.scale(base, zoomLevel) {
    //paintSrcMixinScale(base, zoomLevel);
    //bitmapSrcMixinScale(base, zoomLevel);
    dy = base.dy;
    repeat = base.repeat;
    _repeatGap = base.repeatGap;
    repeatStart = base.repeatStart;
    rotate = base.rotate;
    scale = base.scale;
    position = base.position;
    alignCenter = base.alignCenter;
    _lineSymbolMinZoomLevel = base._lineSymbolMinZoomLevel;

    if (this.scale == Scale.NONE) return;

    if (zoomLevel >= _lineSymbolMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - _lineSymbolMinZoomLevel + 1;
      double scaleFactor =
          pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      _repeatGap = _repeatGap * scaleFactor;
      repeatStart = repeatStart * scaleFactor;
      dy = dy * scaleFactor;
    }
  }

  void setRepeatGap(double repeatGap) {
    _repeatGap = repeatGap;
  }

  void setDy(double dy) {
    this.dy = dy;
  }

  double get repeatGap => _repeatGap;

  int get lineSymbolMinZoomLevel => _lineSymbolMinZoomLevel;

  void setLineSymbolMinZoomLevel(int lineSymbolMinZoomLevel) {
    this._lineSymbolMinZoomLevel = lineSymbolMinZoomLevel;
  }

  @override
  String getShapeType() {
    return "Linesymbol";
  }
}
