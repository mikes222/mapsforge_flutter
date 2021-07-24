import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/layer/job/jobrenderer.dart';
import 'package:mapsforge_flutter/src/marker/markerdatastore.dart';

import '../cache/tilebitmapcache.dart';
import 'displaymodel.dart';

class MapModel {
  final DisplayModel displayModel;
  final JobRenderer renderer;
  final List<MarkerDataStore> markerDataStores = [];
  final TileBitmapCache? tileBitmapCache;
  final TileBitmapCache tileBitmapCacheFirstLevel;

  MapModel({
    required this.displayModel,
    required this.renderer,
    this.tileBitmapCache,
    TileBitmapCache? tileBitmapCacheFirstLevel,
  }) : tileBitmapCacheFirstLevel =
            tileBitmapCacheFirstLevel ?? MemoryTileBitmapCache();

  void dispose() {
    markerDataStores.forEach((datastore) {
      datastore.dispose();
    });
    tileBitmapCache?.dispose();
    tileBitmapCacheFirstLevel.dispose();
  }
}
