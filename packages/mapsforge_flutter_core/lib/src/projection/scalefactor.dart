import 'dart:math';

import 'package:mapsforge_flutter_core/src/utils/mapsforge_settings_mgr.dart';

/// A class that encapsulates the relationship between a zoom level and a scale factor.
class Scalefactor {
  /// The scale factor, which represents the number of tiles in each direction at a
  /// given zoom level (e.g., at zoom level 3, the scale factor is 2^3 = 8).
  ///
  /// This can be a fractional number to represent intermediate zoom levels during
  /// pinch-to-zoom.
  final double scalefactor;

  /// The discrete zoom level, calculated from the scale factor.
  ///
  /// Zoom level 0 represents the whole world in a single tile.
  final int zoomlevel;

  /// Creates a `Scalefactor` from a given [zoomlevel].
  factory Scalefactor.fromZoomlevel(int zoomlevel) {
    return Scalefactor._(zoomlevelToScalefactor(zoomlevel), zoomlevel);
  }

  /// Creates a `Scalefactor` from a given [scalefactor].
  factory Scalefactor.fromScalefactor(double scalefactor) {
    return Scalefactor._(scalefactor, scalefactorToZoomlevel(scalefactor));
  }

  const Scalefactor._(this.scalefactor, this.zoomlevel);

  /// Converts a [scalefactor] to the corresponding integer zoom level.
  static int scalefactorToZoomlevel(double scalefactor) {
    assert(scalefactor >= 1);
    return (log(scalefactor) / log(2)).floor();
  }

  /// Converts a [zoomlevel] to the corresponding scale factor.
  static double zoomlevelToScalefactor(int zoomlevel) {
    assert(zoomlevel >= 0 && zoomlevel <= MapsforgeSettingsMgr.defaultMaxZoomlevel, "Zoom level $zoomlevel out of range");
    return pow(2, zoomlevel.toDouble()).toDouble();
  }
}
