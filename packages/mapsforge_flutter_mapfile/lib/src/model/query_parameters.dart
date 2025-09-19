import 'dart:math';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_debug.dart';
import 'package:mapsforge_flutter_mapfile/src/helper/querycalculations.dart';

class QueryParameters {
  int fromBaseTileX = 0;
  int fromBaseTileY = 0;
  int fromBlockX = 0;
  int fromBlockY = 0;
  int? queryTileBitmask;
  int queryZoomLevel = 65536;
  int toBaseTileX = 0;
  int toBaseTileY = 0;
  int toBlockX = 0;
  int toBlockY = 0;
  bool useTileBitmask = false;

  void calculateBaseTilesSingle(Tile tile, SubFileParameter subFileParameter) {
    if (tile.zoomLevel < subFileParameter.baseZoomLevel) {
      // calculate the XY numbers of the upper left and lower right sub-tiles
      int zoomLevelDifference = subFileParameter.baseZoomLevel - tile.zoomLevel;
      fromBaseTileX = tile.tileX << zoomLevelDifference;
      fromBaseTileY = tile.tileY << zoomLevelDifference;
      toBaseTileX = fromBaseTileX + (1 << zoomLevelDifference) - 1;
      toBaseTileY = fromBaseTileY + (1 << zoomLevelDifference) - 1;
      useTileBitmask = false;
    } else if (tile.zoomLevel > subFileParameter.baseZoomLevel) {
      // calculate the XY numbers of the parent base tile
      int zoomLevelDifference = tile.zoomLevel - subFileParameter.baseZoomLevel;
      fromBaseTileX = tile.tileX >> zoomLevelDifference;
      fromBaseTileY = tile.tileY >> zoomLevelDifference;
      toBaseTileX = fromBaseTileX;
      toBaseTileY = fromBaseTileY;
      useTileBitmask = true;
      queryTileBitmask = QueryCalculations.calculateSingleTileBitmask(tile, zoomLevelDifference);
    } else {
      // use the tile XY numbers of the requested tile
      fromBaseTileX = tile.tileX;
      fromBaseTileY = tile.tileY;
      toBaseTileX = fromBaseTileX;
      toBaseTileY = fromBaseTileY;
      useTileBitmask = false;
    }
  }

  void calculateBaseTiles(Tile upperLeft, Tile lowerRight, SubFileParameter subFileParameter) {
    if (upperLeft.zoomLevel < subFileParameter.baseZoomLevel) {
      // here we need to combine multiple base tiles
      int zoomLevelDifference = subFileParameter.baseZoomLevel - upperLeft.zoomLevel;
      fromBaseTileX = upperLeft.tileX << zoomLevelDifference;
      fromBaseTileY = upperLeft.tileY << zoomLevelDifference;
      toBaseTileX = (lowerRight.tileX << zoomLevelDifference) + (1 << zoomLevelDifference) - 1;
      toBaseTileY = (lowerRight.tileY << zoomLevelDifference) + (1 << zoomLevelDifference) - 1;
      useTileBitmask = false;
    } else if (upperLeft.zoomLevel > subFileParameter.baseZoomLevel) {
      // we might have more than just one base tile as we might span boundaries
      int zoomLevelDifference = upperLeft.zoomLevel - subFileParameter.baseZoomLevel;
      fromBaseTileX = upperLeft.tileX >> zoomLevelDifference;
      fromBaseTileY = upperLeft.tileY >> zoomLevelDifference;
      toBaseTileX = lowerRight.tileX >> zoomLevelDifference;
      toBaseTileY = lowerRight.tileY >> zoomLevelDifference;
      // TODO understand what is going on here. The tileBitmask is used to extract just
      // the data from the base tiles that is relevant for the area, but how can this work
      // for a set of tiles, so not using tileBitmask for the moment.
      useTileBitmask = true;
      queryTileBitmask = QueryCalculations.calculateTileBitmask(upperLeft, lowerRight, zoomLevelDifference);
    } else {
      // we are on the base zoom level, so we just need all tiles in range
      fromBaseTileX = upperLeft.tileX;
      fromBaseTileY = upperLeft.tileY;
      toBaseTileX = lowerRight.tileX;
      toBaseTileY = lowerRight.tileY;
      useTileBitmask = false;
    }
  }

  void calculateBlocks(SubFileParameter subFileParameter) {
    // calculate the blocks (tiles) in the subfile which need to be read
    fromBlockX = max(fromBaseTileX - subFileParameter.boundaryTileLeft, 0);
    fromBlockY = max(fromBaseTileY - subFileParameter.boundaryTileTop, 0);
    toBlockX = min(toBaseTileX - subFileParameter.boundaryTileLeft, subFileParameter.blocksWidth - 1);
    toBlockY = min(toBaseTileY - subFileParameter.boundaryTileTop, subFileParameter.blocksHeight - 1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueryParameters &&
          runtimeType == other.runtimeType &&
          fromBaseTileX == other.fromBaseTileX &&
          fromBaseTileY == other.fromBaseTileY &&
          fromBlockX == other.fromBlockX &&
          fromBlockY == other.fromBlockY &&
          queryTileBitmask == other.queryTileBitmask &&
          queryZoomLevel == other.queryZoomLevel &&
          toBaseTileX == other.toBaseTileX &&
          toBaseTileY == other.toBaseTileY &&
          toBlockX == other.toBlockX &&
          toBlockY == other.toBlockY &&
          useTileBitmask == other.useTileBitmask;

  @override
  int get hashCode =>
      fromBaseTileX.hashCode ^
      fromBaseTileY.hashCode ^
      fromBlockX.hashCode ^
      fromBlockY.hashCode ^
      queryTileBitmask.hashCode ^
      queryZoomLevel.hashCode ^
      toBaseTileX.hashCode ^
      toBaseTileY.hashCode ^
      toBlockX.hashCode ^
      toBlockY.hashCode ^
      useTileBitmask.hashCode;

  @override
  String toString() {
    return 'QueryParameters{fromBaseTileX/Y: $fromBaseTileX/$fromBaseTileY, toBaseTileX/Y: $toBaseTileX/$toBaseTileY, fromBlockX/Y: $fromBlockX/$fromBlockY, toBlockX/Y: $toBlockX/$toBlockY, queryTileBitmask: 0x${queryTileBitmask?.toRadixString(16)}, queryZoomLevel: $queryZoomLevel, useTileBitmask: $useTileBitmask}';
  }
}
