import 'package:dart_rendertheme/model.dart';
import 'package:mapsforge_flutter_renderer/src/util/spatial_index.dart';
import 'package:mapsforge_flutter_core/model.dart';

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
    // Use spatial indexing for better performance when dealing with many elements
    if (addElements.length > 10 || keepElements.length > 10) {
      return _removeCollisionsWithSpatialIndex(addElements, keepElements);
    }

    // Use original algorithm for small lists
    List<RenderInfo> toDraw2 = [];
    for (var newElement in addElements) {
      if (haveSpace(newElement, keepElements)) {
        toDraw2.add(newElement);
      } else {
        //newElement.dispose();
      }
    }
    return toDraw2;
  }

  /// Optimized collision removal using spatial indexing
  static List<RenderInfo> _removeCollisionsWithSpatialIndex(List<RenderInfo> addElements, List<RenderInfo> keepElements) {
    final spatialIndex = SpatialIndex(cellSize: 128.0);

    // Add all keep elements to spatial index
    for (final element in keepElements) {
      spatialIndex.add(element);
    }

    final toDraw = <RenderInfo>[];

    // Check each new element against spatial index
    for (final newElement in addElements) {
      if (!spatialIndex.hasCollision(newElement)) {
        toDraw.add(newElement);
        spatialIndex.add(newElement); // Add to index for subsequent collision checks
      }
    }

    return toDraw;
  }
}
