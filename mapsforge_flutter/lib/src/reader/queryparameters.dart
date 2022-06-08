import 'dart:math';

import '../mapfile/subfileparameter.dart';
import '../model/tile.dart';

import 'querycalculations.dart';

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
      this.fromBaseTileX = tile.tileX << zoomLevelDifference;
      this.fromBaseTileY = tile.tileY << zoomLevelDifference;
      this.toBaseTileX = this.fromBaseTileX + (1 << zoomLevelDifference) - 1;
      this.toBaseTileY = this.fromBaseTileY + (1 << zoomLevelDifference) - 1;
      this.useTileBitmask = false;
    } else if (tile.zoomLevel > subFileParameter.baseZoomLevel) {
      // calculate the XY numbers of the parent base tile
      int zoomLevelDifference = tile.zoomLevel - subFileParameter.baseZoomLevel;
      this.fromBaseTileX = tile.tileX >> zoomLevelDifference;
      this.fromBaseTileY = tile.tileY >> zoomLevelDifference;
      this.toBaseTileX = this.fromBaseTileX;
      this.toBaseTileY = this.fromBaseTileY;
      this.useTileBitmask = true;
      this.queryTileBitmask = QueryCalculations.calculateSingleTileBitmask(
          tile, zoomLevelDifference);
    } else {
      // use the tile XY numbers of the requested tile
      this.fromBaseTileX = tile.tileX;
      this.fromBaseTileY = tile.tileY;
      this.toBaseTileX = this.fromBaseTileX;
      this.toBaseTileY = this.fromBaseTileY;
      this.useTileBitmask = false;
    }
  }

  void calculateBaseTiles(
      Tile upperLeft, Tile lowerRight, SubFileParameter subFileParameter) {
    if (upperLeft.zoomLevel < subFileParameter.baseZoomLevel) {
      // here we need to combine multiple base tiles
      int zoomLevelDifference =
          subFileParameter.baseZoomLevel - upperLeft.zoomLevel;
      this.fromBaseTileX = upperLeft.tileX << zoomLevelDifference;
      this.fromBaseTileY = upperLeft.tileY << zoomLevelDifference;
      this.toBaseTileX = (lowerRight.tileX << zoomLevelDifference) +
          (1 << zoomLevelDifference) -
          1;
      this.toBaseTileY = (lowerRight.tileY << zoomLevelDifference) +
          (1 << zoomLevelDifference) -
          1;
      this.useTileBitmask = false;
    } else if (upperLeft.zoomLevel > subFileParameter.baseZoomLevel) {
      // we might have more than just one base tile as we might span boundaries
      int zoomLevelDifference =
          upperLeft.zoomLevel - subFileParameter.baseZoomLevel;
      this.fromBaseTileX = upperLeft.tileX >> zoomLevelDifference;
      this.fromBaseTileY = upperLeft.tileY >> zoomLevelDifference;
      this.toBaseTileX = lowerRight.tileX >> zoomLevelDifference;
      this.toBaseTileY = lowerRight.tileY >> zoomLevelDifference;
      // TODO understand what is going on here. The tileBitmask is used to extract just
      // the data from the base tiles that is relevant for the area, but how can this work
      // for a set of tiles, so not using tileBitmask for the moment.
      this.useTileBitmask = true;
      this.queryTileBitmask = QueryCalculations.calculateTileBitmask(
          upperLeft, lowerRight, zoomLevelDifference);
    } else {
      // we are on the base zoom level, so we just need all tiles in range
      this.fromBaseTileX = upperLeft.tileX;
      this.fromBaseTileY = upperLeft.tileY;
      this.toBaseTileX = lowerRight.tileX;
      this.toBaseTileY = lowerRight.tileY;
      this.useTileBitmask = false;
    }
  }

  void calculateBlocks(SubFileParameter subFileParameter) {
    // calculate the blocks in the file which need to be read
    this.fromBlockX =
        max(this.fromBaseTileX - subFileParameter.boundaryTileLeft, 0);
    this.fromBlockY =
        max(this.fromBaseTileY - subFileParameter.boundaryTileTop, 0);
    this.toBlockX = min(this.toBaseTileX - subFileParameter.boundaryTileLeft,
        subFileParameter.blocksWidth - 1);
    this.toBlockY = min(this.toBaseTileY - subFileParameter.boundaryTileTop,
        subFileParameter.blocksHeight - 1);
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
    return 'QueryParameters{fromBaseTileX: $fromBaseTileX, fromBaseTileY: $fromBaseTileY, fromBlockX: $fromBlockX, fromBlockY: $fromBlockY, queryTileBitmask: $queryTileBitmask, queryZoomLevel: $queryZoomLevel, toBaseTileX: $toBaseTileX, toBaseTileY: $toBaseTileY, toBlockX: $toBlockX, toBlockY: $toBlockY, useTileBitmask: $useTileBitmask}';
  }
}
