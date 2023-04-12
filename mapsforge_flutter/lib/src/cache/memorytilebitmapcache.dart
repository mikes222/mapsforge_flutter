import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';

///
/// This is a memory-only implementation of the [TileBitmapCache]. It stores the bitmaps in memory.
/// We use a factory and remember all active instances. This way we can easily purge caches if needed.
///
class MemoryTileBitmapCache extends TileBitmapCache {
  static final List<MemoryTileBitmapCache> _instances = [];

  final Storage<Tile, TileBitmap> storage =
      StatisticsStorage<Tile, TileBitmap>(onEvict: (key, item) {
    //item.decrementRefCount();
  });
  late LruCache<Tile, TileBitmap> _cache;

  factory MemoryTileBitmapCache.create() {
    MemoryTileBitmapCache result = MemoryTileBitmapCache._();
    _instances.add(result);
    return result;
  }

  static void purgeAllCaches() {
    for (MemoryTileBitmapCache cache in _instances) {
      cache.purgeAll();
    }
  }

  static void purgeCachesByBoundary(BoundingBox boundingBox) {
    for (MemoryTileBitmapCache cache in _instances) {
      cache.purgeByBoundary(boundingBox);
    }
  }

  MemoryTileBitmapCache._() {
    _cache = new LruCache<Tile, TileBitmap>(
      storage: storage,
      capacity: 100,
    );
  }

  @override
  void dispose() {
    print("Statistics for MemoryTileBitmapCache: ${_cache.storage.toString()}");
    _cache.clear();
    _instances.remove(this);
  }

  @override
  TileBitmap? getTileBitmapSync(Tile tile) {
    return _cache.get(tile);
  }

  @override
  Future<TileBitmap?> getTileBitmapAsync(Tile tile) async {
    return _cache.get(tile);
  }

  @override
  void addTileBitmap(Tile tile, TileBitmap tileBitmap) {
    //tileBitmap.incrementRefCount();
    // TileBitmap bitmap = _bitmaps.get(tile);
    // if (bitmap != null) {
    //   bitmap.decrementRefCount();
    // }
    _cache[tile] = tileBitmap;
  }

  @override
  void purgeAll() {
    _cache.clear();
  }

  @override
  void purgeByBoundary(BoundingBox boundingBox) {
    storage.keys.where((Tile tile) {
      Projection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
      if (tile.getBoundingBox(projection).intersects(boundingBox)) {
        return true;
      }
      return false;
    }).forEach((tile) {
      _cache.remove(tile);
    });
  }
}
