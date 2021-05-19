import 'dart:math';

import 'package:mapsforge_flutter/src/projection/projection.dart';

class Scalefactor {
  final double scalefactor;

  final int zoomlevel;

  static Scalefactor fromZoomlevel(int zoomlevel) {
    return Scalefactor._(zoomlevelToScalefactor(zoomlevel), zoomlevel);
  }

  static Scalefactor fromScalefactor(double scalefactor) {
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
  static double zoomlevelToScalefactor(int zoomLevel) {
    assert(zoomLevel >= 0 && zoomLevel <= 30);
    return pow(2, zoomLevel.toDouble()).toDouble();
  }
}
