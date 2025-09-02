import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/map_cap.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/map_join.dart';

mixin StrokeSrcMixin {
  int _strokeColor = transparent();

  double _strokeWidth = 0;

  MapCap _strokeCap = MapCap.ROUND;

  MapJoin _strokeJoin = MapJoin.ROUND;

  List<double>? _strokeDashArray;

  int _strokeMinZoomLevel = MapsforgeSettingsMgr().strokeMinZoomlevel;

  void setStrokeColorFromNumber(int color) {
    _strokeColor = color;
  }

  void setStrokeWidth(double strokeWidth) {
    assert(strokeWidth >= 0);
    _strokeWidth = strokeWidth * MapsforgeSettingsMgr().getUserScaleFactor();
  }

  double get strokeWidth => _strokeWidth;

  MapCap get strokeCap => _strokeCap;

  MapJoin get strokeJoin => _strokeJoin;

  List<double>? get strokeDashArray => _strokeDashArray;

  int get strokeMinZoomLevel => _strokeMinZoomLevel;

  void strokeSrcMixinClone(StrokeSrcMixin base) {
    _strokeColor = base._strokeColor;
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
    return _strokeColor == transparent();
  }

  static int transparent() => 0x00000000;

  int get strokeColor => _strokeColor;

  void setStrokeCap(MapCap cap) {
    _strokeCap = cap;
  }

  void setStrokeJoin(MapJoin join) {
    _strokeJoin = join;
  }

  void setStrokeDashArray(List<double>? strokeDashArray) {
    _strokeDashArray = strokeDashArray;
  }

  void setStrokeMinZoomLevel(int strokeMinZoomLevel) {
    _strokeMinZoomLevel = strokeMinZoomLevel;
  }
}
