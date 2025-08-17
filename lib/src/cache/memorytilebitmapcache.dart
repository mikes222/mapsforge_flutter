import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/tilepicture.dart';

///
/// This is a memory-only implementation of the [TileBitmapCache]. It stores the bitmaps in memory.
/// We use a factory and remember all active instances. This way we can easily purge caches if needed.
///
class MemoryTileBitmapCache extends TileBitmapCache {
  static final List<MemoryTileBitmapCache> _instances = [];

  final Storage<Tile, TilePicture> storage =
      WeakReferenceStorage<Tile, TilePicture>();
  late LruCache<Tile, TilePicture> _cache;

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
    _cache = new LruCache<Tile, TilePicture>(
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
  TilePicture? getTileBitmapSync(Tile tile) {
    return _cache.get(tile);
  }

  @override
  Future<TilePicture?> getTileBitmapAsync(Tile tile) async {
    return _cache.get(tile);
  }

  @override
  void addTileBitmap(Tile tile, TilePicture tileBitmap) {
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
      if (tile.getBoundingBox().intersects(boundingBox)) {
        return true;
      }
      return false;
    }).forEach((tile) {
      _cache.remove(tile);
    });
  }
}
