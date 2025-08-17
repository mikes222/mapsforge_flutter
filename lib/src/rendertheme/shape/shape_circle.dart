import 'dart:math';

import 'package:mapsforge_flutter/src/rendertheme/shape/shape.dart';

import '../../model/maprectangle.dart';
import '../../renderer/paintmixin.dart';
import '../nodeproperties.dart';
import '../noderenderinfo.dart';
import '../rendercontext.dart';
import 'paintsrcmixin.dart';

class ShapeCircle extends Shape with PaintSrcMixin {
  /// the radius of the circle in pixels
  double radius = 10;

  bool scaleRadius = true;

  double dy = 0;

  ShapeCircle.base(int level) : super.base(level: level) {
    fillColor = PaintSrcMixin.transparent();
  }

  ShapeCircle.scale(ShapeCircle base, int zoomLevel)
      : super.scale(base, zoomLevel) {
    paintSrcMixinScale(base, zoomLevel);
    radius = base.radius;
    scaleRadius = base.scaleRadius;
    dy = base.dy;

    if (scaleRadius) {
      if (zoomLevel >= strokeMinZoomLevel) {
        int zoomLevelDiff = zoomLevel - strokeMinZoomLevel + 1;
        double scaleFactor =
            pow(PaintMixin.STROKE_INCREASE, zoomLevelDiff) as double;
        radius = base.radius * scaleFactor;
      }
    }
  }

  @override
  MapRectangle calculateBoundary() {
    return MapRectangle(-radius, -radius, radius * 2, radius * 2);
  }

  @override
  String getShapeType() {
    return "Circle";
  }

  @override
  renderNode(RenderContext renderContext, NodeProperties nodeProperties) {
    renderContext.addToCurrentDrawingLayer(
        level, NodeRenderInfo<ShapeCircle>(nodeProperties, this));
  }
}
