import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_rendertheme/src/model/nodewayproperties.dart';
import 'package:dart_rendertheme/src/util/douglas_peucker_mappoint.dart';

/// Properties for one Way as read from the datastore. Note that the properties are
/// dependent on the zoomLevel and pixelsize of the device. Therefore one instance
/// of WayProperties can be used for one zoomlevel only.
class WayProperties implements NodeWayProperties {
  final double maxGap = 5;

  final Way way;

  final int layer;

  final bool isClosedWay;

  /// cache for the absolute center of the way in mappixels
  Mappoint? center;

  /// cache for absolute coordinates
  late List<List<Mappoint>> coordinatesAbsolute;

  /// cache for the boundary of the way
  MapRectangle? _minMaxMappoint;

  WayProperties(this.way, PixelProjection projection) : layer = max(0, way.layer), isClosedWay = LatLongUtils.isClosedWay(way.latLongs[0]) {
    _calculateCoordinatesAbsolute(projection);
  }

  List<List<Mappoint>> getCoordinatesAbsolute() {
    return coordinatesAbsolute;
  }

  List<List<Mappoint>> _calculateCoordinatesAbsolute(PixelProjection projection) {
    coordinatesAbsolute = [];
    way.latLongs.forEachIndexed((int idx, List<ILatLong> outerList) {
      List<Mappoint> mp1 = outerList.map((ILatLong position) => projection.latLonToPixel(position)).toList();
      MapRectangle minMaxMappoint = MapRectangle.from(mp1);
      if (idx == 0) _minMaxMappoint = minMaxMappoint;
      if (minMaxMappoint.getWidth() > maxGap || minMaxMappoint.getHeight() > maxGap) {
        if (mp1.length > 6) mp1 = DouglasPeuckerMappoint().simplify(mp1, maxGap);
        // check if the area to draw is too small. This saves 100ms for complex structures
        coordinatesAbsolute.add(mp1);
      }
    });
    return coordinatesAbsolute;
  }

  Mappoint getCenterAbsolute(PixelProjection projection) {
    if (center != null) return center!;

    if (way.labelPosition != null) {
      center = projection.latLonToPixel(way.labelPosition!);
    }
    return _minMaxMappoint!.getCenter();
  }

  int getLayer() {
    return layer;
  }

  List<Tag> getTags() {
    return way.tags;
  }

  MapRectangle getBoundaryAbsolute() {
    if (_minMaxMappoint != null) return _minMaxMappoint!;
    List<List<Mappoint>> coordinates = getCoordinatesAbsolute();
    if (coordinates.isEmpty) return const MapRectangle.zero();
    if (_minMaxMappoint != null) return _minMaxMappoint!;
    _minMaxMappoint = MapRectangle.from(coordinates[0]);
    return _minMaxMappoint!;
  }

  /// Computes a polyline with distance dy parallel to given coordinates.
  /// http://objectmix.com/graphics/132987-draw-parallel-polyline-algorithm-needed.html
  /// distance: positive -> left offset, negative -> right
  static List<Mappoint> parallelPath(List<Mappoint> originals, double distance) {
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
    offsets.add(Mappoint(originals[0].x - distance * u[0].y, originals[0].y + distance * u[0].x));

    // For 1 to N-1 calculate the intersection of the offset lines
    for (int k = 1; k < n; k++) {
      double l = distance / (1 + u[k].x * u[k - 1].x + u[k].y * u[k - 1].y);
      offsets.add(Mappoint(originals[k].x - l * (u[k].y + u[k - 1].y), originals[k].y + l * (u[k].x + u[k - 1].x)));
    }

    // For the end point use the normal
    offsets.add(Mappoint(originals[n].x - distance * u[n - 1].y, originals[n].y + distance * u[n - 1].x));

    return offsets;
  }

  /// Calculates the center of the minimum bounding rectangle for the given coordinates.
  ///
  /// @param coordinates the coordinates for which calculation should be done.
  /// @return the center coordinates of the minimum bounding rectangle.
  static Mappoint _calculateCenterOfBoundingBox(List<Mappoint> coordinates) {
    double pointXMin = coordinates[0].x;
    double pointXMax = coordinates[0].x;
    double pointYMin = coordinates[0].y;
    double pointYMax = coordinates[0].y;

    for (Mappoint immutablePoint in coordinates) {
      if (immutablePoint.x < pointXMin) {
        pointXMin = immutablePoint.x;
      } else if (immutablePoint.x > pointXMax) {
        pointXMax = immutablePoint.x;
      }

      if (immutablePoint.y < pointYMin) {
        pointYMin = immutablePoint.y;
      } else if (immutablePoint.y > pointYMax) {
        pointYMax = immutablePoint.y;
      }
    }

    return Mappoint((pointXMin + pointXMax) / 2, (pointYMax + pointYMin) / 2);
  }
}
