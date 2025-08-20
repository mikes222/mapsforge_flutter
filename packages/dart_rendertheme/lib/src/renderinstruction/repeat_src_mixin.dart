import 'dart:math';

import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/renderinstruction/stroke_color_src_mixin.dart';

mixin RepeatSrcMixin {
  int _repeatMinZoomLevel = MapsforgeSettingsMgr().strokeMinZoomlevel;

  bool repeat = true;

  late double repeatGap;

  late double repeatStart;

  bool rotate = true;

  void setRepeatGap(double repeatGap) {
    this.repeatGap = repeatGap;
  }

  void repeatSrcMixinClone(RepeatSrcMixin base) {
    repeat = base.repeat;
    repeatGap = base.repeatGap;
    repeatStart = base.repeatStart;
    rotate = base.rotate;
  }

  void repeatSrcMixinScale(RepeatSrcMixin base, int zoomlevel) {
    repeatSrcMixinClone(base);
    if (zoomlevel >= _repeatMinZoomLevel) {
      int zoomLevelDiff = zoomlevel - _repeatMinZoomLevel + 1;
      double scaleFactor = pow(StrokeColorSrcMixin.STROKE_INCREASE, zoomLevelDiff) as double;
      repeatGap = base.repeatGap * scaleFactor;
      repeatStart = base.repeatStart * scaleFactor;
    }
  }
}
