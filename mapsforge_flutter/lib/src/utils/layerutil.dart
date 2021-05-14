import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';
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
  static Tile getUpperLeft(BoundingBox boundingBox, int zoomLevel, int indoorLevel, double tileSize) {
    MercatorProjectionImpl mercatorProjectionImpl = MercatorProjectionImpl(tileSize, zoomLevel);
    int tileLeft = mercatorProjectionImpl.longitudeToTileX(boundingBox.minLongitude!);
    int tileTop = mercatorProjectionImpl.latitudeToTileY(boundingBox.maxLatitude!);
    return new Tile(tileLeft, tileTop, zoomLevel, indoorLevel);
  }

  /**
   * Lower right tile for an area.
   *
   * @param boundingBox the area boundingBox
   * @param zoomLevel   the zoom level.
   * @param tileSize    the tile size.
   * @return the tile at the lower right of the bbox.
   */
  static Tile getLowerRight(BoundingBox boundingBox, int zoomLevel, int indoorLevel, double tileSize) {
    MercatorProjectionImpl mercatorProjectionImpl = MercatorProjectionImpl(tileSize, zoomLevel);
    int tileRight = mercatorProjectionImpl.longitudeToTileX(boundingBox.maxLongitude!);
    int tileBottom = mercatorProjectionImpl.latitudeToTileY(boundingBox.minLatitude!);
    return new Tile(tileRight, tileBottom, zoomLevel, indoorLevel);
  }

  static Set<Tile> getTilesByTile(Tile upperLeft, Tile lowerRight) {
    Set<Tile> tiles = new Set<Tile>();
    for (int tileY = upperLeft.tileY; tileY <= lowerRight.tileY; ++tileY) {
      for (int tileX = upperLeft.tileX; tileX <= lowerRight.tileX; ++tileX) {
        tiles.add(new Tile(tileX, tileY, upperLeft.zoomLevel, upperLeft.indoorLevel));
//        tiles.add(tileCache.getTile(tileX, tileY, zoomLevel, tileSize));
      }
    }
    return tiles;
  }

  ///
  /// Get all tiles needed for a given view. The tiles are in the order where it makes most sense for
  /// the user (tile in the middle should be created first
  ///
  static List<Tile> getTiles(ViewModel viewModel, MapViewPosition mapViewPosition) {
    BoundingBox boundingBox = mapViewPosition.calculateBoundingBox(viewModel.viewDimension!)!;
    int zoomLevel = mapViewPosition.zoomLevel;
    int indoorLevel = mapViewPosition.indoorLevel;
    int tileLeft = mapViewPosition.mercatorProjection!.longitudeToTileX(boundingBox.minLongitude!);
    int tileTop = mapViewPosition.mercatorProjection!.latitudeToTileY(boundingBox.maxLatitude!);
    int tileRight = mapViewPosition.mercatorProjection!.longitudeToTileX(boundingBox.maxLongitude!);
    int tileBottom = mapViewPosition.mercatorProjection!.latitudeToTileY(boundingBox.minLatitude!);
    int tileHalfX = ((tileRight - tileLeft) / 2).round() + tileLeft;
    int tileHalfY = ((tileBottom - tileTop) / 2).round() + tileTop;

    List<Tile> tiles = [];

    // build tiles starting from the center tile
    for (int tileY = tileHalfY; tileY <= tileBottom; ++tileY) {
      tiles.add(Tile(tileHalfX, tileY, zoomLevel, indoorLevel));
      int xDiff = 1;
      while (true) {
        bool xAdded = false;
        if (tileHalfX + xDiff <= tileRight) {
          tiles.add(Tile(tileHalfX + xDiff, tileY, zoomLevel, indoorLevel));
          xAdded = true;
        }
        if (tileHalfX - xDiff >= tileLeft) {
          tiles.add(Tile(tileHalfX - xDiff, tileY, zoomLevel, indoorLevel));
          xAdded = true;
        }
        if (!xAdded) break;
        ++xDiff;
      }
    }
    for (int tileY = tileHalfY - 1; tileY >= tileTop; --tileY) {
      tiles.add(Tile(tileHalfX, tileY, zoomLevel, indoorLevel));
      int xDiff = 1;
      while (true) {
        bool xAdded = false;
        if (tileHalfX + xDiff <= tileRight) {
          tiles.add(Tile(tileHalfX + xDiff, tileY, zoomLevel, indoorLevel));
          xAdded = true;
        }
        if (tileHalfX - xDiff >= tileLeft) {
          tiles.add(Tile(tileHalfX - xDiff, tileY, zoomLevel, indoorLevel));
          xAdded = true;
        }
        if (!xAdded) break;
        ++xDiff;
      }
    }
    return tiles;
  }

  /// Transforms a list of MapElements, orders it and removes those elements that overlap.
  /// This operation is useful for an early elimination of elements in a list that will never
  /// be drawn because they overlap.
  ///
  /// @param input list of MapElements
  /// @return collision-free, ordered list, a subset of the input.
  static List<MapElementContainer> collisionFreeOrdered(List<MapElementContainer> input) {
    // sort items by priority (highest first)
    input.sort((MapElementContainer a, MapElementContainer b) => a.priority - b.priority);
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
