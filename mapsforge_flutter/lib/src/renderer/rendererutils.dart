import 'dart:math';

import '../model/mappoint.dart';

class RendererUtils {
  /**
   * Computes a polyline with distance dy parallel to given coordinates.
   * http://objectmix.com/graphics/132987-draw-parallel-polyline-algorithm-needed.html
   */
  static List<Mappoint> parallelPath(List<Mappoint> p, double dy) {
    int n = p.length - 1;
    List<Mappoint> u = [];
    List<Mappoint> h = [];

    // Generate an array u[] of unity vectors of each direction
    for (int k = 0; k < n; ++k) {
      double c = p[k + 1].x - p[k].x;
      double s = p[k + 1].y - p[k].y;
      double l = sqrt(c * c + s * s);
      if (l == 0) {
        u.add(const Mappoint(0, 0));
      } else {
        u.add(Mappoint(c / l, s / l));
      }
    }

    // For the start point calculate the normal
    h.add(Mappoint(p[0].x - dy * u[0].y, p[0].y + dy * u[0].x));

    // For 1 to N-1 calculate the intersection of the offset lines
    for (int k = 1; k < n; k++) {
      double l = dy / (1 + u[k].x * u[k - 1].x + u[k].y * u[k - 1].y);
      h.add(Mappoint(p[k].x - l * (u[k].y + u[k - 1].y),
          p[k].y + l * (u[k].x + u[k - 1].x)));
    }

    // For the end point use the normal
    h.add(Mappoint(p[n].x - dy * u[n - 1].y, p[n].y + dy * u[n - 1].x));

    return h;
  }
}
