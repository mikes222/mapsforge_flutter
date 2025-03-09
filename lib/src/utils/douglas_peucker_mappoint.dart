import 'dart:collection';
import 'dart:math' as Math;
import 'dart:math';

import '../../core.dart';

class DouglasPeuckerMappoint {
  double _perpendicularDistanceSquared(Mappoint p, Mappoint a, Mappoint b) {
    // Berechne das Quadrat der senkrechten Distanz von Punkt p zur Linie ab
    // zwischen den Punkten a und b.
    if (a.x == b.x && a.y == b.y) {
      return Math.pow(p.x - a.x, 2) + pow(p.y - a.y, 2).toDouble();
    }
    double area = (b.x - a.x) * (a.y - p.y) - (a.x - p.x) * (b.y - a.y);
    double abDistSquared =
        Math.pow(b.x - a.x, 2) + pow(b.y - a.y, 2).toDouble();
    return (area * area) / abDistSquared;
  }

  List<Mappoint> simplify(List<Mappoint> points, double tolerance) {
    if (points.length <= 2) {
      return points;
    }

    double toleranceSquared = tolerance * tolerance;
    List<Mappoint> result = [];
    Queue<List<int>> stack = Queue();
    stack.add([0, points.length - 1]);

    while (stack.isNotEmpty) {
      List<int> current = stack.removeFirst();
      int start = current[0];
      int end = current[1];

      double maxDistanceSquared = 0;
      int maxDistanceIndex = start;

      for (int i = start + 1; i < end; i++) {
        double distanceSquared = _perpendicularDistanceSquared(
            points[i], points[start], points[end]);
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
