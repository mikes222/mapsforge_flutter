import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

///
/// This is a memory-only implementation of the [TileBitmapCache]. It stores the bitmaps in memory.
/// We use a factory and remember all active instances. This way we can easily purge caches if needed.
///
class MemoryLabelCache {
  static final List<MemoryLabelCache> _instances = [];

  late LruCache<Tile, RenderInfoCollection> _cache;

  factory MemoryLabelCache.create() {
    MemoryLabelCache result = MemoryLabelCache._();
    _instances.add(result);
    return result;
  }

  static void purgeAllCaches() {
    for (MemoryLabelCache cache in _instances) {
      cache.purgeAll();
    }
  }

  static void purgeCachesByBoundary(BoundingBox boundingBox) {
    for (MemoryLabelCache cache in _instances) {
      cache.purgeByBoundary(boundingBox);
    }
  }

  MemoryLabelCache._() {
    _cache = LruCache<Tile, RenderInfoCollection>(capacity: 500);
  }

  void dispose() {
    print("Statistics for MemoryLabelCache: ${_cache.storage.toString()}");
    _cache.clear();
    _instances.remove(this);
  }

  void purgeAll() {
    _cache.clear();
  }

  void purgeByBoundary(BoundingBox boundingBox) {
    _cache.clear();
    // _cache.storage.keys
    //     .where((RenderInfoCollection tile) {
    //       if (tile.getBoundingBox().intersects(boundingBox)) {
    //         return true;
    //       }
    //       return false;
    //     })
    //     .forEach((tile) {
    //       _cache.remove(tile);
    //     });
  }

  Future<RenderInfoCollection> getOrProduce(Tile leftUpper, Tile rightLower, Future<RenderInfoCollection> Function(Tile) producer) {
    return _cache.getOrProduce(leftUpper, producer);
  }

  RenderInfoCollection? get(Tile tile) {
    try {
      return _cache.get(tile);
    } catch (error) {
      // Exception: Cannot get a value from a producer since the value is a future and the get() method is synchronously
      // a value is still in progress, return null
      return null;
    }
  }
}
