import 'dart:math';

import 'package:mapsforge_flutter/src/model/scale.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape.dart';

import '../../model/linestring.dart';
import '../../renderer/paintmixin.dart';
import '../rendercontext.dart';
import '../textkey.dart';
import '../wayproperties.dart';
import '../wayrenderinfo.dart';
import 'paintsrcmixin.dart';
import 'textsrcmixin.dart';

class ShapePathtext extends Shape with PaintSrcMixin, TextSrcMixin {
  double dy = 0;

  Scale scale = Scale.STROKE;

  bool repeat = true;

  double repeatGap = 5;

  double repeatStart = 5;

  bool rotate = true;

  TextKey? textKey;

  ShapePathtext.base(int level) : super.base(level: level) {
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

  void setScaleFromValue(String value) {
    if (value.contains("ALL")) {
      scale = Scale.ALL;
    } else if (value.contains("NONE")) {
      scale = Scale.NONE;
    }
    scale = Scale.STROKE;
  }

  @override
  String getShapeType() {
    return "Pathtext";
  }

  @override
  void renderWay(
      final RenderContext renderContext, WayProperties wayProperties) {
    String? caption = textKey!.getValue(wayProperties.getTags());
    if (caption == null) {
      return;
    }

    LineString? stringPath =
        wayProperties.calculateStringPath(renderContext.projection, dy);
    if (stringPath == null || stringPath.segments.isEmpty) {
      return;
    }

    renderContext.addToClashDrawingLayer(
        level,
        WayRenderInfo(wayProperties, this)
          ..caption = caption
          ..stringPath = stringPath);
    return;
  }

  @override
  String toString() {
    return 'ShapePathtext{level: $level, textKey: $textKey}';
  }
}
