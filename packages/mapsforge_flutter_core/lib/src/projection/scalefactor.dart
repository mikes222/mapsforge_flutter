import 'dart:math';

import 'package:mapsforge_flutter_core/src/utils/mapsforge_settings_mgr.dart';

class Scalefactor {
  /// The number of tiles in horizontal/vertical direction. ZoomLevel 3 (8*8 tiles)
  /// results to 2^zoomlevel = 8. To reflect pinch'n'zoom the scalefactor can also
  /// be a fractional number
  final double scalefactor;

  /// zoomLevel 0 means the whole world fits at 1 tile, 1 means the whole world fits at 2*2 tiles and so on
  final int zoomlevel;

  factory Scalefactor.fromZoomlevel(int zoomlevel) {
    return Scalefactor._(zoomlevelToScalefactor(zoomlevel), zoomlevel);
  }

  factory Scalefactor.fromScalefactor(double scalefactor) {
    return Scalefactor._(scalefactor, scalefactorToZoomlevel(scalefactor));
  }

  const Scalefactor._(this.scalefactor, this.zoomlevel);

  /// Converts a scaleFactor to a zoomLevel.
  /// Note that this will return a double, as the scale factors cover the
  /// intermediate zoom levels as well.
  ///
  /// @param scaleFactor the scale factor to convert to a zoom level.
  /// @return the zoom level.
  static int scalefactorToZoomlevel(double scalefactor) {
    assert(scalefactor >= 1);
    return (log(scalefactor) / log(2)).floor();
  }

  /// Converts a zoom level to a scale factor.
  ///
  /// @param zoomLevel the zoom level to convert.
  /// @return the corresponding scale factor.
  static double zoomlevelToScalefactor(int zoomlevel) {
    assert(zoomlevel >= 0 && zoomlevel <= MapsforgeSettingsMgr.defaultMaxZoomlevel, "Zoom level $zoomlevel out of range");
    return pow(2, zoomlevel.toDouble()).toDouble();
  }
}
