import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/renderer/jobrenderer.dart';

class MapModel {
  final DisplayModel displayModel;
  final JobRenderer renderer;
  final List<IMarkerDataStore> markerDataStores = [];
  final TileBitmapCache? tileBitmapCache;
  final TileBitmapCache tileBitmapCacheFirstLevel;
  final SymbolCache? symbolCache;

  MapModel({
    required this.displayModel,
    required this.renderer,
    this.tileBitmapCache,
    this.symbolCache,
    TileBitmapCache? tileBitmapCacheFirstLevel,
  }) : tileBitmapCacheFirstLevel =
            tileBitmapCacheFirstLevel ?? MemoryTileBitmapCache.create();

  void dispose() {
    renderer.dispose();
    markerDataStores.forEach((datastore) {
      datastore.dispose();
    });
    markerDataStores.clear();
    tileBitmapCache?.dispose();
    tileBitmapCacheFirstLevel.dispose();
    symbolCache?.dispose();
  }

  /// Purges all caches assigned to this MapModel. Use this if you changed the datastore which is backed by the renderer.
  /// If the datastore is used by other mapmodels too consider using the static purge() methods
  /// from FileTileBitmapCache and MemoryTileBitmapCache instead.
  void purgeCacheAll() {
    tileBitmapCache?.purgeAll();
    tileBitmapCacheFirstLevel.purgeAll();
  }

  void purgeCacheBoundary(BoundingBox boundingBox) {
    tileBitmapCache?.purgeByBoundary(boundingBox);
    tileBitmapCacheFirstLevel.purgeByBoundary(boundingBox);
  }
}
