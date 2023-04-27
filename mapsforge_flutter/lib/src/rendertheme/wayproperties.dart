import 'dart:math';

import 'package:mapsforge_flutter/src/rendertheme/nodewayproperties.dart';

import '../../core.dart';
import '../../datastore.dart';
import '../../maps.dart';
import '../model/linesegment.dart';
import '../model/linestring.dart';
import '../model/tag.dart';
import '../renderer/geometryutils.dart';
import '../renderer/minmaxmappoint.dart';
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
/// dependent on the zoomLevel and pixelsize of the device.
class WayProperties implements NodeWayProperties {
  final double maxGap = 5;

  final Way way;

  final int layer;

  final bool isClosedWay;

  Mappoint? center;

  List<List<Mappoint>>? coordinatesAbsolute;

  int _lastZoomLevel = -1;

  WayProperties(this.way)
      : layer = max(0, way.layer),
        isClosedWay = LatLongUtils.isClosedWay(way.latLongs[0]);

  List<List<Mappoint>> getCoordinatesAbsolute(PixelProjection projection) {
    // deferred evaluation as some PolyLineContainers will never be drawn. However,
    // to save memory, after computing the absolute coordinates, the way is released.
    if (projection.scalefactor.zoomlevel != _lastZoomLevel)
      coordinatesAbsolute = null;
    if (coordinatesAbsolute == null) {
      coordinatesAbsolute = [];
      way.latLongs.forEach((outerList) {
        List<Mappoint> mp1 = outerList
            .map((position) => projection.latLonToPixel(position))
            .toList();
        mp1 = ReduceHelper.reduce(mp1, maxGap);
        // check if the area to draw is too small. This saves 100ms for complex structures
        MinMaxMappoint minMaxMappoint = MinMaxMappoint(mp1);
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

  Mappoint getCenterRelativeToLeftUpper(PixelProjection projection,
      Mappoint leftUpper, double dy) {
    Mappoint center = getCenterAbsolute(projection);
    return center.offset(-leftUpper.x, -leftUpper.y + dy);
  }

  List<List<Mappoint>> getCoordinatesRelativeToLeftUpper(
      PixelProjection projection, Mappoint leftUpper, double dy) {
    List<List<Mappoint>> coordinatesAbsolute =
    getCoordinatesAbsolute(projection);
    List<List<Mappoint>> coordinatesRelativeToTile = [];

    coordinatesAbsolute.forEach((outerList) {
      List<Mappoint> mp1 = outerList
          .map((inner) => inner.offset(-leftUpper.x, -leftUpper.y + dy))
          .toList();
      coordinatesRelativeToTile.add(mp1);

      // MinMaxMappoint minMaxMappoint = MinMaxMappoint(mp1);
      // print(minMaxMappoint);
    });
    return coordinatesRelativeToTile;
  }

  LineString? calculateStringPath(PixelProjection projection, double dy) {
    List<List<Mappoint>> coordinatesAbsolute =
    getCoordinatesAbsolute(projection);

    if (coordinatesAbsolute.length == 0) {
      return null;
    }
    List<Mappoint>? c;
    if (dy == 0) {
      c = coordinatesAbsolute[0];
    } else {
      c = RendererUtils.parallelPath(coordinatesAbsolute[0], dy);
    }

    if (c.length < 2) {
      return null;
    }

    LineString fullPath = new LineString();
    for (int i = 1; i < c.length; i++) {
      LineSegment segment = new LineSegment(c[i - 1], c[i]);
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
