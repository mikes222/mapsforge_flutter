import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';

class HgtFile {
  static final _log = Logger('HgtFile');

  static const int ocean = -500;

  static const int invalid = -32767;

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

  final Map<int, HgtRastering> _zoomRasterings = {};

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

  HgtRastering? raster(PixelProjection projection) {
    if (rows == 0) {
      return null;
    }
    HgtRastering? hgtRastering = _zoomRasterings[projection.scalefactor.zoomlevel];
    if (hgtRastering != null) return hgtRastering;

    MapRectangle rectangle = MapRectangle(
      projection.longitudeToPixelX(baseLon.toDouble()),
      projection.latitudeToPixelY((baseLat + latHeight).toDouble()),
      projection.longitudeToPixelX((baseLon + lonWidth).toDouble()),
      projection.latitudeToPixelY(baseLat.toDouble()),
    );
    List<double> yPositions = [];
    List<double> xPositions = [];
    int factor = 1;
    if (projection.scalefactor.zoomlevel <= 8) {
      factor = 2;
    }
    if (projection.scalefactor.zoomlevel <= 6) {
      factor = 4;
    }
    if (projection.scalefactor.zoomlevel <= 4) {
      factor = 8;
    }
    double latStep = latHeight / (rows - 1) * factor;
    for (double lat = (baseLat + latHeight).toDouble(); lat >= (baseLat).toDouble(); lat -= latStep) {
      double yPosition = projection.latitudeToPixelY(lat);
      yPositions.add(yPosition);
    }
    assert(yPositions.length * factor == rows, "yPositions.length: ${yPositions.length}, hgtFile.rows: $rows");

    double lonStep = rectangle.getWidth() / (columns - 1) * factor;
    for (double x = rectangle.left; x <= rectangle.right; x += lonStep) {
      xPositions.add(x);
    }
    // possible precision error may prevent the last column
    if (xPositions.length * factor < columns) xPositions.add(rectangle.right);
    assert(
      xPositions.length * factor == columns,
      "xPositions.length: ${xPositions.length}, _hgtFile.columns: ${columns} ${rectangle.right} ${xPositions.last} $lonStep",
    );
    hgtRastering = HgtRastering(yPositions, xPositions, _elevations, columns, factor);
    _zoomRasterings[projection.scalefactor.zoomlevel] = hgtRastering;
    return hgtRastering;
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
    double x = u * (columns - 1);
    double y = v * (rows - 1);

    assert(x >= 0 && x < columns, 'x: $x, columns: $columns');
    assert(y >= 0 && y < rows, 'y: $y, rows: $rows');

    final q00 = elevation(x.round(), y.round());
    return q00;
  }

  int elevation(int col, int row) {
    return _elevations[row * columns + col];
  }

  @override
  String toString() {
    return 'HgtFile{baseLat: $baseLat, baseLon: $baseLon, lonWidth: $lonWidth, latHeight: $latHeight, rows: $rows, columns: $columns}';
  }
}

//////////////////////////////////////////////////////////////////////////////

class HgtRastering {
  final List<double> yPositions;

  final List<double> xPositions;

  final Int16List elevations;

  final int columns;

  final int factor;

  HgtRastering(this.yPositions, this.xPositions, this.elevations, this.columns, this.factor);

  int elevation(int col, int row) {
    return elevations[row * columns * factor + col * factor];
  }
}
