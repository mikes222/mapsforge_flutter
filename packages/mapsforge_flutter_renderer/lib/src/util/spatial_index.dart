import 'package:dart_rendertheme/model.dart';
import 'package:mapsforge_flutter_core/model.dart';

/// High-performance spatial index using grid-based partitioning for collision detection.
///
/// This class implements an optimized spatial indexing system that partitions space
/// into a regular grid to enable fast collision detection between map elements.
/// It provides O(1) insertion and O(log n) collision detection performance.
///
/// Key features:
/// - Grid-based spatial partitioning for performance
/// - Configurable cell size for different use cases
/// - Fast collision detection with boundary checking
/// - Memory-efficient storage with sparse grid representation
/// - Exception handling for robust collision detection
class SpatialIndex {
  /// Size of each grid cell in logical pixels.
  final double _cellSize;

  /// Sparse grid storage mapping cell coordinates to render items.
  final Map<String, List<RenderInfo>> _grid = {};

  /// Creates a new spatial index with the specified cell size.
  ///
  /// [cellSize] Size of each grid cell in logical pixels (default: 256.0)
  /// Smaller cells provide more precise collision detection but use more memory
  SpatialIndex({double cellSize = 256.0}) : _cellSize = cellSize;

  /// Adds a render item to the spatial index.
  ///
  /// The item is added to all grid cells that intersect with its boundary.
  /// Items without boundaries are ignored for performance.
  ///
  /// [item] Render item to add to the index
  void add(RenderInfo item) {
    final boundary = item.boundaryAbsolute;
    if (boundary != null) {
      final cells = _getCells(boundary);
      for (final cell in cells) {
        _grid.putIfAbsent(cell, () => <RenderInfo>[]).add(item);
      }
    }
  }

  /// Checks if an item collides with any existing items in the index.
  ///
  /// Uses grid-based lookup to efficiently check only items in nearby cells.
  /// Handles exceptions gracefully by assuming no collision on error.
  ///
  /// [item] Item to check for collisions
  /// Returns true if collision detected, false otherwise
  bool hasCollision(RenderInfo item) {
    final boundary = item.boundaryAbsolute;
    if (boundary == null) return false;

    final cells = _getCells(boundary);
    for (final cell in cells) {
      final cellItems = _grid[cell];
      if (cellItems != null) {
        for (final existing in cellItems) {
          try {
            if (existing.clashesWith(item)) {
              return true;
            }
          } catch (error) {
            // If we can't determine collision, assume no collision
            continue;
          }
        }
      }
    }
    return false;
  }

  /// Gets all grid cell identifiers that intersect with the given boundary.
  ///
  /// Calculates the range of cells covered by the boundary and returns
  /// string identifiers for efficient map lookup.
  ///
  /// [boundary] Rectangle boundary to find intersecting cells for
  /// Returns list of cell identifier strings
  List<String> _getCells(MapRectangle boundary) {
    final minX = (boundary.left / _cellSize).floor();
    final maxX = (boundary.right / _cellSize).floor();
    final minY = (boundary.top / _cellSize).floor();
    final maxY = (boundary.bottom / _cellSize).floor();

    final cells = <String>[];
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        cells.add('${x}_$y');
      }
    }
    return cells;
  }

  /// Clear the spatial index
  void clear() {
    _grid.clear();
  }

  /// Get statistics about the spatial index
  Map<String, dynamic> getStats() {
    int totalItems = 0;
    int maxItemsPerCell = 0;
    for (final items in _grid.values) {
      totalItems += items.length;
      if (items.length > maxItemsPerCell) {
        maxItemsPerCell = items.length;
      }
    }

    return {
      'totalCells': _grid.length,
      'totalItems': totalItems,
      'maxItemsPerCell': maxItemsPerCell,
      'avgItemsPerCell': _grid.isEmpty ? 0.0 : totalItems / _grid.length,
    };
  }
}
