import 'dart:typed_data';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';

/// A kind of cache for hgt calculation. The projections is always the same while calculating for a tile and the file is mostly the same - except for calculations
/// beyond the boundary of the hgt file.
class HgtInfo {
  final PixelProjection projection;

  final HgtProvider hgtProvider;

  HgtFile? hgtFile;

  HgtInfo({required this.projection, required this.hgtProvider});

  /// Only for HillshadingRenderer
  int? elevationAt(double latitude, double longitude) {
    return HgtFile.ocean;
    //return hgtFile.elevationAt(latitude, longitude);
  }

  /// Finds the elevation points for the given tile. We find all elevations inbetween the tile as well as the points immediately surrounding the tile.
  _ElevationGrid? _calculateGrid({required Mappoint leftUpper, required int tileSize}) {
    if (hgtFile == null) {
      ILatLong leftUpperLL = projection.pixelToLatLong(leftUpper.x, leftUpper.y);
      hgtFile = hgtProvider.getForLatLon(leftUpperLL.latitude, leftUpperLL.longitude);
    }
    HgtRastering? hgtRastering = hgtFile!.raster(projection);
    // if (hgtRastering == null) {
    //   // we may start with an existing file in the middle of the tile, todo missing data
    //   ILatLong leftUpperLL = projection.pixelToLatLong(leftUpper.x + tileSize, leftUpper.y);
    //   hgtFile = hgtProvider.getForLatLon(leftUpperLL.latitude, leftUpperLL.longitude);
    //   hgtRastering = hgtFile!.raster(projection);
    // }
    if (hgtRastering == null) {
      return null;
    }
    // The index of the elevation in the hgtFile [0..column/row - 1]
    int leftColumnIdx = hgtRastering.xPositions.lastIndexWhere((test) => test <= leftUpper.x);
    int topRowIdx = hgtRastering.yPositions.lastIndexWhere((test) => test <= leftUpper.y);
    // since we searched for the file at the left-top corner we should always have elevation points at the left and upper side
    assert(leftColumnIdx >= 0);
    assert(topRowIdx >= 0);

    int rightColumnIdx = hgtRastering.xPositions.indexWhere((test) => test >= leftUpper.x + tileSize, leftColumnIdx);
    int bottomRowIdx = hgtRastering.yPositions.indexWhere((test) => test >= leftUpper.y + tileSize, topRowIdx);

    if (rightColumnIdx == -1) {
      rightColumnIdx = hgtRastering.xPositions.length;
    }
    if (bottomRowIdx == -1) {
      bottomRowIdx = hgtRastering.yPositions.length;
    }

    _ElevationGrid elevationGrid = _createGrid(
      leftUpper: leftUpper,
      leftColumnIdx: leftColumnIdx,
      topRowIdx: topRowIdx,
      rightColumnIdx: rightColumnIdx,
      bottomRowIdx: bottomRowIdx,
      hgtRastering: hgtRastering,
    );
    if (bottomRowIdx == hgtRastering.yPositions.length) {
      _ElevationGrid? elevationGrid2 = _extendGrid(leftUpper: leftUpper, tileSize: tileSize, xCheck: 0, yCheck: tileSize);
      if (elevationGrid2 != null) {
        elevationGrid = elevationGrid.appendBottom(elevationGrid2);
      }
    }
    if (rightColumnIdx == hgtRastering.xPositions.length) {
      _ElevationGrid? elevationGrid2 = _extendGrid(leftUpper: leftUpper, tileSize: tileSize, xCheck: tileSize, yCheck: 0);
      if (elevationGrid2 != null) {
        elevationGrid = elevationGrid.appendRight(elevationGrid2);
      }
    }
    // todo we may miss data at the right-bottom side of the tile
    return elevationGrid.finalize(tileSize);
  }

  _ElevationGrid? _extendGrid({required Mappoint leftUpper, required int tileSize, required int xCheck, required int yCheck}) {
    ILatLong leftUpperLL = projection.pixelToLatLong(leftUpper.x + xCheck, leftUpper.y + yCheck);
    HgtFile hgtFile = hgtProvider.getForLatLon(leftUpperLL.latitude, leftUpperLL.longitude);
    HgtRastering? hgtRastering = hgtFile.raster(projection);
    if (hgtRastering == null) {
      // we may start with an existing file in the middle of the tile, todo missing data
      return null;
    }
    // The index of the elevation in the hgtFile [0..column/row - 1]
    int leftColumnIdx = hgtRastering.xPositions.lastIndexWhere((test) => test <= leftUpper.x);
    int topRowIdx = hgtRastering.yPositions.lastIndexWhere((test) => test <= leftUpper.y);
    if (leftColumnIdx == -1) leftColumnIdx = 0;
    if (topRowIdx == -1) topRowIdx = 0;
    // since we searched for the file at the left-top corner we should always have elevation points at the left and upper side
    assert(leftColumnIdx >= 0);
    assert(topRowIdx >= 0);

    int rightColumnIdx = hgtRastering.xPositions.indexWhere((test) => test >= leftUpper.x + tileSize, leftColumnIdx);
    int bottomRowIdx = hgtRastering.yPositions.indexWhere((test) => test >= leftUpper.y + tileSize, topRowIdx);

    if (rightColumnIdx == -1) {
      rightColumnIdx = hgtFile.columns;
    }
    if (bottomRowIdx == -1) {
      bottomRowIdx = hgtFile.rows;
    }

    return _createGrid(
      leftUpper: leftUpper,
      leftColumnIdx: leftColumnIdx,
      topRowIdx: topRowIdx,
      rightColumnIdx: rightColumnIdx,
      bottomRowIdx: bottomRowIdx,
      hgtRastering: hgtRastering,
    );
  }

  _ElevationGrid _createGrid({
    required Mappoint leftUpper,
    required int leftColumnIdx,
    required int topRowIdx,
    required int rightColumnIdx,
    required int bottomRowIdx,
    required HgtRastering hgtRastering,
  }) {
    assert(leftColumnIdx < rightColumnIdx, "leftColumnIdx: $leftColumnIdx, rightColumnIdx: $rightColumnIdx");
    assert(topRowIdx < bottomRowIdx, "topRowIdx: $topRowIdx, bottomRowIdx: $bottomRowIdx");

    _ElevationGrid elevationGrid = _ElevationGrid(rightColumnIdx - leftColumnIdx + 1, bottomRowIdx - topRowIdx + 1);
    for (int row = 0; row < elevationGrid.rows; ++row) {
      if (topRowIdx + row >= hgtRastering.yPositions.length) {
        continue;
      }
      double tileY = hgtRastering.yPositions[topRowIdx + row] - leftUpper.y;
      for (int column = 0; column < elevationGrid.columns; ++column) {
        if (leftColumnIdx + column >= hgtRastering.xPositions.length) {
          continue;
        }
        double tileX = hgtRastering.xPositions[leftColumnIdx + column] - leftUpper.x;
        int elevation = hgtRastering.elevation(leftColumnIdx + column, topRowIdx + row);
        _ElevationPoint elevationPoint = _ElevationPoint(tileX.round(), tileY.round(), elevation);
        elevationGrid.set(column, row, elevationPoint);
      }
    }
    // todo we may miss data at the right side of the tile
    return elevationGrid;
  }

  void render({required Mappoint leftUpper, required int tileSize, required HgtTileRenderer tileRenderer, required Uint8List pixels}) {
    _ElevationGrid? elevationGrid = _calculateGrid(leftUpper: leftUpper, tileSize: tileSize);
    //print("elevationGrid: $elevationGrid");
    if (elevationGrid == null) {
      return;
    }

    ILatLong leftUpperLL = projection.pixelToLatLong(leftUpper.x, leftUpper.y);

    int row = 0;
    int maxY = 0;
    for (int y = 0; y < tileSize; ++y) {
      int column = 0;
      if (y > maxY) {
        ++row;
        // not enough rows available, out of boundary of the file(s), nothing to render
        if (row + 1 == elevationGrid.rows) break;
      }
      _ElevationPoint leftTop = elevationGrid.get(column, row);
      _ElevationPoint rightTop = elevationGrid.get(column + 1, row);
      _ElevationPoint leftBottom = elevationGrid.get(column, row + 1);
      _ElevationPoint rightBottom = elevationGrid.get(column + 1, row + 1);
      _ElevationArea area = _ElevationArea(leftTop: leftTop, rightTop: rightTop, leftBottom: leftBottom, rightBottom: rightBottom);
      maxY = leftBottom != const _ElevationPoint.invalid()
          ? leftBottom.y
          : rightBottom != const _ElevationPoint.invalid()
          ? rightBottom.y
          : maxY;
      for (int x = 0; x < tileSize; ++x) {
        int elevation = _interpolatedElevation(area, x, y);
        tileRenderer.render(pixels, tileSize, x, y, projection, leftUpperLL.latitude, leftUpperLL.longitude, elevation);
        if (x > rightTop.x) {
          if (column + 2 == elevationGrid.columns) break;
          ++column;
          leftTop = elevationGrid.get(column, row);
          rightTop = elevationGrid.get(column + 1, row);
          leftBottom = elevationGrid.get(column, row + 1);
          rightBottom = elevationGrid.get(column + 1, row + 1);
          area = _ElevationArea(leftTop: leftTop, rightTop: rightTop, leftBottom: leftBottom, rightBottom: rightBottom);
          maxY = leftBottom != const _ElevationPoint.invalid()
              ? leftBottom.y
              : rightBottom != const _ElevationPoint.invalid()
              ? rightBottom.y
              : maxY;
        }
      }
    }

    // for (int x = tileSize - 10; x < tileSize; ++x) {
    //   for (int y = tileSize - 10; y < tileSize; ++y) {
    //     int idx = y * tileSize + x;
    //     pixels.buffer.asUint32List()[idx] = 0xff00ff00;
    //   }
    // }
  }

  /// tileX: mappoint-pixels in x-direction starting with 0 at the left border of the tile
  int _interpolatedElevation(_ElevationArea area, int tileX, int tileY) {
    if (area.specificElevation != null) return area.specificElevation!;
    final invalidLT = area.leftTop == const _ElevationPoint.invalid();
    final invalidRT = area.rightTop == const _ElevationPoint.invalid();
    final invalidLB = area.leftBottom == const _ElevationPoint.invalid();
    final invalidRB = area.rightBottom == const _ElevationPoint.invalid();

    final invalids = (invalidLT == true ? 1 : 0) + (invalidRT == true ? 1 : 0) + (invalidLB == true ? 1 : 0) + (invalidRB == true ? 1 : 0);
    // more than 2 invalids? we cannot render anything
    if (invalids >= 2) {
      area.specificElevation = HgtFile.invalid;
      return HgtFile.invalid;
    }

    final oceanLT = area.leftTop.elevation == HgtFile.ocean;
    final oceanRT = area.rightTop.elevation == HgtFile.ocean;
    final oceanLB = area.leftBottom.elevation == HgtFile.ocean;
    final oceanRB = area.rightBottom.elevation == HgtFile.ocean;

    final oceans = (oceanLT == true ? 1 : 0) + (oceanRT == true ? 1 : 0) + (oceanLB == true ? 1 : 0) + (oceanRB == true ? 1 : 0);
    // 2 oceans, 2 normal elevations <- ocean
    // 2 oceans, 1 invalid, 1 normal <- invalid
    // 3 oceans, 1 invalid <- render
    // 3 oceans, 1 normal <- ocean
    // 4 oceans <- ocean
    if (oceans == 2 && invalids == 1) {
      area.specificElevation = HgtFile.invalid;
      return HgtFile.invalid;
    }
    if (oceans >= 2 && invalids == 0) {
      area.specificElevation = HgtFile.ocean;
      return HgtFile.ocean;
    }
    if (oceans == 4) {
      area.specificElevation = HgtFile.ocean;
      return HgtFile.ocean;
    }

    final dx = invalidRT || invalidLT ? area.rightBottom.x - area.leftBottom.x : area.rightTop.x - area.leftTop.x;
    final dy = invalidLB || invalidLT ? area.rightBottom.y - area.rightTop.y : area.leftBottom.y - area.leftTop.y;

    assert(
      dx >= 0,
      "dx: $dx, leftTop.x: ${area.leftTop.x}, rightTop.x: ${area.rightTop.x}, leftBottom.x: ${area.leftBottom.x}, rightBottom.x: ${area.rightBottom.x}",
    );
    assert(
      dy >= 0,
      "dy: $dy, leftTop.y: ${area.leftTop.y}, rightTop.y: ${area.rightTop.y}, leftBottom.y: ${area.leftBottom.y}, rightBottom.y: ${area.rightBottom.y}",
    );
    assert(tileX >= area.leftTop.x, "tileX: $tileX, tileY: $tileY, leftTop: ${area.leftTop}, rightTop: ${area.rightTop}, leftBottom: ${area.leftBottom}");
    assert(
      tileY <= area.leftBottom.y,
      "tileX: $tileX, tileY: $tileY, leftTop: ${area.leftTop}, rightTop: ${area.rightTop}, leftBottom: ${area.leftBottom}, rightBottom: ${area.rightBottom}",
    );

    final tx = dx == 0 ? 0.0 : (tileX - area.leftTop.x) / dx;
    final ty = dy == 0 ? 0.0 : (tileY - area.leftTop.y) / dy;
    assert(tx >= 0, "tx: $tx, tileX: $tileX, leftTop.x: ${area.leftTop.x}");
    assert(ty >= 0, "ty: $ty, tileY: $tileY, leftTop.y: ${area.leftTop.y}");

    final nx = tx.clamp(0.0, 1.0);
    final ny = ty.clamp(0.0, 1.0);

    if (oceanLT || invalidLT) {
      if (nx + ny <= 1.0) return HgtFile.ocean;
      final value = _interpolateTriangle(nx, ny, 1.0, 0.0, area.rightTop.elevDbl(), 0.0, 1.0, area.leftBottom.elevDbl(), 1.0, 1.0, area.rightBottom.elevDbl());
      return value.round();
    }

    if (oceanRB || invalidRB) {
      if (nx + ny >= 1.0) return HgtFile.ocean;
      final value = _interpolateTriangle(nx, ny, 0.0, 0.0, area.leftTop.elevDbl(), 1.0, 0.0, area.rightTop.elevDbl(), 0.0, 1.0, area.leftBottom.elevDbl());
      return value.round();
    }

    if (oceanRT || invalidRT) {
      if (nx >= ny) return HgtFile.ocean;
      final value = _interpolateTriangle(nx, ny, 0.0, 0.0, area.leftTop.elevDbl(), 0.0, 1.0, area.leftBottom.elevDbl(), 1.0, 1.0, area.rightBottom.elevDbl());
      return value.round();
    }

    if (oceanLB || invalidLB) {
      if (nx <= ny) return HgtFile.ocean;
      final value = _interpolateTriangle(nx, ny, 0.0, 0.0, area.leftTop.elevDbl(), 1.0, 0.0, area.rightTop.elevDbl(), 1.0, 1.0, area.rightBottom.elevDbl());
      return value.round();
    }

    final top = area.leftTop.elevation + (area.rightTop.elevation - area.leftTop.elevation) * nx;
    final bottom = area.leftBottom.elevation + (area.rightBottom.elevation - area.leftBottom.elevation) * nx;
    final value = top + (bottom - top) * ny;
    return value.round();
  }

  double _interpolateTriangle(double x, double y, double x1, double y1, double z1, double x2, double y2, double z2, double x3, double y3, double z3) {
    final denom = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3);
    if (denom == 0) return z1;
    final w1 = ((y2 - y3) * (x - x3) + (x3 - x2) * (y - y3)) / denom;
    final w2 = ((y3 - y1) * (x - x3) + (x1 - x3) * (y - y3)) / denom;
    final w3 = 1.0 - w1 - w2;
    return z1 * w1 + z2 * w2 + z3 * w3;
  }
}

//////////////////////////////////////////////////////////////////////////////

class _ElevationPoint {
  final int x;

  final int y;

  final int elevation;

  const _ElevationPoint(this.x, this.y, this.elevation);

  const _ElevationPoint.invalid() : x = -1, y = -1, elevation = -500;

  double elevDbl() => elevation.toDouble();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _ElevationPoint && runtimeType == other.runtimeType && x == other.x && y == other.y && elevation == other.elevation;

  @override
  int get hashCode => Object.hash(x, y, elevation);

  @override
  String toString() {
    return '_ElevationPoint{x: $x, y: $y, elevation: $elevation}';
  }
}

//////////////////////////////////////////////////////////////////////////////

class _ElevationGrid {
  late final List<_ElevationPoint> _points;

  final int columns;

  final int rows;

  _ElevationGrid(this.columns, this.rows) : assert(columns > 1), assert(rows > 1), _points = List.filled(columns * rows, const _ElevationPoint.invalid());

  void set(int column, int row, _ElevationPoint elevationPoint) {
    _points[row * columns + column] = elevationPoint;
  }

  _ElevationPoint get(int column, int row) {
    assert(column < columns, "column: $column, columns: $columns");
    assert(row < rows, "row: $row, rows: $rows");
    return _points[row * columns + column];
  }

  void _verify() {
    int lastY = -10000;
    for (int row = 0; row < rows; ++row) {
      int y = get(0, row).y;
      for (int column = 0; column < columns; ++column) {
        int cellY = get(column, row).y;
        if (y == -1 && cellY != -1) y = cellY;
        assert(y == -1 || cellY == -1 || cellY == y, "column: $column, row: $row, y: $y, cell-y: $cellY, columns: $columns, rows: $rows");
      }
      assert(lastY == -10000 || y > lastY, "row: $row, lastY: $lastY, y: $y");
      if (y != -1) lastY = y;
    }
    int lastX = -10000;
    for (int column = 0; column < columns; ++column) {
      int x = get(column, 0).x;
      for (int row = 0; row < rows; ++row) {
        int cellX = get(column, row).x;
        if (x == -1 && cellX != -1) x = cellX;
        assert(x == -1 || cellX == -1 || cellX == x, "column: $column, row: $row, x: $x, cell-x: $cellX, columns: $columns, rows: $rows");
      }
      assert(lastX == -10000 || x == -1 || x > lastX, "column: $column, lastX: $lastX, x: $x");
      if (x != -1) lastX = x;
    }
  }

  _ElevationGrid appendBottom(_ElevationGrid other) {
    assert(columns >= other.columns, "columns: $columns, other.columns: ${other.columns}");
    _ElevationGrid result = _ElevationGrid(columns, rows + other.rows);
    for (int row = 0; row < rows; ++row) {
      for (int column = 0; column < columns; ++column) {
        result.set(column, row, get(column, row));
      }
    }
    for (int row = 0; row < other.rows; ++row) {
      for (int column = 0; column < other.columns; ++column) {
        result.set(column, row + rows, other.get(column, row));
      }
    }
    return result;
  }

  _ElevationGrid appendRight(_ElevationGrid other) {
    assert(rows >= other.rows);
    _ElevationGrid result = _ElevationGrid(columns + other.columns, rows);
    for (int row = 0; row < rows; ++row) {
      for (int column = 0; column < columns; ++column) {
        result.set(column, row, get(column, row));
      }
    }
    for (int row = 0; row < other.rows; ++row) {
      for (int column = 0; column < other.columns; ++column) {
        result.set(column + columns, row, other.get(column, row));
      }
    }
    return result;
  }

  _ElevationGrid finalize(int tileSize) {
    _ElevationGrid result = this;

    if (columns > tileSize / 4) {
      result = _ElevationGrid((columns / 4).ceil(), rows);
      for (int row = 0; row < rows; ++row) {
        for (int column = 0; column < columns; column += 4) {
          _ElevationPoint point = get(column, row);
          result.set(column ~/ 4, row, point);
        }
        if (columns % 4 != 1) {
          // make sure we have the last column for seamless border to the next file
          _ElevationPoint point = get(columns - 1, row);
          result.set(result.columns - 1, row, point);
        }
      }
      return result.finalize(tileSize);
    }
    if (rows > tileSize / 4) {
      result = _ElevationGrid(columns, (rows / 4).ceil());
      for (int row = 0; row < rows; row += 4) {
        for (int column = 0; column < columns; ++column) {
          _ElevationPoint point = get(column, row);
          result.set(column, row ~/ 4, point);
        }
      }
      if (rows % 4 != 1) {
        for (int column = 0; column < columns; ++column) {
          _ElevationPoint point = get(column, rows - 1);
          result.set(column, result.rows - 1, point);
        }
      }
      return result.finalize(tileSize);
    }
    //result._verify();
    return result;
  }

  @override
  String toString() {
    return '_ElevationGrid{_points: $_points, columns: $columns, rows: $rows}';
  }
}

//////////////////////////////////////////////////////////////////////////////

class _ElevationArea {
  final _ElevationPoint leftTop;

  final _ElevationPoint rightTop;

  final _ElevationPoint leftBottom;

  final _ElevationPoint rightBottom;

  int? specificElevation;

  _ElevationArea({required this.leftTop, required this.rightTop, required this.leftBottom, required this.rightBottom}) {
    final allEqual = (leftTop == rightTop) && (rightTop == leftBottom) && (leftBottom == rightBottom);
    if (allEqual) {
      specificElevation = leftTop.elevation;
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class _MissingElevation {
  final int columnIdx;

  final int rowIdx;

  _MissingElevation(this.columnIdx, this.rowIdx);
}
