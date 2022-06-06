import 'dart:math';

import 'package:mapsforge_flutter/src/model/mappoint.dart';

class ReduceHelper {
  static List<Mappoint> reduce(List<Mappoint> nodes, double maxDeviation) {
    double furthestPointDistance = 0.0;
    int furthestPointIndex = 0;
    _Line line = _Line(nodes.first, nodes.last);
    for (int i = 1; i < nodes.length - 1; ++i) {
      double distance = line.distance(nodes.elementAt(i));
      if (distance > furthestPointDistance) {
        furthestPointDistance = distance;
        furthestPointIndex = i;
      }
    }
    if (furthestPointDistance > maxDeviation) {
      List<Mappoint> reduced1 = reduce(
          nodes.getRange(0, furthestPointIndex + 1).toList(), maxDeviation);
      List<Mappoint> reduced2 = reduce(
          nodes.getRange(furthestPointIndex, nodes.length).toList(),
          maxDeviation);
      List<Mappoint> result = reduced1;
      result.addAll(reduced2.getRange(1, reduced2.length));
      return result;
    } else {
      return line.asList();
    }
  }
}

/////////////////////////////////////////////////////////////////////////

class _Line {
  final Mappoint start;

  final Mappoint end;

  _Line(this.start, this.end);

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
      // steigung der begrenzung
      double ka = (y2 - y1) / (x2 - x1);
      // anfangswert der begrenzung (y=k*x+d)
      double da = y1 - ka * x1;
      // steigung der orthogonale
      double kb = -1 / ka;
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
