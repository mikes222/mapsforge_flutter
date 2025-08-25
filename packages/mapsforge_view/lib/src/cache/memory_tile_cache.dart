import 'package:dart_common/model.dart';
import 'package:datastore_renderer/ui.dart';
import 'package:ecache/ecache.dart';
import 'package:mapsforge_view/src/cache/tile_cache.dart';

///
/// This is a memory-only implementation of the [TileBitmapCache]. It stores the bitmaps in memory.
/// We use a factory and remember all active instances. This way we can easily purge caches if needed.
///
class MemoryTileCache extends TileCache {
  static final List<MemoryTileCache> _instances = [];

  final Storage<Tile, TilePicture> storage = WeakReferenceStorage<Tile, TilePicture>();
  late LruCache<Tile, TilePicture> _cache;

  factory MemoryTileCache.create() {
    MemoryTileCache result = MemoryTileCache._();
    _instances.add(result);
    return result;
  }

  MemoryTileCache._() {
    _cache = LruCache<Tile, TilePicture>(storage: storage, capacity: 1000);
  }

  @override
  void dispose() {
    print("Statistics for MemoryTileBitmapCache: ${_cache.storage.toString()}");
    _cache.clear();
    _instances.remove(this);
  }

  static void purgeAllCaches() {
    for (MemoryTileCache cache in _instances) {
      cache.purgeAll();
    }
  }

  static void purgeCachesByBoundary(BoundingBox boundingBox) {
    for (MemoryTileCache cache in _instances) {
      cache.purgeByBoundary(boundingBox);
    }
  }

  @override
  void purgeAll() {
    _cache.clear();
  }

  @override
  void purgeByBoundary(BoundingBox boundingBox) {
    storage.keys
        .where((Tile tile) {
          if (tile.getBoundingBox().intersects(boundingBox)) {
            return true;
          }
          return false;
        })
        .forEach((tile) {
          _cache.remove(tile);
        });
  }

  @override
  Future<TilePicture?> getOrProduce(Tile tile, Future<TilePicture> Function(Tile) producer) {
    return _cache.getOrProduce(tile, producer);
  }

  @override
  TilePicture? get(Tile tile) {
    try {
      return _cache.get(tile);
    } catch (error) {
      // Exception: Cannot get a value from a producer since the value is a future and the get() method is synchronously
      // a value is still in progress, return null
      return null;
    }
  }
}
