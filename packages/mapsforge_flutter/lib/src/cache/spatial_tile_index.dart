import 'dart:collection';
import 'dart:math' as Math;

import 'package:mapsforge_flutter_core/model.dart';

/// A spatial index for tiles using a grid-based approach to optimize
/// boundary-based cache operations and collision detection
class SpatialTileIndex {
  final double _cellSize;
  final Map<String, Set<Tile>> _grid = HashMap<String, Set<Tile>>();
  final Map<Tile, Set<String>> _tileToGridCells = HashMap<Tile, Set<String>>();

  /// Creates a spatial index with the specified cell size in degrees
  /// Smaller cell sizes provide better spatial resolution but use more memory
  SpatialTileIndex({double cellSize = 1.0}) : _cellSize = cellSize;

  // for testing purposes
  Map<Tile, Set<String>> get tileToGridCells => _tileToGridCells;
  Map<String, Set<Tile>> get grid => _grid;

  /// Adds a tile to the spatial index
  void addTile(Tile tile) {
    final BoundingBox bounds = tile.getBoundingBox();
    final Set<String> gridCells = _getGridCells(bounds);

    _tileToGridCells[tile] = gridCells;

    for (final String cell in gridCells) {
      _grid.putIfAbsent(cell, () => HashSet<Tile>()).add(tile);
    }
  }

  /// Removes a tile from the spatial index
  void removeTile(Tile tile) {
    final Set<String>? gridCells = _tileToGridCells.remove(tile);
    if (gridCells != null) {
      for (final String cell in gridCells) {
        final Set<Tile>? cellTiles = _grid[cell];
        if (cellTiles != null) {
          cellTiles.remove(tile);
          if (cellTiles.isEmpty) {
            _grid.remove(cell);
          }
        }
      }
    }
  }

  /// Returns all tiles that intersect with the given bounding box
  Set<Tile> getTilesInBoundary(BoundingBox boundingBox) {
    final Set<String> gridCells = _getGridCells(boundingBox);
    final Set<Tile> result = HashSet<Tile>();

    for (final String cell in gridCells) {
      final Set<Tile>? cellTiles = _grid[cell];
      if (cellTiles != null) {
        for (final Tile tile in cellTiles) {
          // Double-check intersection to handle tiles spanning multiple cells
          if (tile.getBoundingBox().intersects(boundingBox)) {
            result.add(tile);
          }
        }
      }
    }

    return result;
  }

  /// Clears all tiles from the spatial index
  void clear() {
    _grid.clear();
    _tileToGridCells.clear();
  }

  /// Returns the number of tiles in the index
  int get tileCount => _tileToGridCells.length;

  /// Returns the number of grid cells in use
  int get gridCellCount => _grid.length;

  /// Gets statistics about the spatial index
  Map<String, dynamic> getStatistics() {
    int totalTiles = 0;
    int maxTilesPerCell = 0;
    int minTilesPerCell = _grid.isNotEmpty ? _grid.values.first.length : 0;

    for (final Set<Tile> cellTiles in _grid.values) {
      final int count = cellTiles.length;
      totalTiles += count;
      maxTilesPerCell = Math.max(maxTilesPerCell, count);
      minTilesPerCell = Math.min(minTilesPerCell, count);
    }

    final double avgTilesPerCell = _grid.isNotEmpty ? totalTiles / _grid.length : 0.0;

    return {
      'totalTiles': tileCount,
      'gridCells': gridCellCount,
      'avgTilesPerCell': avgTilesPerCell,
      'maxTilesPerCell': maxTilesPerCell,
      'minTilesPerCell': minTilesPerCell,
      'cellSize': _cellSize,
    };
  }

  /// Calculates which grid cells a bounding box spans
  Set<String> _getGridCells(BoundingBox bounds) {
    final Set<String> cells = HashSet<String>();

    final int minLatCell = (bounds.minLatitude / _cellSize).floor();
    final int maxLatCell = (bounds.maxLatitude / _cellSize).floor();
    final int minLonCell = (bounds.minLongitude / _cellSize).floor();
    final int maxLonCell = (bounds.maxLongitude / _cellSize).floor();

    for (int lat = minLatCell; lat <= maxLatCell; lat++) {
      for (int lon = minLonCell; lon <= maxLonCell; lon++) {
        cells.add('${lat}_$lon');
      }
    }

    return cells;
  }
}
