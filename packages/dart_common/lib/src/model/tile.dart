import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_common/src/utils/mapsforge_settings_mgr.dart';

/// Represents a rectangular map tile in a hierarchical tiling scheme.
/// 
/// Tiles divide the world map into a grid at different zoom levels, following the
/// standard web mercator tiling scheme. Each tile is uniquely identified by its
/// X/Y coordinates and zoom level:
/// 
/// - Zoom level 0: Single tile (0,0) covers the entire world
/// - Zoom level 1: 2×2 grid of tiles (0,0 to 1,1)
/// - Zoom level n: 2^n × 2^n grid of tiles
/// 
/// Key features:
/// - Hierarchical parent/child relationships
/// - Neighbor tile calculation
/// - Cached boundary calculations for performance
/// - Indoor level support for multi-floor mapping
/// - Efficient coordinate-to-tile conversions
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

  /// Calculates the maximum valid tile coordinate for a given zoom level.
  /// 
  /// At zoom level n, tiles range from 0 to (2^n - 1) in both X and Y directions.
  /// 
  /// [zoomLevel] The zoom level (must be non-negative)
  /// Returns the maximum tile coordinate (2^zoomLevel - 1)
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

  /// Creates a new tile with the specified coordinates and zoom level.
  /// 
  /// [tileX] The X coordinate of the tile (0 to 2^zoomLevel - 1)
  /// [tileY] The Y coordinate of the tile (0 to 2^zoomLevel - 1)
  /// [zoomLevel] The zoom level (must be non-negative)
  /// [indoorLevel] The indoor/floor level for multi-story mapping
  /// 
  /// Asserts that all coordinates are within valid ranges for the zoom level
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

  /// Gets all eight neighboring tiles around this tile.
  /// 
  /// Returns tiles in all cardinal and diagonal directions, wrapping around
  /// the world boundaries as needed (longitude wraps, latitude clamps).
  /// 
  /// Returns a Set containing the 8 neighboring tiles
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

  /// Gets the tile immediately to the west (left) of this tile.
  /// 
  /// Wraps around the world boundary if necessary.
  /// Returns the western neighbor tile
  Tile getLeft() {
    int x = tileX - 1;
    if (x < 0) {
      x = getMaxTileNumber(zoomLevel);
    }
    return Tile(x, tileY, zoomLevel, indoorLevel);
  }

  /// Gets the tile immediately to the east (right) of this tile.
  /// 
  /// Wraps around the world boundary if necessary.
  /// Returns the eastern neighbor tile
  Tile getRight() {
    int x = tileX + 1;
    if (x > getMaxTileNumber(zoomLevel)) {
      x = 0;
    }
    return Tile(x, tileY, zoomLevel, indoorLevel);
  }

  /// Gets the tile immediately to the north (above) of this tile.
  /// 
  /// Wraps around if at the northern boundary.
  /// Returns the northern neighbor tile
  Tile getAbove() {
    int y = tileY - 1;
    if (y < 0) {
      y = getMaxTileNumber(zoomLevel);
    }
    return Tile(tileX, y, zoomLevel, indoorLevel);
  }

  /// Gets the tile immediately to the south (below) of this tile.
  /// 
  /// Wraps around if at the southern boundary.
  /// Returns the southern neighbor tile

  Tile getBelow() {
    int y = tileY + 1;
    if (y > getMaxTileNumber(zoomLevel)) {
      y = 0;
    }
    return Tile(tileX, y, zoomLevel, indoorLevel);
  }

  /// Returns the tile above left
  ///
  /// @return tile above left
  Tile getAboveLeft() {
    int y = tileY - 1;
    int x = tileX - 1;
    if (y < 0) {
      y = getMaxTileNumber(zoomLevel);
    }
    if (x < 0) {
      x = getMaxTileNumber(zoomLevel);
    }
    return Tile(x, y, zoomLevel, indoorLevel);
  }

  /// Returns the tile above right
  ///
  /// @return tile above right
  Tile getAboveRight() {
    int y = tileY - 1;
    int x = tileX + 1;
    if (y < 0) {
      y = getMaxTileNumber(zoomLevel);
    }
    if (x > getMaxTileNumber(zoomLevel)) {
      x = 0;
    }
    return Tile(x, y, zoomLevel, indoorLevel);
  }

  /// Returns the tile below left
  ///
  /// @return tile below left
  Tile getBelowLeft() {
    int y = tileY + 1;
    int x = tileX - 1;
    if (y > getMaxTileNumber(zoomLevel)) {
      y = 0;
    }
    if (x < 0) {
      x = getMaxTileNumber(zoomLevel);
    }
    return Tile(x, y, zoomLevel, indoorLevel);
  }

  /// Returns the tile below right
  ///
  /// @return tile below right
  Tile getBelowRight() {
    int y = tileY + 1;
    int x = tileX + 1;
    if (y > getMaxTileNumber(zoomLevel)) {
      y = 0;
    }
    if (x > getMaxTileNumber(zoomLevel)) {
      x = 0;
    }
    return Tile(x, y, zoomLevel, indoorLevel);
  }

  /// @return the parent tile of this tile or null, if the zoom level of this tile is 0.
  Tile? getParent() {
    if (zoomLevel == 0) {
      return null;
    }

    return Tile((tileX / 2).floor(), (tileY / 2).floor(), (zoomLevel - 1), indoorLevel);
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

    return tileX % 2 + 2 * getParent()!.getShiftX(otherTile);
  }

  int getShiftY(Tile otherTile) {
    if (this == (otherTile)) {
      return 0;
    }

    return tileY % 2 + 2 * getParent()!.getShiftY(otherTile);
  }

  BoundingBox getBoundingBox() {
    if (_boundary != null) return _boundary!;
    MercatorProjection projection = MercatorProjection.fromZoomlevel(zoomLevel);
    _boundary = projection.boundingBoxOfTile(this);
    return _boundary!;
  }

  Mappoint getLeftUpper() {
    if (_leftUpper != null) return _leftUpper!;
    _leftUpper = Mappoint((tileX * MapsforgeSettingsMgr().tileSize), (tileY * MapsforgeSettingsMgr().tileSize));
    return _leftUpper!;
  }

  Mappoint getCenter() {
    if (_center != null) return _center!;
    double tileSize = MapsforgeSettingsMgr().tileSize;
    _center = Mappoint((tileX * tileSize + tileSize / 2).toDouble(), (tileY * tileSize + tileSize / 2).toDouble());
    return _center!;
  }

  MapRectangle getMapBoundary() {
    if (_mapBoundary != null) return _mapBoundary!;
    double tileSize = MapsforgeSettingsMgr().tileSize;
    _mapBoundary = MapRectangle((tileX * tileSize), (tileY * tileSize), (tileX * tileSize + tileSize), (tileY * tileSize + tileSize));
    return _mapBoundary!;
  }

  @override
  String toString() {
    return 'Tile{$tileX/$tileY, $zoomLevel, $indoorLevel}';
  }
}
