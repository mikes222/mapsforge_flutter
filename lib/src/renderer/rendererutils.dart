import 'dart:math';

import '../model/mappoint.dart';

class RendererUtils {
  /// Computes a polyline with distance dy parallel to given coordinates.
  /// http://objectmix.com/graphics/132987-draw-parallel-polyline-algorithm-needed.html
  /// distance: positive -> left offset, negative -> right
  static List<Mappoint> parallelPath(
      List<Mappoint> originals, double distance) {
    int n = originals.length - 1;
    List<Mappoint> u = [];
    List<Mappoint> offsets = [];

    // Generate an array u[] of unity vectors of each direction
    for (int k = 0; k < n; ++k) {
      double c = originals[k + 1].x - originals[k].x;
      double s = originals[k + 1].y - originals[k].y;
      double l = sqrt(c * c + s * s);
      if (l == 0) {
        u.add(const Mappoint(0, 0));
      } else {
        u.add(Mappoint(c / l, s / l));
      }
    }

    // For the start point calculate the normal
    offsets.add(Mappoint(originals[0].x - distance * u[0].y,
        originals[0].y + distance * u[0].x));

    // For 1 to N-1 calculate the intersection of the offset lines
    for (int k = 1; k < n; k++) {
      double l = distance / (1 + u[k].x * u[k - 1].x + u[k].y * u[k - 1].y);
      offsets.add(Mappoint(originals[k].x - l * (u[k].y + u[k - 1].y),
          originals[k].y + l * (u[k].x + u[k - 1].x)));
    }

    // For the end point use the normal
    offsets.add(Mappoint(originals[n].x - distance * u[n - 1].y,
        originals[n].y + distance * u[n - 1].x));

    return offsets;
  }
}
