import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/paintelements/point/mapelementcontainer.dart';

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
    Mappoint center = Mappoint(
        mapViewPosition.projection!
            .longitudeToPixelX(mapViewPosition.longitude!),
        mapViewPosition.projection!
            .latitudeToPixelY(mapViewPosition.latitude!));
    int zoomLevel = mapViewPosition.zoomLevel;
    int indoorLevel = mapViewPosition.indoorLevel;
    int tileLeft = mapViewPosition.projection!
        .pixelXToTileX(max(center.x - viewModel.mapDimension.width / 2, 0));
    int tileRight = mapViewPosition.projection!.pixelXToTileX(min(
        center.x + viewModel.mapDimension.width / 2,
        mapViewPosition.projection!.mapsize.toDouble()));
    int tileTop = mapViewPosition.projection!
        .pixelYToTileY(max(center.y - viewModel.mapDimension.height / 2, 0));
    int tileBottom = mapViewPosition.projection!.pixelYToTileY(min(
        center.y + viewModel.mapDimension.height / 2,
        mapViewPosition.projection!.mapsize.toDouble()));
    int diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 50) _log.info("diff: $diff ms, tileBoundaries2");
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
    //_log.info("$tileTop, $tileBottom, sort ${tileMap.length} items");

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
  /// be drawn because they overlap. Overlapping items will be disposed.
  ///
  /// @param input list of MapElements
  /// @return collision-free, ordered list, a subset of the input.
  static List<MapElementContainer> collisionFreeOrdered(
      List<MapElementContainer> input) {
    // sort items by priority (highest first)
    input.sort();
    // in order of priority, see if an item can be drawn, i.e. none of the items
    // in the currentItemsToDraw list clashes with it.
    List<MapElementContainer> output = [];
    for (MapElementContainer item in input) {
      if (haveSpace(item, output)) {
        output.add(item);
      } else {
        item.dispose();
      }
    }
    return output;
  }

  static bool haveSpace(
      MapElementContainer item, List<MapElementContainer> list) {
    for (MapElementContainer outputElement in list) {
      if (outputElement.clashesWith(item)) {
        //print("$outputElement --------clashesWith-------- $item");
        return false;
      }
    }
    return true;
  }

  /// returns the list of elements which can be added without collisions and disposes() elements which cannot be added
  static List<MapElementContainer> removeCollisions(
      List<MapElementContainer> addElements,
      List<MapElementContainer> keepElements) {
    List<MapElementContainer> toDraw2 = [];
    addElements.forEach((MapElementContainer newElement) {
      if (haveSpace(newElement, keepElements)) {
        toDraw2.add(newElement);
      } else {
        newElement.dispose();
      }
    });
    // print(
    //     "Removed ${addElements.length - toDraw2.length} elements out of ${addElements.length}");
    // if (addElements.length == toDraw2.length && addElements.length > 20) {
    //   toDraw2.forEach((element) {
    //     print(" having ${element.boundaryAbsolute} $element");
    //   });
    // }
    return toDraw2;
  }
}
