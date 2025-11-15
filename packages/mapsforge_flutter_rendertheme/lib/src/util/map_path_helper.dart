import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';

class MapPathHelper {
  /// Computes a polyline with distance dy parallel to given coordinates.
  /// http://objectmix.com/graphics/132987-draw-parallel-polyline-algorithm-needed.html
  /// distance: positive -> left offset, negative -> right
  static List<Mappoint> parallelPath(List<Mappoint> originals, double distance) {
    int n = originals.length - 1;
    List<MappointRelative> u = [];

    // Generate an array u[] of unity vectors of each direction
    for (int k = 0; k < n; ++k) {
      double c = originals[k + 1].x - originals[k].x;
      double s = originals[k + 1].y - originals[k].y;
      double l = sqrt(c * c + s * s);
      if (l == 0) {
        u.add(const MappointRelative.zero());
      } else {
        u.add(MappointRelative(c / l, s / l));
      }
    }

    List<Mappoint> offsets = [];
    // For the start point calculate the normal
    offsets.add(Mappoint(originals[0].x - distance * u[0].dy, originals[0].y + distance * u[0].dx));

    // For 1 to N-1 calculate the intersection of the offset lines
    for (int k = 1; k < n; k++) {
      double denominator = 1 + u[k].dx * u[k - 1].dx + u[k].dy * u[k - 1].dy;
      if (denominator.abs() < 1e-10) {
        // Near zero, would cause infinity
        // Use simple perpendicular offset instead of intersection
        double x = originals[k].x - distance * u[k].dy;
        double y = originals[k].y + distance * u[k].dx;
        offsets.add(Mappoint(x, y));
      } else {
        double l = distance / denominator;
        double x = originals[k].x - l * (u[k].dy + u[k - 1].dy);
        double y = originals[k].y + l * (u[k].dx + u[k - 1].dx);
        offsets.add(Mappoint(x, y));
      }
    }

    // For the end point use the normal
    offsets.add(Mappoint(originals[n].x - distance * u[n - 1].dy, originals[n].y + distance * u[n - 1].dx));

    return offsets;
  }
}
