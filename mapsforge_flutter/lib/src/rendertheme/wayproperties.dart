import 'dart:math';

import 'package:mapsforge_flutter/src/rendertheme/nodewayproperties.dart';

import '../../core.dart';
import '../../datastore.dart';
import '../../maps.dart';
import '../model/linesegment.dart';
import '../model/linestring.dart';
import '../model/tag.dart';
import '../renderer/geometryutils.dart';
import '../renderer/minmaxdouble.dart';
import '../renderer/rendererutils.dart';
import '../utils/reducehelper.dart';

///
/// In the terminal window run
///
///```
/// flutter packages pub run build_runner build --delete-conflicting-outputs
///```
///
/// Properties for one Way as read from the datastore. Note that the properties are
/// dependent on the zoomLevel and pixelsize of the device. . However one instance
// /// of WayProperties is used for one zoomlevel only.
class WayProperties implements NodeWayProperties {
  final double maxGap = 5;

  final Way way;

  final int layer;

  final bool isClosedWay;

  /// cache for the center of the way
  Mappoint? center;

  /// cache for absolute coordinates
  List<List<Mappoint>>? coordinatesAbsolute;

  // remove this security feature after 2025/01
  @deprecated
  int _lastZoomLevel = -1;

  WayProperties(this.way)
      : layer = max(0, way.layer),
        isClosedWay = LatLongUtils.isClosedWay(way.latLongs[0]);

  List<List<Mappoint>> getCoordinatesAbsolute(PixelProjection projection) {
    // remove this security feature after 2025/01
    if (_lastZoomLevel != -1 &&
        projection.scalefactor.zoomlevel != _lastZoomLevel)
      throw UnimplementedError("Invalid zoomlevel");
    if (coordinatesAbsolute == null) {
      coordinatesAbsolute = [];
      way.latLongs.forEach((List<ILatLong> outerList) {
        List<Mappoint> mp1 = outerList
            .map((ILatLong position) => projection.latLonToPixel(position))
            .toList();
        mp1 = ReduceHelper.reduce(mp1, maxGap);
        // check if the area to draw is too small. This saves 100ms for complex structures
        MinMaxDouble minMaxMappoint = MinMaxDouble(mp1);
        if (minMaxMappoint.maxX - minMaxMappoint.minX > maxGap ||
            minMaxMappoint.maxY - minMaxMappoint.minY > maxGap) {
          coordinatesAbsolute!.add(mp1);
        }
      });
      _lastZoomLevel = projection.scalefactor.zoomlevel;
    }
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

  // List<List<Mappoint>> getCoordinatesRelativeToLeftUpper(
  //     PixelProjection projection, Mappoint leftUpper, double dy) {
  //   List<List<Mappoint>> coordinatesAbsolute =
  //       getCoordinatesAbsolute(projection);
  //   List<List<Mappoint>> coordinatesRelativeToTile = [];
  //
  //   coordinatesAbsolute.forEach((outerList) {
  //     List<Mappoint> mp1 = outerList
  //         .map((inner) => inner.offset(-leftUpper.x, -leftUpper.y + dy))
  //         .toList();
  //     coordinatesRelativeToTile.add(mp1);
  //   });
  //   return coordinatesRelativeToTile;
  // }

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
}
