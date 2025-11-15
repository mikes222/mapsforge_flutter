import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_rendertheme/src/model/scale.dart';

mixin BaseSrcMixin {
  late final int level;

  int priority = 0;

  double _dy = 0;

  Scale scale = Scale.STROKE;

  /// The boundary of this object in pixels relative to the center of the
  /// corresponding node or way. This is a cache and will be calculated by asking.
  /// Do NOT clone this.
  MapRectangle? boundary;

  /// if false (default) the symbol will always drawn in the same direction regardless of the map rotation. For example an exclamation symbol (!) will
  /// always have the dot points towards the bottom of the screen.
  /// If true the symbol rotates with the map.
  bool rotateWithMap = false;

  String? cat;

  double get dy => _dy;

  void setDy(double value) {
    _dy = value * MapsforgeSettingsMgr().getDeviceScaleFactor();
  }

  void baseSrcMixinClone(BaseSrcMixin base) {
    // level is set via constructor
    //level = base.level;
    priority = base.priority;
    _dy = base._dy;
    scale = base.scale;
    rotateWithMap = base.rotateWithMap;
    cat = base.cat;
  }

  void baseSrcMixinScale(BaseSrcMixin base, int zoomlevel) {
    baseSrcMixinClone(base);
    if (zoomlevel >= MapsforgeSettingsMgr().strokeMinZoomlevel) {
      double scaleFactor = MapsforgeSettingsMgr().calculateScaleFactor(zoomlevel, MapsforgeSettingsMgr().strokeMinZoomlevel);
      _dy = _dy * scaleFactor;
    }
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
