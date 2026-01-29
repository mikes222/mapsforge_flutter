import 'dart:collection';
import 'dart:io';

import 'package:mapsforge_flutter_renderer/src/hgt/hgt_file.dart';

abstract class IHgtFileProvider {
  HgtFile getForLatLon(double latitude, double longitude);
}

class HgtFileProvider implements IHgtFileProvider {
  final String directoryPath;

  final int maxEntries;

  // elevation data columns per degree longitude
  final int columnsPerDegree;

  // degree per file in horizontal/vertical direction
  final int step;

  final LinkedHashMap<String, HgtFile> _cache = LinkedHashMap<String, HgtFile>();

  HgtFileProvider({required this.directoryPath, this.maxEntries = 8, this.columnsPerDegree = 120, this.step = 2}) : assert(!directoryPath.endsWith("/"));

  String buildFilename({required int baseLat, required int baseLon}) {
    final latPrefix = baseLat >= 0 ? 'N' : 'S';
    final lonPrefix = baseLon >= 0 ? 'E' : 'W';
    final latAbs = baseLat.abs().toString().padLeft(2, '0');
    final lonAbs = baseLon.abs().toString().padLeft(3, '0');
    return '$latPrefix$latAbs$lonPrefix$lonAbs.hgt';
  }

  @override
  HgtFile getForLatLon(double latitude, double longitude) {
    final baseLat = (latitude / step).floor() * step;
    final baseLon = (longitude / step).floor() * step;
    final filename = buildFilename(baseLat: baseLat, baseLon: baseLon);

    final cached = _cache[filename];
    if (cached != null) {
      return cached;
    }

    final file = File('$directoryPath${Platform.pathSeparator}$filename');

    final hgt = HgtFile.readFromFile(file, baseLat: baseLat, baseLon: baseLon, tileWidth: step, tileHeight: step, rows: columnsPerDegree * step);
    _cache[filename] = hgt;

    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }

    return hgt;
  }
}
