import 'dart:math';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/utils/timing.dart';

import '../layer/job/job.dart';
import '../layer/job/jobqueue.dart';
import '../layer/job/jobset.dart';
import '../rendertheme/renderinfo.dart';

class LayerUtil {
  static final _log = new Logger('LayerUtil');

  static JobSet? submitJobSet(
      ViewModel viewModel, MapViewPosition mapViewPosition, JobQueue jobQueue) {
    //_log.info("viewModel ${viewModel.viewDimension}");
    Timing timing = Timing(log: _log, active: true);
    List<Tile> tiles = getTiles(viewModel, mapViewPosition);
    JobSet jobSet = JobSet();
    tiles.forEach((Tile tile) {
      Job job = Job(tile, false, viewModel.displayModel.tileSize);
      jobSet.add(job);
    });
    timing.lap(50, "${jobSet.jobs.length} missing tiles");
    //_log.info("JobSets created: ${jobSet.jobs.length}");
    if (jobSet.jobs.length > 0) {
      jobQueue.processJobset(jobSet);
      return jobSet;
    }
    return null;
  }

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
      ViewModel viewModel, MapViewPosition mapViewPosition) {
    Mappoint center = mapViewPosition.getCenter();
    int zoomLevel = mapViewPosition.zoomLevel;
    int indoorLevel = mapViewPosition.indoorLevel;
    double halfWidth = viewModel.mapDimension.width / 2;
    double halfHeight = viewModel.mapDimension.height / 2;
    if (mapViewPosition.rotation > 2) {
      // we rotate. Use the max side for both width and height
      halfWidth = max(halfWidth, halfHeight);
      halfHeight = max(halfWidth, halfHeight);
    }
    // rising from 0 to 45, then falling to 0 at 90°
    int degreeDiff = 45 - ((mapViewPosition.rotation) % 90 - 45).round().abs();
    int tileLeft =
        mapViewPosition.projection.pixelXToTileX(max(center.x - halfWidth, 0));
    int tileRight = mapViewPosition.projection.pixelXToTileX(min(
        center.x + halfWidth, mapViewPosition.projection.mapsize.toDouble()));
    int tileTop =
        mapViewPosition.projection.pixelYToTileY(max(center.y - halfHeight, 0));
    int tileBottom = mapViewPosition.projection.pixelYToTileY(min(
        center.y + halfHeight, mapViewPosition.projection.mapsize.toDouble()));
    if (degreeDiff > 5) {
      tileLeft = max(tileLeft - 1, 0);
      tileRight = min(tileRight + 1,
          mapViewPosition.projection.scalefactor.scalefactor.ceil());
      tileTop = max(tileTop - 1, 0);
      tileBottom = min(tileBottom + 1,
          mapViewPosition.projection.scalefactor.scalefactor.ceil());
    }
    // shift the center to the left-upper corner of a tile since we will calculate the distance to the left-upper corners of each tile
    center = center.offset(-viewModel.displayModel.tileSize / 2,
        -viewModel.displayModel.tileSize / 2);
    Map<Tile, double> tileMap = Map<Tile, double>();
    for (int tileY = tileTop; tileY <= tileBottom; ++tileY) {
      for (int tileX = tileLeft; tileX <= tileRight; ++tileX) {
        Tile tile = Tile(tileX, tileY, zoomLevel, indoorLevel);
        Mappoint leftUpper = mapViewPosition.projection.getLeftUpper(tile);
        tileMap[tile] =
            (pow(leftUpper.x - center.x, 2) + pow(leftUpper.y - center.y, 2))
                .toDouble();
      }
    }
    //_log.info("$tileTop, $tileBottom, sort ${tileMap.length} items");

    List<Tile> sortedKeys = tileMap.keys.toList(growable: false)
      ..sort((k1, k2) => tileMap[k1]!.compareTo(tileMap[k2]!));
    return sortedKeys;
  }

  /// Transforms a list of MapElements, orders it and removes those elements that overlap.
  /// This operation is useful for an early elimination of elements in a list that will never
  /// be drawn because they overlap. Overlapping items will be disposed.
  ///
  /// @param input list of MapElements
  /// @return collision-free, ordered list, a subset of the input.
  static List<RenderInfo> collisionFreeOrdered(
      List<RenderInfo> input, PixelProjection projection) {
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
    return output;
  }

  static bool haveSpace(
      RenderInfo item, List<RenderInfo> list, PixelProjection projection) {
    for (RenderInfo outputElement in list) {
      if (outputElement.clashesWith(item, projection)) {
        //print("$outputElement --------clashesWith-------- $item");
        return false;
      }
    }
    return true;
  }

  /// returns the list of elements which can be added without collisions and disposes() elements which cannot be added
  static List<RenderInfo> removeCollisions(List<RenderInfo> addElements,
      List<RenderInfo> keepElements, PixelProjection projection) {
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
