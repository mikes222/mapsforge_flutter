import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/src/model/scale.dart';
import 'package:dart_rendertheme/src/model/shape_painter.dart';

mixin BaseSrcMixin {
  late final int level;

  int priority = 0;

  double dy = 0;

  Scale scale = Scale.STROKE;

  /// do not clone the painter
  ShapePainter? shapePainter;

  /// The boundary of this object in pixels relative to the center of the
  /// corresponding node or way. This is a cache and will be calculated by asking.
  /// Do NOT clone this.
  MapRectangle? boundary;

  void setDy(double value) {
    dy = value;
  }

  void baseSrcMixinClone(BaseSrcMixin base) {
    // level is set via constructor
    //level = base.level;
    priority = base.priority;
    dy = base.dy;
    scale = base.scale;
  }

  void baseSrcMixinScale(BaseSrcMixin base, int zoomlevel) {
    baseSrcMixinClone(base);
  }

  void setScaleFromValue(String value) {
    if (value.contains("ALL")) {
      scale = Scale.ALL;
    } else if (value.contains("NONE")) {
      scale = Scale.NONE;
    }
    scale = Scale.STROKE;
  }

  ShapePainter? getPainter() => shapePainter;
}
