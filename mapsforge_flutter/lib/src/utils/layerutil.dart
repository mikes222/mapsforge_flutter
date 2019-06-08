import 'package:mapsforge_flutter/src/cache/tilecache.dart';
import 'package:mapsforge_flutter/src/model/mapviewdimension.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

import '../mapelements/mapelementcontainer.dart';
import '../model/boundingbox.dart';
import '../model/tile.dart';
import 'mercatorprojection.dart';

class LayerUtil {
  /**
   * Upper left tile for an area.
   *
   * @param boundingBox the area boundingBox
   * @param zoomLevel   the zoom level.
   * @param tileSize    the tile size.
   * @return the tile at the upper left of the bbox.
   */
  static Tile getUpperLeft(BoundingBox boundingBox, int zoomLevel, int tileSize) {
    int tileLeft = MercatorProjection.longitudeToTileX(boundingBox.minLongitude, zoomLevel);
    int tileTop = MercatorProjection.latitudeToTileY(boundingBox.maxLatitude, zoomLevel);
    return new Tile(tileLeft, tileTop, zoomLevel, tileSize);
  }

  /**
   * Lower right tile for an area.
   *
   * @param boundingBox the area boundingBox
   * @param zoomLevel   the zoom level.
   * @param tileSize    the tile size.
   * @return the tile at the lower right of the bbox.
   */
  static Tile getLowerRight(BoundingBox boundingBox, int zoomLevel, int tileSize) {
    int tileRight = MercatorProjection.longitudeToTileX(boundingBox.maxLongitude, zoomLevel);
    int tileBottom = MercatorProjection.latitudeToTileY(boundingBox.minLatitude, zoomLevel);
    return new Tile(tileRight, tileBottom, zoomLevel, tileSize);
  }

  static Set<Tile> getTilesByTile(Tile upperLeft, Tile lowerRight) {
    Set<Tile> tiles = new Set<Tile>();
    for (int tileY = upperLeft.tileY; tileY <= lowerRight.tileY; ++tileY) {
      for (int tileX = upperLeft.tileX; tileX <= lowerRight.tileX; ++tileX) {
        tiles.add(new Tile(tileX, tileY, upperLeft.zoomLevel, upperLeft.tileSize));
//        tiles.add(tileCache.getTile(tileX, tileY, zoomLevel, tileSize));
      }
    }
    return tiles;
  }

  static List<Tile> getTiles(MapViewDimension mapViewDimension, MapViewPosition mapViewPosition, int tileSize, TileCache tileCache) {
    BoundingBox boundingBox = mapViewPosition.calculateBoundingBox(tileSize, mapViewDimension.getDimension());
    int zoomLevel = mapViewPosition.zoomLevel;
    int tileLeft = MercatorProjection.longitudeToTileX(boundingBox.minLongitude, zoomLevel);
    int tileTop = MercatorProjection.latitudeToTileY(boundingBox.maxLatitude, zoomLevel);
    int tileRight = MercatorProjection.longitudeToTileX(boundingBox.maxLongitude, zoomLevel);
    int tileBottom = MercatorProjection.latitudeToTileY(boundingBox.minLatitude, zoomLevel);
    int tileHalfX = ((tileRight - tileLeft) / 2).round() + tileLeft;
    int tileHalfY = ((tileBottom - tileTop) / 2).round() + tileTop;

    List<Tile> tiles = new List<Tile>();

    // build tiles starting from the center tile
    for (int tileY = tileHalfY; tileY <= tileBottom; ++tileY) {
      for (int tileX = tileHalfX; tileX <= tileRight; ++tileX) {
        tiles.add(tileCache.getTile(tileX, tileY, zoomLevel, tileSize));
      }
      for (int tileX = tileHalfX - 1; tileX >= tileLeft; --tileX) {
        tiles.add(tileCache.getTile(tileX, tileY, zoomLevel, tileSize));
      }
    }
    for (int tileY = tileHalfY - 1; tileY >= tileTop; --tileY) {
      for (int tileX = tileHalfX; tileX <= tileRight; ++tileX) {
        tiles.add(tileCache.getTile(tileX, tileY, zoomLevel, tileSize));
      }
      for (int tileX = tileHalfX - 1; tileX >= tileLeft; --tileX) {
        tiles.add(tileCache.getTile(tileX, tileY, zoomLevel, tileSize));
      }
    }
    return tiles;
  }

  /**
   * Transforms a list of MapElements, orders it and removes those elements that overlap.
   * This operation is useful for an early elimination of elements in a list that will never
   * be drawn because they overlap.
   *
   * @param input list of MapElements
   * @return collision-free, ordered list, a subset of the input.
   */

  static List<MapElementContainer> collisionFreeOrdered(List<MapElementContainer> input) {
    // sort items by priority (highest first)
    input.sort((MapElementContainer a, MapElementContainer b) => a.priority - b.priority);
    //Collections.sort(input, Collections.reverseOrder());
    // in order of priority, see if an item can be drawn, i.e. none of the items
    // in the currentItemsToDraw list clashes with it.
    List<MapElementContainer> output = new List<MapElementContainer>();
    for (MapElementContainer item in input) {
      bool hasSpace = true;
      for (MapElementContainer outputElement in output) {
        if (outputElement.clashesWith(item)) {
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
