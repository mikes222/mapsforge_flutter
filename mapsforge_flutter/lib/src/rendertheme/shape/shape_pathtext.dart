import 'dart:math';

import 'package:mapsforge_flutter/src/rendertheme/shape/shape.dart';

import '../../../core.dart';
import '../../renderer/paintmixin.dart';
import '../renderinstruction/renderinstruction.dart';
import '../renderinstruction/textkey.dart';
import 'paintsrcmixin.dart';
import 'textsrcmixin.dart';

class ShapePathtext extends Shape with PaintSrcMixin, TextSrcMixin {
  double dy = 0;

  Scale scale = Scale.STROKE;

  bool repeat = true;

  double repeatGap = 5;

  double repeatStart = 5;

  bool rotate = true;

  int level = 0;

  TextKey? textKey;

  ShapePathtext.base() : super.base() {
    fillColor = PaintSrcMixin.transparent();
  }

  ShapePathtext.scale(ShapePathtext base, int zoomLevel)
      : super.scale(base, zoomLevel) {
    paintSrcMixinScale(base, zoomLevel);
    textSrcMixinScale(base, zoomLevel);
    dy = base.dy;
    scale = base.scale;
    repeat = base.repeat;
    repeatGap = base.repeatGap;
    repeatStart = base.repeatStart;
    rotate = base.rotate;
    level = base.level;
    textKey = base.textKey;

    if (zoomLevel >= strokeMinZoomLevel) {
      int zoomLevelDiff = zoomLevel - strokeMinZoomLevel + 1;
      double scaleFactor =
          pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      repeatGap = repeatGap * scaleFactor;
      repeatStart = repeatStart * scaleFactor;
    }
  }

  void setDy(double dy) {
    this.dy = dy;
  }

  @override
  String getShapeType() {
    return "Pathtext";
  }
}
