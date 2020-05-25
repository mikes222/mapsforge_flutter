import 'package:mapsforge_flutter/src/cache/tilecache.dart';
import 'package:mapsforge_flutter/src/model/mapviewdimension.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/projection/mercatorprojectionimpl.dart';

import '../mapelements/mapelementcontainer.dart';
import '../model/boundingbox.dart';
import '../model/tile.dart';

class LayerUtil {
  /**
   * Upper left tile for an area.
   *
   * @param boundingBox the area boundingBox
   * @param zoomLevel   the zoom level.
   * @param tileSize    the tile size.
   * @return the tile at the upper left of the bbox.
   */
  static Tile getUpperLeft(BoundingBox boundingBox, int zoomLevel, double tileSize) {
    MercatorProjectionImpl mercatorProjectionImpl = MercatorProjectionImpl(tileSize, zoomLevel);
    int tileLeft = mercatorProjectionImpl.longitudeToTileX(boundingBox.minLongitude);
    int tileTop = mercatorProjectionImpl.latitudeToTileY(boundingBox.maxLatitude);
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
  static Tile getLowerRight(BoundingBox boundingBox, int zoomLevel, double tileSize) {
    MercatorProjectionImpl mercatorProjectionImpl = MercatorProjectionImpl(tileSize, zoomLevel);
    int tileRight = mercatorProjectionImpl.longitudeToTileX(boundingBox.maxLongitude);
    int tileBottom = mercatorProjectionImpl.latitudeToTileY(boundingBox.minLatitude);
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

  static List<Tile> getTiles(MapViewDimension mapViewDimension, MapViewPosition mapViewPosition, TileCache tileCache) {
    BoundingBox boundingBox = mapViewPosition.calculateBoundingBox(mapViewDimension.getDimension());
    int zoomLevel = mapViewPosition.zoomLevel;
    double tileSize = mapViewPosition.mercatorProjection.tileSize;
    int tileLeft = mapViewPosition.mercatorProjection.longitudeToTileX(boundingBox.minLongitude);
    int tileTop = mapViewPosition.mercatorProjection.latitudeToTileY(boundingBox.maxLatitude);
    int tileRight = mapViewPosition.mercatorProjection.longitudeToTileX(boundingBox.maxLongitude);
    int tileBottom = mapViewPosition.mercatorProjection.latitudeToTileY(boundingBox.minLatitude);
    int tileHalfX = ((tileRight - tileLeft) / 2).round() + tileLeft;
    int tileHalfY = ((tileBottom - tileTop) / 2).round() + tileTop;

    List<Tile> tiles = new List<Tile>();

    // build tiles starting from the center tile
    for (int tileY = tileHalfY; tileY <= tileBottom; ++tileY) {
      tiles.add(tileCache.getTile(tileHalfX, tileY, zoomLevel, tileSize));
      int xDiff = 1;
      while (true) {
        bool xAdded = false;
        if (tileHalfX + xDiff <= tileRight) {
          tiles.add(tileCache.getTile(tileHalfX + xDiff, tileY, zoomLevel, tileSize));
          xAdded = true;
        }
        if (tileHalfX - xDiff >= tileLeft) {
          tiles.add(tileCache.getTile(tileHalfX - xDiff, tileY, zoomLevel, tileSize));
          xAdded = true;
        }
        if (!xAdded) break;
        ++xDiff;
      }
    }
    for (int tileY = tileHalfY - 1; tileY >= tileTop; --tileY) {
      tiles.add(tileCache.getTile(tileHalfX, tileY, zoomLevel, tileSize));
      int xDiff = 1;
      while (true) {
        bool xAdded = false;
        if (tileHalfX + xDiff <= tileRight) {
          tiles.add(tileCache.getTile(tileHalfX + xDiff, tileY, zoomLevel, tileSize));
          xAdded = true;
        }
        if (tileHalfX - xDiff >= tileLeft) {
          tiles.add(tileCache.getTile(tileHalfX - xDiff, tileY, zoomLevel, tileSize));
          xAdded = true;
        }
        if (!xAdded) break;
        ++xDiff;
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
