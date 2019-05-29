import '../mapelements/mapelementcontainer.dart';
import '../model/boundingbox.dart';
import '../model/mappoint.dart';
import '../model/tile.dart';
import '../tilestore/tileposition.dart';

import 'mercatorprojection.dart';

class LayerUtil {
  static List<TilePosition> getTilePositions(BoundingBox boundingBox,
      int zoomLevel, Mappoint topLeftPoint, int tileSize) {
    int tileLeft = MercatorProjection.longitudeToTileX(
        boundingBox.minLongitude, zoomLevel);
    int tileTop =
        MercatorProjection.latitudeToTileY(boundingBox.maxLatitude, zoomLevel);
    int tileRight = MercatorProjection.longitudeToTileX(
        boundingBox.maxLongitude, zoomLevel);
    int tileBottom =
        MercatorProjection.latitudeToTileY(boundingBox.minLatitude, zoomLevel);

    int initialCapacity =
        (tileRight - tileLeft + 1) * (tileBottom - tileTop + 1);
    List<TilePosition> tilePositions = new List<TilePosition>(initialCapacity);

    for (int tileY = tileTop; tileY <= tileBottom; ++tileY) {
      for (int tileX = tileLeft; tileX <= tileRight; ++tileX) {
        double pixelX =
            MercatorProjection.tileToPixel(tileX, tileSize) - topLeftPoint.x;
        double pixelY =
            MercatorProjection.tileToPixel(tileY, tileSize) - topLeftPoint.y;

        tilePositions.add(new TilePosition(
            new Tile(tileX, tileY, zoomLevel, tileSize),
            new Mappoint(pixelX, pixelY)));
      }
    }

    return tilePositions;
  }

  /**
   * Upper left tile for an area.
   *
   * @param boundingBox the area boundingBox
   * @param zoomLevel   the zoom level.
   * @param tileSize    the tile size.
   * @return the tile at the upper left of the bbox.
   */
  static Tile getUpperLeft(
      BoundingBox boundingBox, int zoomLevel, int tileSize) {
    int tileLeft = MercatorProjection.longitudeToTileX(
        boundingBox.minLongitude, zoomLevel);
    int tileTop =
        MercatorProjection.latitudeToTileY(boundingBox.maxLatitude, zoomLevel);
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
  static Tile getLowerRight(
      BoundingBox boundingBox, int zoomLevel, int tileSize) {
    int tileRight = MercatorProjection.longitudeToTileX(
        boundingBox.maxLongitude, zoomLevel);
    int tileBottom =
        MercatorProjection.latitudeToTileY(boundingBox.minLatitude, zoomLevel);
    return new Tile(tileRight, tileBottom, zoomLevel, tileSize);
  }

  static Set<Tile> getTilesByTile(Tile upperLeft, Tile lowerRight) {
    Set<Tile> tiles = new Set<Tile>();
    for (int tileY = upperLeft.tileY; tileY <= lowerRight.tileY; ++tileY) {
      for (int tileX = upperLeft.tileX; tileX <= lowerRight.tileX; ++tileX) {
        tiles.add(
            new Tile(tileX, tileY, upperLeft.zoomLevel, upperLeft.tileSize));
      }
    }
    return tiles;
  }

  static Set<Tile> getTiles(
      BoundingBox boundingBox, int zoomLevel, int tileSize) {
    int tileLeft = MercatorProjection.longitudeToTileX(
        boundingBox.minLongitude, zoomLevel);
    int tileTop =
        MercatorProjection.latitudeToTileY(boundingBox.maxLatitude, zoomLevel);
    int tileRight = MercatorProjection.longitudeToTileX(
        boundingBox.maxLongitude, zoomLevel);
    int tileBottom =
        MercatorProjection.latitudeToTileY(boundingBox.minLatitude, zoomLevel);

    Set<Tile> tiles = new Set<Tile>();

    for (int tileY = tileTop; tileY <= tileBottom; ++tileY) {
      for (int tileX = tileLeft; tileX <= tileRight; ++tileX) {
        tiles.add(new Tile(tileX, tileY, zoomLevel, tileSize));
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

  static List<MapElementContainer> collisionFreeOrdered(
      List<MapElementContainer> input) {
    // sort items by priority (highest first)
    input.sort((MapElementContainer a, MapElementContainer b) =>
        a.priority - b.priority);
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
