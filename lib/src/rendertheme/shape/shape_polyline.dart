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
class ShapePolyline extends Shape with PaintSrcMixin, BitmapSrcMixin {
  Scale scale = Scale.STROKE;

  double dy = 0;
  String? id;

  ShapePolyline.base(int level) : super.base(level: level);

  ShapePolyline.scale(ShapePolyline base, int zoomLevel)
      : super.scale(base, zoomLevel) {
    paintSrcMixinScale(base, zoomLevel);
    bitmapSrcMixinScale(base, zoomLevel);
    scale = base.scale;
    dy = base.dy;
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
    return "Polyline";
  }

  @override
  void renderWay(
      final RenderContext renderContext, WayProperties wayProperties) {
    if (bitmapSrc == null && isStrokeTransparent()) return;
    if (wayProperties.getCoordinatesAbsolute(renderContext.projection).length ==
        0) return;

    renderContext.addToCurrentDrawingLayer(
        level, WayRenderInfo<ShapePolyline>(wayProperties, this));
  }

  @override
  String toString() {
    return 'ShapePolyline{level: $level, scale: $scale, super: ${super.toString()}, ${paintSrcMixinToString()}, ${bitmapSrcMixinToString()}}';
  }
}
