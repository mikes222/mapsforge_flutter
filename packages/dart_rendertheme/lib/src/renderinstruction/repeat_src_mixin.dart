import 'package:dart_common/utils.dart';

mixin RepeatSrcMixin {
  final int _repeatMinZoomLevel = MapsforgeSettingsMgr().strokeMinZoomlevelText;

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
      double scaleFactor = MapsforgeSettingsMgr().calculateScaleFactor(zoomlevel, _repeatMinZoomLevel);
      repeatGap = base.repeatGap * scaleFactor;
      repeatStart = base.repeatStart * scaleFactor;
    }
  }
}
