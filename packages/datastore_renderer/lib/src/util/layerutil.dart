import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';

class LayerUtil {
  static Set<Tile> getTilesByTile(Tile upperLeft, Tile lowerRight) {
    Set<Tile> tiles = {};
    for (int tileY = upperLeft.tileY; tileY <= lowerRight.tileY; ++tileY) {
      for (int tileX = upperLeft.tileX; tileX <= lowerRight.tileX; ++tileX) {
        tiles.add(Tile(tileX, tileY, upperLeft.zoomLevel, upperLeft.indoorLevel));
        //        tiles.add(tileCache.getTile(tileX, tileY, zoomLevel, tileSize));
      }
    }
    return tiles;
  }

  static bool haveSpace(RenderInfo item, List<RenderInfo> list) {
    for (RenderInfo outputElement in list) {
      try {
        if (outputElement.clashesWith(item)) {
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
  static List<RenderInfo> removeCollisions(List<RenderInfo> addElements, List<RenderInfo> keepElements) {
    List<RenderInfo> toDraw2 = [];
    for (var newElement in addElements) {
      if (haveSpace(newElement, keepElements)) {
        toDraw2.add(newElement);
      } else {
        //newElement.dispose();
      }
    }
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
