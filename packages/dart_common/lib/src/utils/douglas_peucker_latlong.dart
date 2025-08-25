import 'dart:collection';
import 'dart:math' as Math;

import 'package:dart_common/model.dart';

class DouglasPeuckerLatLong {
  num _perpendicularDistanceSquared(ILatLong p, ILatLong a, ILatLong b) {
    // Berechne das Quadrat der senkrechten Distanz von Punkt p zur Linie ab
    // zwischen den Punkten a und b.
    double dx = a.longitude - b.longitude;
    double dy = a.latitude - b.latitude;
    
    if (dx == 0 && dy == 0) {
      // Points a and b are the same, return distance squared to point a
      double px = p.longitude - a.longitude;
      double py = p.latitude - a.latitude;
      return px * px + py * py;
    }
    
    double area = (b.longitude - a.longitude) * (a.latitude - p.latitude) - (a.longitude - p.longitude) * (b.latitude - a.latitude);
    double abDistSquared = dx * dx + dy * dy;
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
