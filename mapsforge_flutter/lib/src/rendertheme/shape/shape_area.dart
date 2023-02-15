import 'package:mapsforge_flutter/src/rendertheme/shape/shape.dart';

import '../renderinstruction/renderinstruction.dart';
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

  int level = 0;

  double dy = 0;

  ShapeArea.base() : super.base();

  ShapeArea.scale(ShapeArea base, int zoomLevel)
      : super.scale(base, zoomLevel) {
    paintSrcMixinScale(base, zoomLevel);
    bitmapSrcMixinScale(base, zoomLevel);
    scale = base.scale;
    level = base.level;
    dy = base.dy;
  }

  void setDy(double dy) {
    this.dy = dy;
  }

  @override
  String getShapeType() {
    return "Area";
  }
}
