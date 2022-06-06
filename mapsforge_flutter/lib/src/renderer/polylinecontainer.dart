import 'dart:math';

import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/projection/pixelprojection.dart';
import 'package:mapsforge_flutter/src/renderer/minmaxmappoint.dart';
import 'package:mapsforge_flutter/src/utils/reducehelper.dart';

import '../datastore/way.dart';
import '../model/mappoint.dart';
import '../model/tag.dart';
import '../model/tile.dart';
import '../renderer/shapecontainer.dart';
import '../utils/latlongutils.dart';
import 'geometryutils.dart';

/// A PolylineContainer encapsulates the way data retrieved from a map file.
/// <p/>
/// The class uses deferred evaluation for computing the absolute and relative
/// pixel coordinates of the way as many ways will not actually be rendered on a
/// map. In order to save memory, after evaluation, the internally stored way is
/// released.
class PolylineContainer implements ShapeContainer {
  Mappoint? center;
  List<List<Mappoint>>? coordinatesAbsolute;
  List<List<Mappoint>>? coordinatesRelativeToTile;
  final List<Tag> tags;
  final int layer;
  final Tile upperLeft;
  final bool isClosedWay;
  final Way way;

  final double maxGap = 3;

  PolylineContainer(this.way, this.upperLeft)
      : tags = way.tags,
        layer = max(0, way.layer),
        isClosedWay = LatLongUtils.isClosedWay(way.latLongs[0]);

  Mappoint getCenterAbsolute(PixelProjection projection) {
    if (this.way.labelPosition != null) {
      this.center = projection.latLonToPixel(this.way.labelPosition!);
    }
    if (this.center == null) {
      this.center = GeometryUtils.calculateCenterOfBoundingBox(
          getCoordinatesAbsolute(projection)[0]);
    }
    return this.center!;
  }

  List<List<Mappoint>> getCoordinatesAbsolute(PixelProjection projection) {
    // deferred evaluation as some PolyLineContainers will never be drawn. However,
    // to save memory, after computing the absolute coordinates, the way is released.
    if (coordinatesAbsolute == null) {
      coordinatesAbsolute = [];
      way.latLongs.forEach((outer) {
        List<Mappoint> mp1 = outer
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
    }
    return coordinatesAbsolute!;
  }

  List<List<Mappoint>> getCoordinatesRelativeToOrigin(
      PixelProjection projection) {
    if (coordinatesRelativeToTile == null) {
      Mappoint tileOrigin = projection.getLeftUpper(upperLeft);
      getCoordinatesAbsolute(projection);
      coordinatesRelativeToTile = [];

      coordinatesAbsolute!.forEach((outer) {
        List<Mappoint> mp1 = outer
            .map((inner) => inner.offset(-tileOrigin.x, -tileOrigin.y))
            .toList();
        coordinatesRelativeToTile!.add(mp1);

        // MinMaxMappoint minMaxMappoint = MinMaxMappoint(mp1);
        // print(minMaxMappoint);
      });
    }
    return coordinatesRelativeToTile!;
  }

  int getLayer() {
    return layer;
  }

  List<Tag> getTags() {
    return tags;
  }

  Tile getUpperLeft() {
    return this.upperLeft;
  }

  @override
  String toString() {
    return 'PolylineContainer{center: $center, coordinatesAbsolute: $coordinatesAbsolute, coordinatesRelativeToTile: $coordinatesRelativeToTile, tags: $tags, layer: $layer, way: $way}';
  }
}
