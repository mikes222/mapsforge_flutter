import 'dart:math';

import 'package:collection/collection.dart';
import 'package:mapsforge_flutter/src/model/maprectangle.dart';
import 'package:mapsforge_flutter/src/rendertheme/nodewayproperties.dart';
import 'package:mapsforge_flutter/src/utils/douglas_peucker_mappoint.dart';

import '../../core.dart';
import '../../datastore.dart';
import '../../maps.dart';
import '../model/linesegment.dart';
import '../model/linestring.dart';
import '../renderer/geometryutils.dart';
import '../renderer/minmaxdouble.dart';
import '../renderer/rendererutils.dart';

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
  List<List<Mappoint>>? coordinatesAbsolute;

  /// cache for the boundary of the way
  MinMaxDouble? minMaxMappoint;

  WayProperties(this.way)
      : layer = max(0, way.layer),
        isClosedWay = LatLongUtils.isClosedWay(way.latLongs[0]);

  List<List<Mappoint>> getCoordinatesAbsolute(PixelProjection projection) {
    if (coordinatesAbsolute != null) {
      return coordinatesAbsolute!;
    }
    coordinatesAbsolute = [];
    way.latLongs.forEachIndexed((int idx, List<ILatLong> outerList) {
      List<Mappoint> mp1 = outerList
          .map((ILatLong position) => projection.latLonToPixel(position))
          .toList();
      MinMaxDouble minMaxMappoint = MinMaxDouble(mp1);
      if (idx == 0) this.minMaxMappoint = minMaxMappoint;
      if (minMaxMappoint.maxX - minMaxMappoint.minX > maxGap ||
          minMaxMappoint.maxY - minMaxMappoint.minY > maxGap) {
        if (mp1.length > 6)
          mp1 = DouglasPeuckerMappoint().simplify(mp1, maxGap);
        // check if the area to draw is too small. This saves 100ms for complex structures
        coordinatesAbsolute!.add(mp1);
      }
    });
    return coordinatesAbsolute!;
  }

  Mappoint getCenterAbsolute(PixelProjection projection) {
    if (center != null) return center!;

    if (this.way.labelPosition != null) {
      this.center = projection.latLonToPixel(this.way.labelPosition!);
    }
    if (this.center == null) {
      this.center = GeometryUtils.calculateCenterOfBoundingBox(
          getCoordinatesAbsolute(projection)[0]);
    }
    return this.center!;
  }

  LineString? calculateStringPath(PixelProjection projection, double dy) {
    List<List<Mappoint>> coordinatesAbsolute =
        getCoordinatesAbsolute(projection);

    if (coordinatesAbsolute.length == 0 || coordinatesAbsolute[0].length < 2) {
      return null;
    }
    List<Mappoint> c;
    if (dy == 0) {
      c = coordinatesAbsolute[0];
    } else {
      c = RendererUtils.parallelPath(coordinatesAbsolute[0], dy);
    }

    if (c.length < 2) {
      return null;
    }

    LineString fullPath = LineString();
    for (int i = 1; i < c.length; i++) {
      LineSegment segment = LineSegment(c[i - 1], c[i]);
      fullPath.segments.add(segment);
    }
    return fullPath;
  }

  int getLayer() {
    return layer;
  }

  List<Tag> getTags() {
    return way.tags;
  }

  MapRectangle getBoundary(PixelProjection projection) {
    if (minMaxMappoint != null) return minMaxMappoint!.getBoundary();
    List<List<Mappoint>> coordinates = getCoordinatesAbsolute(projection);
    if (coordinates.isEmpty) return const MapRectangle.zero();
    minMaxMappoint = MinMaxDouble(coordinates[0]);
    return minMaxMappoint!.getBoundary();
  }
}
