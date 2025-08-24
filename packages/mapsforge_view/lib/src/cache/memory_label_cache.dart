import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:ecache/ecache.dart';

///
/// This is a memory-only implementation of the [TileBitmapCache]. It stores the bitmaps in memory.
/// We use a factory and remember all active instances. This way we can easily purge caches if needed.
///
class MemoryLabelCache {
  static final List<MemoryLabelCache> _instances = [];

  late LruCache<String, RenderInfoCollection> _cache;

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
    _cache = LruCache<String, RenderInfoCollection>(capacity: 100);
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

  Future<RenderInfoCollection?> getOrProduce(Tile leftUpper, Tile rightLower, Future<RenderInfoCollection> Function(String) producer) {
    String key = "${leftUpper}_$rightLower";
    return _cache.getOrProduce(key, producer);
  }
}
