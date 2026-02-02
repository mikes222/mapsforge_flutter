import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';

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

    final q00 = elevation(x.floor(), y.floor());
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

  int elevation(int col, int row) {
    return _elevations[row * columns + col];
  }

  @override
  String toString() {
    return 'HgtFile{baseLat: $baseLat, baseLon: $baseLon, lonWidth: $lonWidth, latHeight: $latHeight, rows: $rows, columns: $columns}';
  }
}
