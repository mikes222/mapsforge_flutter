import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';

class HgtFile {
  static final _log = Logger('HgtFile');

  final int baseLat;
  final int baseLon;

  /// width of a tile in degree lon
  final int tileWidth;
  final int tileHeight;
  // number of rows of this file
  final int rows;
  final int columns;

  final Int16List _elevations;

  HgtFile._({
    required this.baseLat,
    required this.baseLon,
    required this.tileWidth,
    required this.tileHeight,
    required this.rows,
    required this.columns,
    required Int16List elevations,
  }) : _elevations = elevations;

  static Future<HgtFile> readFromFile(
    File file, {
    required int baseLat,
    required int baseLon,
    required int tileWidth,
    required int tileHeight,
    required int rows,
  }) async {
    if (!file.existsSync()) {
      _log.warning("HGT file not found: ${file.path}");
      return HgtFile._(baseLat: baseLat, baseLon: baseLon, tileWidth: tileWidth, tileHeight: tileHeight, rows: 0, columns: 0, elevations: Int16List(0));
    }

    final Uint8List bytes = await file.readAsBytes();
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

    return HgtFile._(baseLat: baseLat, baseLon: baseLon, tileWidth: tileWidth, tileHeight: tileHeight, rows: rows, columns: columns, elevations: elevations);
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
    if (latitude < baseLat || latitude > baseLat + tileHeight || longitude < baseLon || longitude > baseLon + tileWidth) {
      return null;
    }

    // HGT rows are north-to-south.
    final double u = (longitude - baseLon) / tileWidth;
    final double v = ((baseLat + tileHeight) - latitude) / tileHeight;

    final x = u * (columns - 1);
    final y = v * (rows - 1);
    assert(x >= 0 && x < columns);
    assert(y >= 0 && y < rows);

    final x0 = x.floor().clamp(0, columns - 1);
    final y0 = y.floor().clamp(0, rows - 1);
    // final x1 = min(x0 + 1, columns - 1);
    // final y1 = min(y0 + 1, rows - 1);

    final q00 = _sample(y0, x0);
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
