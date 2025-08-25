import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';

/// A simple spatial index using a grid-based approach for fast collision detection
class SpatialIndex {
  final double _cellSize;
  final Map<String, List<RenderInfo>> _grid = {};

  SpatialIndex({double cellSize = 256.0}) : _cellSize = cellSize;

  /// Add a render info to the spatial index
  void add(RenderInfo item) {
    final boundary = item.boundaryAbsolute;
    if (boundary != null) {
      final cells = _getCells(boundary);
      for (final cell in cells) {
        _grid.putIfAbsent(cell, () => <RenderInfo>[]).add(item);
      }
    }
  }

  /// Check if an item collides with any existing items in the index
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

  /// Get all grid cells that a boundary intersects
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
