import 'dart:math';

import 'rectangle.dart';
import '../utils/mercatorprojection.dart';

import 'boundingbox.dart';
import 'mappoint.dart';

/**
 * A tile represents a rectangular part of the world map. All tiles can be identified by their X and Y number together
 * with their zoom level. The actual area that a tile covers on a map depends on the underlying map projection.
 */
class Tile {
  /**
   * the map size implied by zoom level and tileSize, to avoid multiple computations.
   */
  final int mapSize;

  final int tileSize;

  /**
   * The X number of this tile.
   */
  final int tileX;

  /**
   * The Y number of this tile.
   */
  final int tileY;

  /**
   * The zoom level of this tile.
   */
  final int zoomLevel;

  BoundingBox boundingBox;

  Mappoint origin;

  /**
   * Return the BoundingBox of a rectangle of tiles defined by upper left and lower right tile.
   *
   * @param upperLeft  tile in upper left corner.
   * @param lowerRight tile in lower right corner.
   * @return BoundingBox defined by the area around upperLeft and lowerRight Tile.
   */
  static BoundingBox getBoundingBoxStatic(Tile upperLeft, Tile lowerRight) {
    BoundingBox ul = upperLeft.getBoundingBox();
    BoundingBox lr = lowerRight.getBoundingBox();
    return ul.extendBoundingBox(lr);
  }

  /**
   * Extend of the area defined by the two tiles in absolute coordinates.
   *
   * @param upperLeft  tile in upper left corner of area.
   * @param lowerRight tile in lower right corner of area.
   * @return rectangle with the absolute coordinates.
   */
  static Rectangle getBoundaryAbsoluteStatic(Tile upperLeft, Tile lowerRight) {
    return new Rectangle(
        upperLeft.getOrigin().x,
        upperLeft.getOrigin().y,
        lowerRight.getOrigin().x + upperLeft.tileSize,
        lowerRight.getOrigin().y + upperLeft.tileSize);
  }

  /**
   * Returns true if two tile areas, defined by upper left and lower right tiles, overlap.
   * Precondition: zoom levels of upperLeft/lowerRight and upperLeftOther/lowerRightOther are the
   * same.
   *
   * @param upperLeft       tile in upper left corner of area 1.
   * @param lowerRight      tile in lower right corner of area 1.
   * @param upperLeftOther  tile in upper left corner of area 2.
   * @param lowerRightOther tile in lower right corner of area 2.
   * @return true if the areas overlap, false if zoom levels differ or areas do not overlap.
   */
  static bool tileAreasOverlap(Tile upperLeft, Tile lowerRight,
      Tile upperLeftOther, Tile lowerRightOther) {
    if (upperLeft.zoomLevel != upperLeftOther.zoomLevel) {
      return false;
    }
    if (upperLeft == (upperLeftOther) && lowerRight == lowerRightOther) {
      return true;
    }
    return getBoundaryAbsoluteStatic(upperLeft, lowerRight)
        .intersects(getBoundaryAbsoluteStatic(upperLeftOther, lowerRightOther));
  }

  /**
   * @return the maximum valid tile number for the given zoom level, 2<sup>zoomLevel</sup> -1.
   */
  static int getMaxTileNumber(int zoomLevel) {
    if (zoomLevel < 0) {
      throw new Exception("zoomLevel must not be negative: $zoomLevel");
    } else if (zoomLevel == 0) {
      return 0;
    }
    return (2 << zoomLevel - 1) - 1;
  }

  /**
   * @param tileX     the X number of the tile.
   * @param tileY     the Y number of the tile.
   * @param zoomLevel the zoom level of the tile.
   * @throws IllegalArgumentException if any of the parameters is invalid.
   */
  Tile(this.tileX, this.tileY, this.zoomLevel, this.tileSize)
      : mapSize = MercatorProjection.getMapSize(zoomLevel, tileSize) {
    if (tileX < 0) {
      throw new Exception("tileX must not be negative: $tileX");
    } else if (tileY < 0) {
      throw new Exception("tileY must not be negative: $tileY");
    } else if (zoomLevel < 0) {
      throw new Exception("zoomLevel must not be negative: $zoomLevel");
    }

    int maxTileNumber = getMaxTileNumber(zoomLevel);
    if (tileX > maxTileNumber) {
      throw new Exception(
          "invalid tileX number on zoom level $zoomLevel: $tileX");
    } else if (tileY > maxTileNumber) {
      throw new Exception(
          "invalid tileY number on zoom level $zoomLevel: $tileY");
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tile &&
          runtimeType == other.runtimeType &&
          mapSize == other.mapSize &&
          tileSize == other.tileSize &&
          tileX == other.tileX &&
          tileY == other.tileY &&
          zoomLevel == other.zoomLevel &&
          boundingBox == other.boundingBox &&
          origin == other.origin;

  @override
  int get hashCode =>
      mapSize.hashCode ^
      tileSize.hashCode ^
      tileX.hashCode ^
      tileY.hashCode ^
      zoomLevel.hashCode ^
      boundingBox.hashCode ^
      origin.hashCode;

  /**
   * Gets the geographic extend of this Tile as a BoundingBox.
   *
   * @return boundaries of this tile.
   */
  BoundingBox getBoundingBox() {
    if (this.boundingBox == null) {
      double minLatitude = max(MercatorProjection.LATITUDE_MIN,
          MercatorProjection.tileYToLatitude(tileY + 1, zoomLevel));
      double minLongitude =
          max(-180, MercatorProjection.tileXToLongitude(this.tileX, zoomLevel));
      double maxLatitude = min(MercatorProjection.LATITUDE_MAX,
          MercatorProjection.tileYToLatitude(this.tileY, zoomLevel));
      double maxLongitude =
          min(180, MercatorProjection.tileXToLongitude(tileX + 1, zoomLevel));
      if (maxLongitude == -180) {
        // fix for dateline crossing, where the right tile starts at -180 and causes an invalid bbox
        maxLongitude = 180;
      }
      this.boundingBox =
          new BoundingBox(minLatitude, minLongitude, maxLatitude, maxLongitude);
    }
    return this.boundingBox;
  }

  /**
   * Returns a set of the eight neighbours of this tile.
   *
   * @return neighbour tiles as a set
   */
  Set<Tile> getNeighbours() {
    Set<Tile> neighbours = new Set<Tile>();
    neighbours.add(getLeft());
    neighbours.add(getAboveLeft());
    neighbours.add(getAbove());
    neighbours.add(getAboveRight());
    neighbours.add(getRight());
    neighbours.add(getBelowRight());
    neighbours.add(getBelow());
    neighbours.add(getBelowLeft());
    return neighbours;
  }

  /**
   * Extend of this tile in absolute coordinates.
   *
   * @return rectangle with the absolute coordinates.
   */
  Rectangle getBoundaryAbsolute() {
    return new Rectangle(getOrigin().x, getOrigin().y, getOrigin().x + tileSize,
        getOrigin().y + tileSize);
  }

  /**
   * Extend of this tile in relative (tile) coordinates.
   *
   * @return rectangle with the relative coordinates.
   */
  Rectangle getBoundaryRelative() {
    return new Rectangle(0, 0, tileSize.toDouble(), tileSize.toDouble());
  }

  /**
   * Returns the top-left point of this tile in absolute coordinates.
   *
   * @return the top-left point
   */
  Mappoint getOrigin() {
    if (this.origin == null) {
      int x = MercatorProjection.tileToPixel(this.tileX, this.tileSize);
      int y = MercatorProjection.tileToPixel(this.tileY, this.tileSize);
      this.origin = new Mappoint(x.toDouble(), y.toDouble());
    }
    return this.origin;
  }

  /**
   * Returns the tile to the left of this tile.
   *
   * @return tile to the left.
   */
  Tile getLeft() {
    int x = tileX - 1;
    if (x < 0) {
      x = getMaxTileNumber(this.zoomLevel);
    }
    return new Tile(x, this.tileY, this.zoomLevel, this.tileSize);
  }

  /**
   * Returns the tile to the right of this tile.
   *
   * @return tile to the right
   */
  Tile getRight() {
    int x = tileX + 1;
    if (x > getMaxTileNumber(this.zoomLevel)) {
      x = 0;
    }
    return new Tile(x, this.tileY, this.zoomLevel, this.tileSize);
  }

  /**
   * Returns the tile above this tile.
   *
   * @return tile above
   */
  Tile getAbove() {
    int y = tileY - 1;
    if (y < 0) {
      y = getMaxTileNumber(this.zoomLevel);
    }
    return new Tile(this.tileX, y, this.zoomLevel, this.tileSize);
  }

  /**
   * Returns the tile below this tile.
   *
   * @return tile below
   */

  Tile getBelow() {
    int y = tileY + 1;
    if (y > getMaxTileNumber(this.zoomLevel)) {
      y = 0;
    }
    return new Tile(this.tileX, y, this.zoomLevel, this.tileSize);
  }

  /**
   * Returns the tile above left
   *
   * @return tile above left
   */
  Tile getAboveLeft() {
    int y = tileY - 1;
    int x = tileX - 1;
    if (y < 0) {
      y = getMaxTileNumber(this.zoomLevel);
    }
    if (x < 0) {
      x = getMaxTileNumber(this.zoomLevel);
    }
    return new Tile(x, y, this.zoomLevel, this.tileSize);
  }

  /**
   * Returns the tile above right
   *
   * @return tile above right
   */
  Tile getAboveRight() {
    int y = tileY - 1;
    int x = tileX + 1;
    if (y < 0) {
      y = getMaxTileNumber(this.zoomLevel);
    }
    if (x > getMaxTileNumber(this.zoomLevel)) {
      x = 0;
    }
    return new Tile(x, y, this.zoomLevel, this.tileSize);
  }

  /**
   * Returns the tile below left
   *
   * @return tile below left
   */
  Tile getBelowLeft() {
    int y = tileY + 1;
    int x = tileX - 1;
    if (y > getMaxTileNumber(this.zoomLevel)) {
      y = 0;
    }
    if (x < 0) {
      x = getMaxTileNumber(this.zoomLevel);
    }
    return new Tile(x, y, this.zoomLevel, this.tileSize);
  }

  /**
   * Returns the tile below right
   *
   * @return tile below right
   */
  Tile getBelowRight() {
    int y = tileY + 1;
    int x = tileX + 1;
    if (y > getMaxTileNumber(this.zoomLevel)) {
      y = 0;
    }
    if (x > getMaxTileNumber(this.zoomLevel)) {
      x = 0;
    }
    return new Tile(x, y, this.zoomLevel, this.tileSize);
  }

  /**
   * @return the parent tile of this tile or null, if the zoom level of this tile is 0.
   */
  Tile getParent() {
    if (this.zoomLevel == 0) {
      return null;
    }

    return new Tile((this.tileX / 2).round(), (this.tileY / 2).round(),
        (this.zoomLevel - 1), this.tileSize);
  }

  int getShiftX(Tile otherTile) {
    if (this == otherTile) {
      return 0;
    }

    return this.tileX % 2 + 2 * getParent().getShiftX(otherTile);
  }

  int getShiftY(Tile otherTile) {
    if (this == (otherTile)) {
      return 0;
    }

    return this.tileY % 2 + 2 * getParent().getShiftY(otherTile);
  }

  @override
  String toString() {
    return 'Tile{mapSize: $mapSize, tileSize: $tileSize, tileX: $tileX, tileY: $tileY, zoomLevel: $zoomLevel, boundingBox: $boundingBox, origin: $origin}';
  }
}
