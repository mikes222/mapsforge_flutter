import '../model/tile.dart';

class QueryCalculations {
  static int calculateSingleTileBitmask(Tile tile, int zoomLevelDifference) {
    if (zoomLevelDifference == 1) {
      return getFirstLevelTileBitmask(tile);
    }

    // calculate the XY numbers of the second level sub-tile
    int subtileX = tile.tileX >> (zoomLevelDifference - 2);
    int subtileY = tile.tileY >> (zoomLevelDifference - 2);

    // calculate the XY numbers of the parent tile
    int parentTileX = subtileX >> 1;
    int parentTileY = subtileY >> 1;

    // determine the correct bitmask for all 16 sub-tiles
    if (parentTileX % 2 == 0 && parentTileY % 2 == 0) {
      return getSecondLevelTileBitmaskUpperLeft(subtileX, subtileY);
    } else if (parentTileX % 2 == 1 && parentTileY % 2 == 0) {
      return getSecondLevelTileBitmaskUpperRight(subtileX, subtileY);
    } else if (parentTileX % 2 == 0 && parentTileY % 2 == 1) {
      return getSecondLevelTileBitmaskLowerLeft(subtileX, subtileY);
    } else {
      return getSecondLevelTileBitmaskLowerRight(subtileX, subtileY);
    }
  }

  static int calculateTileBitmask(
      Tile upperLeft, Tile lowerRight, int zoomLevelDifference) {
    int bitmask = 0;
    for (int x = upperLeft.tileX; x <= lowerRight.tileX; x++) {
      for (int y = upperLeft.tileY; y <= lowerRight.tileY; y++) {
        Tile current =
            new Tile(x, y, upperLeft.zoomLevel, upperLeft.indoorLevel);
        bitmask |= calculateSingleTileBitmask(current, zoomLevelDifference);
      }
    }
    return bitmask;
  }

  static int getFirstLevelTileBitmask(Tile tile) {
    if (tile.tileX % 2 == 0 && tile.tileY % 2 == 0) {
      // upper left quadrant
      return 0xcc00;
    } else if (tile.tileX % 2 == 1 && tile.tileY % 2 == 0) {
      //NOSONAR tiles are always positiv
      // upper right quadrant
      return 0x3300;
    } else if (tile.tileX % 2 == 0 && tile.tileY % 2 == 1) {
      // lower left quadrant
      return 0xcc;
    } else {
      // lower right quadrant
      return 0x33;
    }
  }

  static int getSecondLevelTileBitmaskLowerLeft(int subtileX, int subtileY) {
    if (subtileX % 2 == 0 && subtileY % 2 == 0) {
      // upper left sub-tile
      return 0x80;
    } else if (subtileX % 2 == 1 && subtileY % 2 == 0) {
      // upper right sub-tile
      return 0x40;
    } else if (subtileX % 2 == 0 && subtileY % 2 == 1) {
      // lower left sub-tile
      return 0x8;
    } else {
      // lower right sub-tile
      return 0x4;
    }
  }

  static int getSecondLevelTileBitmaskLowerRight(int subtileX, int subtileY) {
    if (subtileX % 2 == 0 && subtileY % 2 == 0) {
      // upper left sub-tile
      return 0x20;
    } else if (subtileX % 2 == 1 && subtileY % 2 == 0) {
      // upper right sub-tile
      return 0x10;
    } else if (subtileX % 2 == 0 && subtileY % 2 == 1) {
      // lower left sub-tile
      return 0x2;
    } else {
      // lower right sub-tile
      return 0x1;
    }
  }

  static int getSecondLevelTileBitmaskUpperLeft(int subtileX, int subtileY) {
    if (subtileX % 2 == 0 && subtileY % 2 == 0) {
      // upper left sub-tile
      return 0x8000;
    } else if (subtileX % 2 == 1 && subtileY % 2 == 0) {
      // upper right sub-tile
      return 0x4000;
    } else if (subtileX % 2 == 0 && subtileY % 2 == 1) {
      // lower left sub-tile
      return 0x800;
    } else {
      // lower right sub-tile
      return 0x400;
    }
  }

  static int getSecondLevelTileBitmaskUpperRight(int subtileX, int subtileY) {
    if (subtileX % 2 == 0 && subtileY % 2 == 0) {
      // upper left sub-tile
      return 0x2000;
    } else if (subtileX % 2 == 1 && subtileY % 2 == 0) {
      // upper right sub-tile
      return 0x1000;
    } else if (subtileX % 2 == 0 && subtileY % 2 == 1) {
      // lower left sub-tile
      return 0x200;
    } else {
      // lower right sub-tile
      return 0x100;
    }
  }

  QueryCalculations() {
    throw new Exception();
  }
}
