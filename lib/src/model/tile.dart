import 'package:mapsforge_flutter/src/utils/mapsforge_constants.dart';

import '../../core.dart';
import '../../maps.dart';
import 'maprectangle.dart';

/// A tile represents a rectangular part of the world map. All tiles can be identified by their X and Y number together
/// with their zoom level. The actual area that a tile covers on a map depends on the underlying map projection.
class Tile {
  /// The X number of this tile.
  final int tileX;

  /// The Y number of this tile.
  final int tileY;

  /// The zoom level of this tile.
  final int zoomLevel;

  /// The indoor level of this tile.
  final int indoorLevel;

  /// The (cached) bounding box of this tile in lat/lon coordinates
  BoundingBox? _boundary;

  /// The (cached) left uppter point of this tile is pixels
  Mappoint? _leftUpper;

  /// The (cached) center of this tile in pixels
  Mappoint? _center;

  /// The (cached) boundary of this tile in pixels
  MapRectangle? _mapBoundary;

  /// @return the maximum valid tile number for the given zoom level, 2<sup>zoomLevel</sup> -1.
  static int getMaxTileNumber(int zoomLevel) {
    assert(zoomLevel >= 0, "zoomLevel must not be negative: $zoomLevel");
    switch (zoomLevel) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 3;
      default:
        return (1 << zoomLevel) - 1;
    }
  }

  /// @param tileX     the X number of the tile.
  /// @param tileY     the Y number of the tile.
  /// @param zoomLevel the zoom level of the tile.
  /// @throws IllegalArgumentException if any of the parameters is invalid.
  Tile(this.tileX, this.tileY, this.zoomLevel, this.indoorLevel)
      : assert(tileX >= 0, "tileX $tileX must not be negative"),
        assert(tileY >= 0, "tileY $tileY must not be negative"),
        assert(zoomLevel >= 0) {
    assert(tileX <= getMaxTileNumber(zoomLevel), "$tileX > ${getMaxTileNumber(zoomLevel)} for zoomlevel $zoomLevel");
    assert(tileY <= getMaxTileNumber(zoomLevel), "$tileY > ${getMaxTileNumber(zoomLevel)} for zoomlevel $zoomLevel");
  }

  void dispose() {}

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tile &&
          runtimeType == other.runtimeType &&
          tileX == other.tileX &&
          tileY == other.tileY &&
          zoomLevel == other.zoomLevel &&
          indoorLevel == other.indoorLevel;

  @override
  int get hashCode => tileX.hashCode ^ tileY.hashCode ^ zoomLevel.hashCode ^ indoorLevel.hashCode << 5;

  /// Returns a set of the eight neighbours of this tile.
  ///
  /// @return neighbour tiles as a set
  Set<Tile> getNeighbours() {
    Set<Tile> neighbours = {};
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
   * Returns the tile to the left of this tile.
   *
   * @return tile to the left.
   */
  Tile getLeft() {
    int x = tileX - 1;
    if (x < 0) {
      x = getMaxTileNumber(this.zoomLevel);
    }
    return new Tile(x, this.tileY, this.zoomLevel, this.indoorLevel);
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
    return new Tile(x, this.tileY, this.zoomLevel, this.indoorLevel);
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
    return new Tile(this.tileX, y, this.zoomLevel, this.indoorLevel);
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
    return new Tile(this.tileX, y, this.zoomLevel, this.indoorLevel);
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
    return new Tile(x, y, this.zoomLevel, this.indoorLevel);
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
    return new Tile(x, y, this.zoomLevel, this.indoorLevel);
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
    return new Tile(x, y, this.zoomLevel, this.indoorLevel);
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
    return new Tile(x, y, this.zoomLevel, this.indoorLevel);
  }

  /// @return the parent tile of this tile or null, if the zoom level of this tile is 0.
  Tile? getParent() {
    if (this.zoomLevel == 0) {
      return null;
    }

    return Tile((this.tileX / 2).floor(), (this.tileY / 2).floor(), (this.zoomLevel - 1), this.indoorLevel);
  }

  /// Returns the childs of this tile. The first two items are the upper row from left to right, the next two items are the lower row.
  List<Tile> getChilds() {
    int x = tileX * 2;
    int y = tileY * 2;
    List<Tile> childs = [];
    childs.add(Tile(x, y, zoomLevel + 1, indoorLevel));
    childs.add(Tile(x + 1, y, zoomLevel + 1, indoorLevel));
    childs.add(Tile(x, y + 1, zoomLevel + 1, indoorLevel));
    childs.add(Tile(x + 1, y + 1, zoomLevel + 1, indoorLevel));
    return childs;
  }

  /// Returns the grandchild-tiles. The tiles are ordered by row, then column
  /// meaning the first 4 tiles are the upper row from left to right.
  List<Tile> getGrandchilds() {
    List<Tile> childs = getChilds();
    List<Tile> result = [];
    for (int i = 0; i < 2; ++i) {
      List<Tile> result0 = [];
      List<Tile> result1 = [];
      List<Tile> grand = childs[i * 2].getChilds();
      result0.add(grand[0]);
      result0.add(grand[1]);
      result1.add(grand[2]);
      result1.add(grand[3]);
      grand = childs[i * 2 + 1].getChilds();
      result0.add(grand[0]);
      result0.add(grand[1]);
      result1.add(grand[2]);
      result1.add(grand[3]);

      result.addAll(result0);
      result.addAll(result1);
    }
    assert(result.length == 16);
    return result;
  }

  int getShiftX(Tile otherTile) {
    if (this == otherTile) {
      return 0;
    }

    return this.tileX % 2 + 2 * getParent()!.getShiftX(otherTile);
  }

  int getShiftY(Tile otherTile) {
    if (this == (otherTile)) {
      return 0;
    }

    return this.tileY % 2 + 2 * getParent()!.getShiftY(otherTile);
  }

  BoundingBox getBoundingBox() {
    if (_boundary != null) return _boundary!;
    Projection projection = MercatorProjection.fromZoomlevel(zoomLevel);
    _boundary = projection.boundingBoxOfTile(this);
    return _boundary!;
  }

  Mappoint getLeftUpper() {
    if (_leftUpper != null) return _leftUpper!;
    _leftUpper = Mappoint((tileX * MapsforgeConstants().tileSize), (tileY * MapsforgeConstants().tileSize));
    return _leftUpper!;
  }

  Mappoint getCenter() {
    if (_center != null) return _center!;
    double tileSize = MapsforgeConstants().tileSize;
    _center = Mappoint((tileX * tileSize + tileSize / 2).toDouble(), (tileY * tileSize + tileSize / 2).toDouble());
    return _center!;
  }

  MapRectangle getMapBoundary() {
    if (_mapBoundary != null) return _mapBoundary!;
    double tileSize = MapsforgeConstants().tileSize;
    _mapBoundary = MapRectangle((tileX * tileSize), (tileY * tileSize), (tileX * tileSize + tileSize), (tileY * tileSize + tileSize));
    return _mapBoundary!;
  }

  @override
  String toString() {
    return 'Tile{$tileX/$tileY, $zoomLevel, $indoorLevel}';
  }
}
