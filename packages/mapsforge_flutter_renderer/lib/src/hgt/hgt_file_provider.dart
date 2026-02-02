import 'dart:collection';
import 'dart:io';

import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/src/hgt/hgt_file.dart';
import 'package:mapsforge_flutter_renderer/src/hgt/hgt_info.dart';

class HgtFileProvider implements IHgtFileProvider {
  final String directoryPath;

  final int maxEntries;

  // elevation data columns per degree longitude
  final int columnsPerDegree;

  // degree per file in horizontal/vertical direction
  final int step;

  final LinkedHashMap<String, HgtFile> _cache = LinkedHashMap<String, HgtFile>();

  HgtFileProvider({required this.directoryPath, this.maxEntries = 256, this.columnsPerDegree = 120, this.step = 2}) : assert(!directoryPath.endsWith("/"));

  String buildFilename({required int baseLat, required int baseLon}) {
    final latPrefix = baseLat >= 0 ? 'N' : 'S';
    final lonPrefix = baseLon >= 0 ? 'E' : 'W';
    final latAbs = baseLat.abs().toString().padLeft(2, '0');
    final lonAbs = baseLon.abs().toString().padLeft(3, '0');
    return '$latPrefix$latAbs$lonPrefix$lonAbs.hgt';
  }

  @override
  HgtInfo getForLatLon(double latitude, double longitude, PixelProjection projection) {
    final baseLat = (latitude / step).floor() * step;
    final baseLon = (longitude / step).floor() * step;
    final filename = buildFilename(baseLat: baseLat, baseLon: baseLon);

    final cached = _cache[filename];
    if (cached != null) {
      return HgtInfo(hgtFile: cached, projection: projection);
    }

    final file = File('$directoryPath${Platform.pathSeparator}$filename');

    final hgt = HgtFile.readFromFile(file, baseLat: baseLat, baseLon: baseLon, tileWidth: step, tileHeight: step, rows: columnsPerDegree * step);
    _cache[filename] = hgt;

    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }

    return HgtInfo(hgtFile: hgt, projection: projection);
  }

  @override
  ElevationArea? elevationAround(HgtInfo hgtInfo, Mappoint leftUpper, int x, int y) {
    if (!hgtInfo.isInside(leftUpper.x + x, leftUpper.y + y)) {
      HgtInfo newHgtInfo = getForLatLon(
        hgtInfo.projection.pixelYToLatitude(leftUpper.y + y),
        hgtInfo.projection.pixelXToLongitude(leftUpper.x + x),
        hgtInfo.projection,
      );
      hgtInfo.takeOver(newHgtInfo);
    }
    if (hgtInfo.hgtFile.rows == 0) {
      // file not found
      return null;
    }
    // fractions of x/y coordinates inbetween the current file-boundary 0..1
    final leftFraction = (leftUpper.x + x - hgtInfo.rectangle.left) / hgtInfo.rectangle.getWidth();
    final topFraction = (leftUpper.y + y - hgtInfo.rectangle.top) / hgtInfo.rectangle.getHeight();

    // The index of the elevation in the hgtFile
    double columnIdx = leftFraction * hgtInfo.hgtFile.columns;
    double rowIdx = topFraction * hgtInfo.hgtFile.rows;

    /// the indices into the elevation data around the given coordinate
    final columnIdxFloor = columnIdx.floor();
    int columnIdxCeil = columnIdx.ceil();
    final rowIdxFloor = rowIdx.floor();
    int rowIdxCeil = rowIdx.ceil();

    // the mappixels
    int tileXFloor = (columnIdxFloor / hgtInfo.hgtFile.columns * hgtInfo.rectangle.getWidth() + hgtInfo.rectangle.left).floor();
    int tileXCeil = (columnIdxCeil / hgtInfo.hgtFile.columns * hgtInfo.rectangle.getWidth() + hgtInfo.rectangle.left).ceil();
    int tileYFloor = (rowIdxFloor / hgtInfo.hgtFile.rows * hgtInfo.rectangle.getHeight() + hgtInfo.rectangle.top).floor();
    int tileYCeil = (rowIdxCeil / hgtInfo.hgtFile.rows * hgtInfo.rectangle.getHeight() + hgtInfo.rectangle.top).ceil();

    return ElevationArea(
      _elevation(hgtInfo, leftUpper, columnIdxFloor, rowIdxFloor),
      _elevation(hgtInfo, leftUpper, columnIdxCeil, rowIdxFloor),
      _elevation(hgtInfo, leftUpper, columnIdxFloor, rowIdxCeil),
      _elevation(hgtInfo, leftUpper, columnIdxCeil, rowIdxCeil),
      (tileXFloor - leftUpper.x).floor(),
      (tileXCeil - leftUpper.x).ceil(),
      (tileYFloor - leftUpper.y).floor(),
      (tileYCeil - leftUpper.y).ceil(),
    );
  }

  int _elevation(HgtInfo hgtInfo, Mappoint leftUpper, col, int row) {
    if (col >= hgtInfo.hgtFile.columns || row >= hgtInfo.hgtFile.rows) {
      double x = (col / hgtInfo.hgtFile.columns * hgtInfo.rectangle.getWidth() + hgtInfo.rectangle.left);
      double y = (row / hgtInfo.hgtFile.rows * hgtInfo.rectangle.getHeight() + hgtInfo.rectangle.top);
      HgtInfo newHgtInfo = getForLatLon(hgtInfo.projection.pixelYToLatitude(y), hgtInfo.projection.pixelXToLongitude(x), hgtInfo.projection);
      if (col >= hgtInfo.hgtFile.columns) col -= hgtInfo.hgtFile.columns;
      if (row >= hgtInfo.hgtFile.rows) row -= hgtInfo.hgtFile.rows;
      if (col < 0) col += hgtInfo.hgtFile.columns;
      if (row < 0) row += hgtInfo.hgtFile.rows;

      if (newHgtInfo.hgtFile.rows == 0) {
        // the new file is empty, what should we provide?
        return -500;
      }
      return newHgtInfo.hgtFile.elevation(col, row);
    }
    return hgtInfo.hgtFile.elevation(col, row);
  }
}
