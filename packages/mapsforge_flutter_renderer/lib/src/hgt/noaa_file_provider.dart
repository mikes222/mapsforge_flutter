import 'dart:collection';
import 'dart:io';

import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/src/hgt/hgt_file.dart';
import 'package:mapsforge_flutter_renderer/src/hgt/noaa_file_definition.dart';

class NoaaFileProvider implements IHgtFileProvider {
  final String directoryPath;

  final LinkedHashMap<String, HgtFile> _cache = LinkedHashMap<String, HgtFile>();

  NoaaFileProvider({required this.directoryPath}) : assert(!directoryPath.endsWith("/"));

  @override
  HgtFile getForLatLon(double latitude, double longitude) {
    final NoaaFileDefinition noaaFileDefinition = NoaaFileDefinition.sourceTileFor(latitude, longitude);

    final cached = _cache[noaaFileDefinition.fileName];
    if (cached != null) {
      return cached;
    }

    final file = File('$directoryPath${Platform.pathSeparator}${noaaFileDefinition.fileName}');

    final hgt = HgtFile.readFromFile(
      file,
      baseLat: noaaFileDefinition.latMin.round(),
      baseLon: noaaFileDefinition.lonMin.round(),
      tileWidth: noaaFileDefinition.width.round(),
      tileHeight: noaaFileDefinition.height.round(),
      rows: noaaFileDefinition.rows,
    );
    _cache[noaaFileDefinition.fileName] = hgt;

    while (_cache.length > 4) {
      _cache.remove(_cache.keys.first);
    }

    return hgt;
  }
}
