import 'dart:collection';
import 'dart:math' as Math;

import '../../core.dart';

class DouglasPeuckerLatLong {
  num _perpendicularDistanceSquared(ILatLong p, ILatLong a, ILatLong b) {
    // Berechne das Quadrat der senkrechten Distanz von Punkt p zur Linie ab
    // zwischen den Punkten a und b.
    if (a.longitude == b.longitude && a.latitude == b.latitude) {
      return Math.pow(p.longitude - a.longitude, 2) + Math.pow(p.latitude - a.latitude, 2);
    }
    double area = (b.longitude - a.longitude) * (a.latitude - p.latitude) - (a.longitude - p.longitude) * (b.latitude - a.latitude);
    num abDistSquared = Math.pow(b.longitude - a.longitude, 2) + Math.pow(b.latitude - a.latitude, 2);
    return (area * area) / abDistSquared;
  }

  List<ILatLong> simplify(List<ILatLong> points, double tolerance) {
    if (points.length <= 2) {
      return points;
    }

    double toleranceSquared = tolerance * tolerance;
    List<ILatLong> result = [];
    Queue<List<int>> stack = Queue();
    stack.add([0, points.length - 1]);

    while (stack.isNotEmpty) {
      List<int> current = stack.removeFirst();
      int start = current[0];
      int end = current[1];

      num maxDistanceSquared = 0;
      int maxDistanceIndex = start;

      for (int i = start + 1; i < end; i++) {
        num distanceSquared = _perpendicularDistanceSquared(points[i], points[start], points[end]);
        if (distanceSquared > maxDistanceSquared) {
          maxDistanceSquared = distanceSquared;
          maxDistanceIndex = i;
        }
      }

      if (maxDistanceSquared > toleranceSquared) {
        stack.addFirst([maxDistanceIndex, end]);
        stack.addFirst([start, maxDistanceIndex]);
      } else {
        if (result.isEmpty) {
          result.add(points[start]);
        }
        result.add(points[end]);
      }
    }
    return result;
  }
}
