import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/projection/pixelprojection.dart';
import 'package:mapsforge_flutter/src/projection/projection.dart';

import '../datastore/way.dart';
import '../model/mappoint.dart';
import '../model/tag.dart';
import '../model/tile.dart';
import '../renderer/shapecontainer.dart';
import '../renderer/shapetype.dart';
import '../utils/latlongutils.dart';
import 'geometryutils.dart';

/**
 * A PolylineContainer encapsulates the way data retrieved from a map file.
 * <p/>
 * The class uses deferred evaluation for computing the absolute and relative
 * pixel coordinates of the way as many ways will not actually be rendered on a
 * map. In order to save memory, after evaluation, the internally stored way is
 * released.
 */

class PolylineContainer implements ShapeContainer {
  Mappoint? center;
  List<List<Mappoint>>? coordinatesAbsolute;
  List<List<Mappoint>>? coordinatesRelativeToTile;
  final List<Tag> tags;
  final int layer;
  final Tile upperLeft;
  final Tile lowerRight;
  final bool isClosedWay;
  late Way way;

  PolylineContainer(Way way, this.upperLeft, this.lowerRight)
      : tags = way.tags,
        layer = way.layer,
        isClosedWay = LatLongUtils.isClosedWay(way.latLongs[0]) {
    this.way = way;
  }

  PolylineContainer.fromList(List<Mappoint> coordinates, this.upperLeft, this.lowerRight, this.tags)
      : layer = 0,
        isClosedWay = coordinates[0] == (coordinates[coordinates.length - 1]) {
    this.coordinatesAbsolute = [];
    this.coordinatesRelativeToTile = null;
    this.coordinatesAbsolute!.add(List.from(coordinates));
  }

  Mappoint getCenterAbsolute(PixelProjection projection) {
    if (this.way.labelPosition != null) {
      this.center = projection.latLonToPixel(this.way.labelPosition!);
    }
    if (this.center == null) {
      this.center = GeometryUtils.calculateCenterOfBoundingBox(getCoordinatesAbsolute(projection)[0]);
    }
    return this.center!;
  }

  List<List<Mappoint>> getCoordinatesAbsolute(PixelProjection projection) {
    // deferred evaluation as some PolyLineContainers will never be drawn. However,
    // to save memory, after computing the absolute coordinates, the way is released.
    if (coordinatesAbsolute == null) {
      coordinatesAbsolute = [];
      for (int i = 0; i < way.latLongs.length; ++i) {
        List<Mappoint> mp1 = [];
        coordinatesAbsolute!.add(mp1);
        for (int j = 0; j < way.latLongs[i].length; ++j) {
          Mappoint mp2 = projection.latLonToPixel(way.latLongs[i][j]);
          mp1.add(mp2);
        }
      }
      //this.way = null;
    }
    return coordinatesAbsolute!;
  }

  List<List<Mappoint>> getCoordinatesRelativeToOrigin(PixelProjection projection) {
    if (coordinatesRelativeToTile == null) {
      Mappoint tileOrigin = projection.getLeftUpper(upperLeft);
      int count = getCoordinatesAbsolute(projection).length;
      coordinatesRelativeToTile = [];
      for (int i = 0; i < count; ++i) {
        List<Mappoint> mp1 = [];
        coordinatesRelativeToTile!.add(mp1);
        for (int j = 0; j < getCoordinatesAbsolute(projection)[i].length; ++j) {
          Mappoint mp2 = coordinatesAbsolute![i][j].offset(-tileOrigin.x, -tileOrigin.y);
          mp1.add(mp2);
        }
      }
    }
    return coordinatesRelativeToTile!;
  }

  int getLayer() {
    return layer;
  }

  @override
  ShapeType getShapeType() {
    return ShapeType.POLYLINE;
  }

  List<Tag> getTags() {
    return tags;
  }

  Tile getUpperLeft() {
    return this.upperLeft;
  }

  Tile getLowerRight() {
    return this.lowerRight;
  }

  @override
  String toString() {
    return 'PolylineContainer{center: $center, coordinatesAbsolute: $coordinatesAbsolute, coordinatesRelativeToTile: $coordinatesRelativeToTile, tags: $tags, layer: $layer, way: $way}';
  }
}
