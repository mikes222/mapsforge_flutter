import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/src/model/cap.dart';
import 'package:dart_rendertheme/src/model/join.dart';

mixin StrokeSrcMixin {
  int strokeColor = transparent();

  double _strokeWidth = 0;

  Cap _strokeCap = Cap.ROUND;

  Join _strokeJoin = Join.ROUND;

  List<double>? _strokeDashArray;

  int _strokeMinZoomLevel = MapsforgeSettingsMgr().strokeMinZoomlevel;

  void setStrokeColorFromNumber(int color) {
    strokeColor = color;
  }

  void setStrokeWidth(double strokeWidth) {
    assert(strokeWidth >= 0);
    _strokeWidth = strokeWidth * MapsforgeSettingsMgr().getUserScaleFactor();
  }

  double get strokeWidth => _strokeWidth;

  Cap get strokeCap => _strokeCap;

  Join get strokeJoin => _strokeJoin;

  List<double>? get strokeDashArray => _strokeDashArray;

  int get strokeMinZoomLevel => _strokeMinZoomLevel;

  void strokeSrcMixinClone(StrokeSrcMixin base) {
    strokeColor = base.strokeColor;
    _strokeWidth = base._strokeWidth;
    _strokeCap = base._strokeCap;
    _strokeJoin = base._strokeJoin;
    _strokeDashArray = base._strokeDashArray;
    _strokeMinZoomLevel = base._strokeMinZoomLevel;
  }

  void strokeSrcMixinScale(StrokeSrcMixin base, int zoomlevel) {
    strokeSrcMixinClone(base);
    if (zoomlevel >= _strokeMinZoomLevel) {
      double scaleFactor = MapsforgeSettingsMgr().calculateScaleFactor(zoomlevel, _strokeMinZoomLevel);
      _strokeWidth = _strokeWidth * scaleFactor;
      if (_strokeDashArray != null) {
        List<double> newStrokeDashArray = [];
        for (var element in _strokeDashArray!) {
          newStrokeDashArray.add(element * scaleFactor);
        }
        _strokeDashArray = newStrokeDashArray;
      }
    }
  }

  bool isStrokeTransparent() {
    return strokeColor == transparent();
  }

  static int transparent() => 0x00000000;

  void setStrokeCap(Cap cap) {
    _strokeCap = cap;
  }

  void setStrokeJoin(Join join) {
    _strokeJoin = join;
  }

  void setStrokeDashArray(List<double>? strokeDashArray) {
    _strokeDashArray = strokeDashArray;
  }

  void setStrokeMinZoomLevel(int strokeMinZoomLevel) {
    _strokeMinZoomLevel = strokeMinZoomLevel;
  }
}
