import 'package:mapsforge_flutter/src/model/scale.dart';
import 'package:mapsforge_flutter/src/rendertheme/shape/shape.dart';

import '../rendercontext.dart';
import '../wayproperties.dart';
import '../wayrenderinfo.dart';
import 'bitmapsrcmixin.dart';
import 'paintsrcmixin.dart';

/// A PolylineContainer encapsulates the way data retrieved from a map file.
/// <p/>
/// The class uses deferred evaluation for computing the absolute and relative
/// pixel coordinates of the way as many ways will not actually be rendered on a
/// map. In order to save memory, after evaluation, the internally stored way is
/// released.
class ShapeArea extends Shape with PaintSrcMixin, BitmapSrcMixin {
  Scale scale = Scale.STROKE;

  double dy = 0;

  ShapeArea.base(int level) : super.base(level: level);

  ShapeArea.scale(ShapeArea base, int zoomLevel)
      : super.scale(base, zoomLevel) {
    paintSrcMixinScale(base, zoomLevel);
    bitmapSrcMixinScale(base, zoomLevel);
    scale = base.scale;
    dy = base.dy;
  }

  void setDy(double dy) {
    this.dy = dy;
  }

  @override
  String getShapeType() {
    return "Area";
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
  void renderWay(RenderContext renderContext, WayProperties wayProperties) {
    if (wayProperties.getCoordinatesAbsolute(renderContext.projection).length ==
        0) return;

    renderContext.addToCurrentDrawingLayer(
        level, WayRenderInfo<ShapeArea>(wayProperties, this));
  }

  @override
  String toString() {
    return 'ShapeArea{level: $level, scale: $scale, dy: $dy, ${paintSrcMixinToString()}}';
  }
}
