import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';

import '../mapelements/mapelementcontainer.dart';
import '../model/boundingbox.dart';
import '../model/tile.dart';

class LayerUtil {
  static final _log = new Logger('LayerUtil');

  /**
   * Upper left tile for an area.
   *
   * @param boundingBox the area boundingBox
   * @param zoomLevel   the zoom level.
   * @param tileSize    the tile size.
   * @return the tile at the upper left of the bbox.
   */
  // static Tile getUpperLeft(BoundingBox boundingBox, int zoomLevel, int indoorLevel, double tileSize) {
  //   MercatorProjectionImpl mercatorProjectionImpl = MercatorProjectionImpl(tileSize, zoomLevel);
  //   int tileLeft = mercatorProjectionImpl.longitudeToTileX(boundingBox.minLongitude);
  //   int tileTop = mercatorProjectionImpl.latitudeToTileY(boundingBox.maxLatitude);
  //   return new Tile(tileLeft, tileTop, zoomLevel, indoorLevel);
  // }

  /**
   * Lower right tile for an area.
   *
   * @param boundingBox the area boundingBox
   * @param zoomLevel   the zoom level.
   * @param tileSize    the tile size.
   * @return the tile at the lower right of the bbox.
   */
  // static Tile getLowerRight(BoundingBox boundingBox, int zoomLevel, int indoorLevel, double tileSize) {
  //   MercatorProjectionImpl mercatorProjectionImpl = MercatorProjectionImpl(tileSize, zoomLevel);
  //   int tileRight = mercatorProjectionImpl.longitudeToTileX(boundingBox.maxLongitude);
  //   int tileBottom = mercatorProjectionImpl.latitudeToTileY(boundingBox.minLatitude);
  //   return new Tile(tileRight, tileBottom, zoomLevel, indoorLevel);
  // }

  static Set<Tile> getTilesByTile(Tile upperLeft, Tile lowerRight) {
    Set<Tile> tiles = new Set<Tile>();
    for (int tileY = upperLeft.tileY; tileY <= lowerRight.tileY; ++tileY) {
      for (int tileX = upperLeft.tileX; tileX <= lowerRight.tileX; ++tileX) {
        tiles.add(
            new Tile(tileX, tileY, upperLeft.zoomLevel, upperLeft.indoorLevel));
//        tiles.add(tileCache.getTile(tileX, tileY, zoomLevel, tileSize));
      }
    }
    return tiles;
  }

  ///
  /// Get all tiles needed for a given view. The tiles are in the order where it makes most sense for
  /// the user (tile in the middle should be created first
  ///
  static List<Tile> getTiles(
      ViewModel viewModel, MapViewPosition mapViewPosition, int time) {
    BoundingBox boundingBox =
        mapViewPosition.calculateBoundingBox(viewModel.viewDimension!);
    int zoomLevel = mapViewPosition.zoomLevel;
    int indoorLevel = mapViewPosition.indoorLevel;
    int tileLeft =
        mapViewPosition.projection!.longitudeToTileX(boundingBox.minLongitude);
    int tileRight =
        mapViewPosition.projection!.longitudeToTileX(boundingBox.maxLongitude);
    int diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 50) _log.info("diff: $diff ms, tileBoundaries1");
    int tileTop =
        mapViewPosition.projection!.latitudeToTileY(boundingBox.maxLatitude);
    int tileBottom =
        mapViewPosition.projection!.latitudeToTileY(boundingBox.minLatitude);
    diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 50) _log.info("diff: $diff ms, tileBoundaries2");
    Mappoint center = mapViewPosition.projection!.latLonToPixel(LatLong(
        boundingBox.minLatitude +
            (boundingBox.maxLatitude - boundingBox.minLatitude) / 2,
        boundingBox.minLongitude +
            (boundingBox.maxLongitude - boundingBox.minLongitude) / 2));
    diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 50) _log.info("diff: $diff ms, shift");
    // shift the center to the left-upper corner of a tile since we will calculate the distance to the left-upper corners of each tile
    center = center.offset(-viewModel.displayModel.tileSize / 2,
        -viewModel.displayModel.tileSize / 2);
    Map<Tile, double> tileMap = Map<Tile, double>();
    for (int tileY = tileTop; tileY <= tileBottom; ++tileY) {
      for (int tileX = tileLeft; tileX <= tileRight; ++tileX) {
        Tile tile = Tile(tileX, tileY, zoomLevel, indoorLevel);
        Mappoint leftUpper = mapViewPosition.projection!.getLeftUpper(tile);
        tileMap[tile] =
            (pow(leftUpper.x - center.x, 2) + pow(leftUpper.y - center.y, 2))
                .toDouble();
      }
    }
    //print("${boundingBox.minLatitude}, $tileTop, $tileBottom, sort ${tileMap.length} items");

    diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 50) _log.info("diff: $diff ms, forfor");
    List<Tile> sortedKeys = tileMap.keys.toList(growable: false)
      ..sort((k1, k2) => tileMap[k1]!.compareTo(tileMap[k2]!));
    diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 50) _log.info("diff: $diff ms, sort");
    return sortedKeys;
  }

  /// Transforms a list of MapElements, orders it and removes those elements that overlap.
  /// This operation is useful for an early elimination of elements in a list that will never
  /// be drawn because they overlap.
  ///
  /// @param input list of MapElements
  /// @return collision-free, ordered list, a subset of the input.
  static List<MapElementContainer> collisionFreeOrdered(
      List<MapElementContainer> input) {
    // sort items by priority (highest first)
    input.sort((MapElementContainer a, MapElementContainer b) =>
        a.priority - b.priority);
    //Collections.sort(input, Collections.reverseOrder());
    // in order of priority, see if an item can be drawn, i.e. none of the items
    // in the currentItemsToDraw list clashes with it.
    List<MapElementContainer> output = [];
    for (MapElementContainer item in input) {
      bool hasSpace = true;
      for (MapElementContainer outputElement in output) {
        if (outputElement.clashesWith(item)) {
          //print("$outputElement --------clashesWith-------- $item");
          hasSpace = false;
          break;
        }
      }
      if (hasSpace) {
        output.add(item);
      }
    }
    return output;
  }
}
