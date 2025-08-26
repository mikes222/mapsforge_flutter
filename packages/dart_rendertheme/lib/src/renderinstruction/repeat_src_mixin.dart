import 'package:dart_common/utils.dart';

mixin RepeatSrcMixin {
  final int _repeatMinZoomLevel = MapsforgeSettingsMgr().strokeMinZoomlevelText;

  bool repeat = true;

  late double _repeatGap;

  late double _repeatStart;

  bool rotate = true;

  void setRepeatGap(double repeatGap) {
    this._repeatGap = repeatGap * MapsforgeSettingsMgr().getFontScaleFactor();
  }

  void setRepeatStart(double repeatStart) {
    this._repeatStart = repeatStart * MapsforgeSettingsMgr().getFontScaleFactor();
  }

  void repeatSrcMixinClone(RepeatSrcMixin base) {
    repeat = base.repeat;
    _repeatGap = base._repeatGap;
    _repeatStart = base._repeatStart;
    rotate = base.rotate;
  }

  void repeatSrcMixinScale(RepeatSrcMixin base, int zoomlevel) {
    repeatSrcMixinClone(base);
    if (zoomlevel >= _repeatMinZoomLevel) {
      double scaleFactor = MapsforgeSettingsMgr().calculateScaleFactor(zoomlevel, _repeatMinZoomLevel);
      _repeatGap = base._repeatGap * scaleFactor;
      _repeatStart = base._repeatStart * scaleFactor;
    }
  }

  double get repeatGap => _repeatGap;

  double get repeatStart => _repeatStart;
}
