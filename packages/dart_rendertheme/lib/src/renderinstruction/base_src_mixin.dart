import 'package:dart_rendertheme/src/model/display.dart';
import 'package:dart_rendertheme/src/model/scale.dart';

mixin BaseSrcMixin {
  late final int level;

  Display display = Display.IFSPACE;

  int priority = 0;

  double dy = 0;

  Scale scale = Scale.STROKE;

  void setDy(double value) {
    dy = value;
  }

  void setScaleFromValue(String value) {
    if (value.contains("ALL")) {
      scale = Scale.ALL;
    } else if (value.contains("NONE")) {
      scale = Scale.NONE;
    }
    scale = Scale.STROKE;
  }
}
