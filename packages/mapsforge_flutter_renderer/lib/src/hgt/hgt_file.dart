import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';

class HgtFile {
  static final _log = Logger('HgtFile');

  // minimum lat/lon of this file
  final int baseLat;
  final int baseLon;

  /// width of this file in degree lon
  final int lonWidth;
  final int latHeight;

  // number of data rows of this file
  final int rows;
  final int columns;

  /// elevation data in int16 (meters)
  final Int16List _elevations;

  HgtFile._({
    required this.baseLat,
    required this.baseLon,
    required this.lonWidth,
    required this.latHeight,
    required this.rows,
    required this.columns,
    required Int16List elevations,
  }) : assert(lonWidth > 0),
       assert(latHeight > 0),
       assert(rows > 0),
       assert(columns > 0),
       _elevations = elevations;

  HgtFile._noFile({required this.baseLat, required this.baseLon, required this.lonWidth, required this.latHeight})
    : assert(lonWidth > 0),
      assert(latHeight > 0),
      _elevations = Int16List(0),
      rows = 0,
      columns = 0;

  static HgtFile readFromFile(File file, {required int baseLat, required int baseLon, required int tileWidth, required int tileHeight, required int rows}) {
    if (!file.existsSync()) {
      _log.warning("HGT file not found: ${file.path}");
      return HgtFile._noFile(baseLat: baseLat, baseLon: baseLon, lonWidth: tileWidth, latHeight: tileHeight);
    }

    final Uint8List bytes = file.readAsBytesSync();
    if (bytes.lengthInBytes % 2 != 0) {
      throw StateError('Invalid .hgt length: ${bytes.lengthInBytes}');
    }

    int columns = bytes.lengthInBytes ~/ 2 ~/ rows;

    // HGT stores signed 16-bit big-endian.
    final ByteData bd = ByteData.sublistView(bytes);
    final elevations = Int16List(rows * columns);
    for (int i = 0; i < rows * columns; i++) {
      elevations[i] = bd.getInt16(i * 2, Endian.little);
    }

    return HgtFile._(baseLat: baseLat, baseLon: baseLon, lonWidth: tileWidth, latHeight: tileHeight, rows: rows, columns: columns, elevations: elevations);
  }

  int? elevationAtTileXY(ILatLong leftUpper, ILatLong rightLower, int tileX, int tileY, int tileSize) {
    if (rows == 0) {
      // file not found
      return null;
    }

    // HGT rows are north-to-south.
    // fractions of lat/lon coordinates of the tile-boundary inbetween the current file-boundary
    final leftFraction = (leftUpper.longitude - baseLon) / lonWidth;
    final rightFraction = (rightLower.longitude - baseLon) / lonWidth;
    final topFraction = ((baseLat + latHeight) - leftUpper.latitude) / latHeight;
    final bottomFraction = ((baseLat + latHeight) - rightLower.latitude) / latHeight;

    // The fraction of the tile-boundary relative to the file-boundary
    final widthFraction = (rightFraction - leftFraction);
    final heightFraction = (bottomFraction - topFraction);

    double columnIdx = (leftFraction + widthFraction * tileX / tileSize) * columns;
    double rowIdx = (topFraction + heightFraction * tileY / tileSize) * rows;

    assert(columnIdx >= 0);
    assert(rowIdx >= 0);
    if (columnIdx == columns) columnIdx = columns - 1;
    if (rowIdx == rows) rowIdx = rows - 1;

    // if (tileX == 0 && tileY == 0) {
    //   _log.info(
    //     "All parameters: leftFraction: $leftFraction, rightFraction: $rightFraction, topFraction: $topFraction, bottomFraction: $bottomFraction, x: $columnIdx, y: $rowIdx",
    //   );
    // }

    return _sample(rowIdx.floor(), columnIdx.floor());
  }

  ElevationArea? elevationAround(ILatLong leftUpperLL, ILatLong rightLowerLL, Mappoint leftUpper, int tileX, int tileY, int tileSize) {
    if (rows == 0) {
      // file not found
      return null;
    }
    // HGT rows are north-to-south.
    // fractions of lat/lon coordinates of the tile-boundary inbetween the current file-boundary
    final leftFraction = (leftUpperLL.longitude - baseLon) / lonWidth;
    final rightFraction = (rightLowerLL.longitude - baseLon) / lonWidth;
    final topFraction = ((baseLat + latHeight) - leftUpperLL.latitude) / latHeight;
    final bottomFraction = ((baseLat + latHeight) - rightLowerLL.latitude) / latHeight;

    // The fraction of the tile-boundary relative to the file-boundary
    final widthFraction = (rightFraction - leftFraction);
    final heightFraction = (bottomFraction - topFraction);

    // The index of the elevation
    double columnIdx = (leftFraction + widthFraction * tileX / tileSize) * columns;
    double rowIdx = (topFraction + heightFraction * tileY / tileSize) * rows;

    assert(columnIdx >= 0);
    assert(rowIdx >= 0);
    if (columnIdx >= columns) columnIdx = columns - 1;
    if (rowIdx >= rows) rowIdx = rows - 1;

    /// the indices into the elevation data around the given coordinate
    final columnIdxFloor = columnIdx.floor();
    final columnIdxCeil = columnIdx.ceil();
    final rowIdxFloor = rowIdx.floor();
    final rowIdxCeil = rowIdx.ceil();

    assert(columnIdxFloor <= columnIdxCeil, "columnIdxFloor: $columnIdxFloor, columnIdxCeil: $columnIdxCeil");
    assert(rowIdxFloor <= rowIdxCeil, "rowIdxFloor: $rowIdxFloor, rowIdxCeil: $rowIdxCeil");

    assert(columnIdxFloor >= 0, "columnIdxFloor: $columnIdxFloor");
    assert(columnIdxCeil >= 0, "columnIdxCeil: $columnIdxCeil");
    assert(rowIdxFloor >= 0, "rowIdxFloor: $rowIdxFloor");
    assert(rowIdxCeil >= 0, "rowIdxCeil: $rowIdxCeil");
    assert(columnIdxFloor < columns, "columnIdxFloor: $columnIdxFloor, columns: $columns");
    assert(columnIdxCeil < columns, "columnIdxCeil: $columnIdxCeil, columns: $columns");
    assert(rowIdxFloor < rows, "rowIdxFloor: $rowIdxFloor, rows: $rows");
    assert(rowIdxCeil < rows, "rowIdxCeil: $rowIdxCeil, rows: $rows");

    int tileXFloor = ((columnIdxFloor / columns - leftFraction) * tileSize / widthFraction).round();
    int tileXCeil = ((columnIdxCeil / columns - leftFraction) * tileSize / widthFraction).round();
    int tileYFloor = ((rowIdxFloor / rows - topFraction) * tileSize / heightFraction).round();
    int tileYCeil = ((rowIdxCeil / rows - topFraction) * tileSize / heightFraction).round();
    // tileXFloor = max(tileXFloor, 0);
    // tileXCeil = min(tileXCeil, tileSize - 1);
    // tileXCeil = max(tileXCeil, 0);
    // tileYFloor = max(tileYFloor, 0);
    // tileYCeil = min(tileYCeil, tileSize - 1);
    // tileYCeil = max(tileYCeil, 0);

    assert(tileXFloor <= tileXCeil, "tileXFloor: $tileXFloor, tileXCeil: $tileXCeil, columnIdxFloor: $columnIdxFloor, columnIdxCeil: $columnIdxCeil");
    assert(tileYFloor <= tileYCeil, "tileYFloor: $tileYFloor, tileYCeil: $tileYCeil, rowIdxFloor: $rowIdxFloor, rowIdxCeil: $rowIdxCeil");

    // assert(tileXCeil >= 0, "tileXCeil: $tileXCeil");
    // assert(tileYCeil >= 0, "tileYCeil: $tileYCeil");

    // assert(tileXFloor < tileSize, "tileXFloor: $tileXFloor");
    // assert(tileXCeil < tileSize, "tileXCeil: $tileXCeil");
    // assert(tileYFloor < tileSize, "tileYFloor: $tileYFloor");
    // assert(tileYCeil < tileSize, "tileYCeil: $tileYCeil");

    return ElevationArea(
      _sample(rowIdxFloor, columnIdxFloor),
      _sample(rowIdxFloor, columnIdxCeil),
      _sample(rowIdxCeil, columnIdxFloor),
      _sample(rowIdxCeil, columnIdxCeil),
      tileXFloor,
      tileXCeil,
      tileYFloor,
      tileYCeil,
    );
  }

  /// Returns the elevation in meters for the given lat/lon.
  ///
  /// The coordinates must lie within [baseLat..baseLat+width] and [baseLon..baseLon+width].
  ///
  /// Uses bilinear interpolation between surrounding samples.
  int? elevationAt(double latitude, double longitude) {
    if (rows == 0) {
      // file not found
      return null;
    }
    if (latitude < baseLat || latitude > baseLat + latHeight || longitude < baseLon || longitude > baseLon + lonWidth) {
      return null;
    }

    // HGT rows are north-to-south.
    // u, v are fractions of lat/lon coordinates inbetween the current file-boundaries
    final double u = (longitude - baseLon) / lonWidth;
    final double v = ((baseLat + latHeight) - latitude) / latHeight;

    // x,y are indices into the elevation data in double digits
    double x = u * columns;
    if (x == columns) x = columns - 1;
    double y = v * rows;
    if (y == rows) y = rows - 1;

    assert(x >= 0 && x < columns, 'x: $x, columns: $columns');
    assert(y >= 0 && y < rows, 'y: $y, rows: $rows');

    final q00 = _sample(y.floor(), x.floor());
    return q00;
    // final q10 = _sample(y0, x1);
    // final q01 = _sample(y1, x0);
    // final q11 = _sample(y1, x1);

    // final fx = x - x0;
    // final fy = y - y0;
    //
    // final a = q00 + (q10 - q00) * fx;
    // final b = q01 + (q11 - q01) * fx;
    // final value = a + (b - a) * fy;
    //
    // final result = value.round();
    // if (result == -32768) return null;
    // return result;
  }

  int _sample(int row, int col) {
    return _elevations[row * columns + col];
  }
}

class ElevationArea {
  final int leftTop;

  final int rightTop;

  final int leftBottom;

  final int rightBottom;

  final int minTileX;

  final int maxTileX;

  final int minTileY;

  final int maxTileY;

  ElevationArea(this.leftTop, this.rightTop, this.leftBottom, this.rightBottom, this.minTileX, this.maxTileX, this.minTileY, this.maxTileY)
    : assert(minTileX <= maxTileX),
      assert(minTileY <= maxTileY);
}
