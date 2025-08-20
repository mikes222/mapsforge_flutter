import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:datastore_renderer/src/model/render_info.dart';
import 'package:datastore_renderer/src/model/render_info_collection.dart';

class LayerUtil {
  //static final _log = new Logger('LayerUtil');

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
    Set<Tile> tiles = Set<Tile>();
    for (int tileY = upperLeft.tileY; tileY <= lowerRight.tileY; ++tileY) {
      for (int tileX = upperLeft.tileX; tileX <= lowerRight.tileX; ++tileX) {
        tiles.add(new Tile(tileX, tileY, upperLeft.zoomLevel, upperLeft.indoorLevel));
        //        tiles.add(tileCache.getTile(tileX, tileY, zoomLevel, tileSize));
      }
    }
    return tiles;
  }

  /// Transforms a list of MapElements, orders it and removes those elements that overlap.
  /// This operation is useful for an early elimination of elements in a list that will never
  /// be drawn because they overlap. Overlapping items will be disposed.
  ///
  /// @param input list of MapElements
  /// @return collision-free, ordered list, a subset of the input.
  static RenderInfoCollection collisionFreeOrdered(List<RenderInfo> input, PixelProjection projection) {
    // sort items by priority (highest first)
    input.sort();
    // in order of priority, see if an item can be drawn, i.e. none of the items
    // in the currentItemsToDraw list clashes with it.
    List<RenderInfo> output = [];
    for (RenderInfo item in input) {
      if (haveSpace(item, output, projection)) {
        output.add(item);
      } else {
        //item.dispose();
      }
    }
    return RenderInfoCollection(output);
  }

  static bool haveSpace(RenderInfo item, List<RenderInfo> list, PixelProjection projection) {
    for (RenderInfo outputElement in list) {
      try {
        if (outputElement.clashesWith(item, projection)) {
          //print("$outputElement --------clashesWith-------- $item");
          return false;
        }
      } catch (error) {
        // seems we cannot find out if we clash, so just use it for now
        return true;
      }
    }
    return true;
  }

  /// returns the list of elements which can be added without collisions and disposes() elements which cannot be added
  static List<RenderInfo> removeCollisions(List<RenderInfo> addElements, List<RenderInfo> keepElements, PixelProjection projection) {
    List<RenderInfo> toDraw2 = [];
    addElements.forEach((RenderInfo newElement) {
      if (haveSpace(newElement, keepElements, projection)) {
        toDraw2.add(newElement);
      } else {
        //newElement.dispose();
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
