import 'dart:collection';
import 'dart:io';

import 'package:mapsforge_flutter_renderer/src/hgt/hgt_file.dart';

abstract class IHgtFileProvider {
  Future<HgtFile?> getForLatLon(double latitude, double longitude);
}

class HgtFileProvider implements IHgtFileProvider {
  final String directoryPath;
  final int maxEntries;

  final LinkedHashMap<String, HgtFile> _cache = LinkedHashMap<String, HgtFile>();

  HgtFileProvider({required this.directoryPath, this.maxEntries = 8}) : assert(!directoryPath.endsWith("/"));

  String buildFilename({required int baseLat, required int baseLon}) {
    final latPrefix = baseLat >= 0 ? 'N' : 'S';
    final lonPrefix = baseLon >= 0 ? 'E' : 'W';
    final latAbs = baseLat.abs().toString().padLeft(2, '0');
    final lonAbs = baseLon.abs().toString().padLeft(3, '0');
    return '$latPrefix$latAbs$lonPrefix$lonAbs.hgt';
  }

  @override
  Future<HgtFile?> getForLatLon(double latitude, double longitude) async {
    int step = 2;
    final baseLat = (latitude / step).floor() * step;
    final baseLon = (longitude / step).floor() * step;
    final filename = buildFilename(baseLat: baseLat, baseLon: baseLon);

    final cached = _cache[filename];
    if (cached != null) {
      return cached;
    }

    final file = File('$directoryPath${Platform.pathSeparator}$filename');

    final hgt = await HgtFile.readFromFile(file, baseLat: baseLat, baseLon: baseLon, tileWidth: step, tileHeight: step, rows: 120 * step);
    _cache[filename] = hgt;

    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }

    return hgt;
  }
}
