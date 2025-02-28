import 'dart:math';

import 'package:mapsforge_flutter/core.dart';

/// Uses the douglas-peucker algorithm to decimate line segments to a similar
/// curve with fewer line segments. See https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm
class ReduceHelper {
  /// Reduces a way of mappoints to a similar curve with fewer mappoints.
  static List<Mappoint> reduceMappoint(
      List<Mappoint> nodes, double maxDeviation) {
    double furthestPointDistance = 0.0;
    int furthestPointIndex = 0;
    _MappointLine line = _MappointLine(nodes.first, nodes.last);
    for (int i = 1; i < nodes.length - 1; ++i) {
      double distance = line.distance(nodes.elementAt(i));
      if (distance > furthestPointDistance) {
        furthestPointDistance = distance;
        furthestPointIndex = i;
      }
    }
    if (furthestPointDistance > maxDeviation) {
      List<Mappoint> reduced1 = reduceMappoint(
          nodes.getRange(0, furthestPointIndex + 1).toList(), maxDeviation);
      List<Mappoint> reduced2 = reduceMappoint(
          nodes.getRange(furthestPointIndex, nodes.length).toList(),
          maxDeviation);
      List<Mappoint> result = reduced1;
      result.addAll(reduced2.getRange(1, reduced2.length));
      return result;
    } else {
      return line.asList();
    }
  }

  /// reduces a way of latlong coordinates to a similar curve with fewer latlongs.
  static List<ILatLong> reduceLatLong(
      List<ILatLong> nodes, double maxDeviation) {
    double furthestPointDistance = 0.0;
    int furthestPointIndex = 0;
    _LatLongLine line = _LatLongLine(nodes.first, nodes.last);
    for (int i = 1; i < nodes.length - 1; ++i) {
      double distance = line.distance(nodes.elementAt(i));
      if (distance > furthestPointDistance) {
        furthestPointDistance = distance;
        furthestPointIndex = i;
      }
    }
    if (furthestPointDistance > maxDeviation) {
      List<ILatLong> reduced1 = reduceLatLong(
          nodes.getRange(0, furthestPointIndex + 1).toList(), maxDeviation);
      List<ILatLong> reduced2 = reduceLatLong(
          nodes.getRange(furthestPointIndex, nodes.length).toList(),
          maxDeviation);
      List<ILatLong> result = reduced1;
      result.addAll(reduced2.getRange(1, reduced2.length));
      return result;
    } else {
      return line.asList();
    }
  }
}

/////////////////////////////////////////////////////////////////////////

class _MappointLine {
  final Mappoint start;

  final Mappoint end;

  late double ka;

  late double da;

  late double kb;

  _MappointLine(this.start, this.end) {
    double x1 = start.x;
    double y1 = start.y;
    double x2 = end.x;
    double y2 = end.y;

    // steigung der begrenzung
    ka = (y2 - y1) / (x2 - x1);
    // anfangswert der begrenzung (y=k*x+d)
    da = y1 - ka * x1;
    // steigung der orthogonale
    kb = -1 / ka;
  }

  List<Mappoint> asList() {
    return [start, end];
  }

  double distance(Mappoint mappoint) {
    double x1 = start.x;
    double y1 = start.y;
    double x2 = end.x;
    double y2 = end.y;

    double xx = 0;
    double yx = 0;
    if (x2 - x1 == 0) {
      // senkrecht
      xx = x1;
      yx = mappoint.y;
    } else if (y2 - y1 == 0) {
      // waagrecht
      xx = mappoint.x;
      yx = y1;
    } else {
      // anfangswert der orthogonale
      double db = mappoint.y - kb * mappoint.x;

      // einsetzen für x
      xx = (da - db) / (kb - ka);
      // einsetzen für y
      yx = ka * xx + da;
    }
    // check if the calculated point is inbetween the two endpoints
    // if (!inbetween(xx, x1, x2) || !inbetween(yx, y1, y2)) {
    // LOGGER.info("hmm, point xx/yx " + xx + "/" + yx + " is not in
    // x1/y1 " + x1 + "/" + y1 + " and x2/y2 " + x2 + "/" + y2);
    // }

    return sqrt(pow(yx - mappoint.y, 2) + pow(xx - mappoint.x, 2));
  }

  // bool inbetween(double toCheck, double value1, double value2) {
  //   if (value1 > value2) {
  //     double swap = value1;
  //     value1 = value2;
  //     value2 = swap;
  //   }
  //   if (toCheck >= value1 && toCheck <= value2) return true;
  //   return false;
  // }
}

/////////////////////////////////////////////////////////////////////////

class _LatLongLine {
  final ILatLong start;

  final ILatLong end;

  late double ka;

  late double da;

  late double kb;

  _LatLongLine(this.start, this.end) {
    double x1 = start.longitude;
    double y1 = start.latitude;
    double x2 = end.longitude;
    double y2 = end.latitude;

    // steigung der begrenzung
    ka = (y2 - y1) / (x2 - x1);
    // anfangswert der begrenzung (y=k*x+d)
    da = y1 - ka * x1;
    // steigung der orthogonale
    kb = -1 / ka;
  }

  List<ILatLong> asList() {
    return [start, end];
  }

  double distance(ILatLong mappoint) {
    double x1 = start.longitude;
    double y1 = start.latitude;
    double x2 = end.longitude;
    double y2 = end.latitude;

    double xx = 0;
    double yx = 0;
    if (x2 - x1 == 0) {
      // senkrecht
      xx = x1;
      yx = mappoint.latitude;
    } else if (y2 - y1 == 0) {
      // waagrecht
      xx = mappoint.longitude;
      yx = y1;
    } else {
      // anfangswert der orthogonale
      double db = mappoint.latitude - kb * mappoint.longitude;

      // einsetzen für x
      xx = (da - db) / (kb - ka);
      // einsetzen für y
      yx = ka * xx + da;
    }
    // check if the calculated point is inbetween the two endpoints
    // if (!inbetween(xx, x1, x2) || !inbetween(yx, y1, y2)) {
    // LOGGER.info("hmm, point xx/yx " + xx + "/" + yx + " is not in
    // x1/y1 " + x1 + "/" + y1 + " and x2/y2 " + x2 + "/" + y2);
    // }

    return sqrt(
        pow(yx - mappoint.latitude, 2) + pow(xx - mappoint.longitude, 2));
  }

// bool inbetween(double toCheck, double value1, double value2) {
//   if (value1 > value2) {
//     double swap = value1;
//     value1 = value2;
//     value2 = swap;
//   }
//   if (toCheck >= value1 && toCheck <= value2) return true;
//   return false;
// }
}
