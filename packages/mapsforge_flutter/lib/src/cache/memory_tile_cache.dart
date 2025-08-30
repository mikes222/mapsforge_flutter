import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter/src/cache/spatial_tile_index.dart';
import 'package:mapsforge_flutter/src/cache/tile_cache.dart';
import 'package:mapsforge_flutter_core/model.dart';

/// This is a memory-only implementation of the [TileCache]. It stores the bitmaps in memory.
/// We use a factory and remember all active instances. This way we can easily purge caches if needed.
class MemoryTileCache extends TileCache {
  static final List<MemoryTileCache> _instances = [];

  late final LruCache<Tile, TilePicture?> _cache;

  final SpatialTileIndex _spatialIndex = SpatialTileIndex(cellSize: 2); // 2 degree cells, 180*90 = 16200 cells

  factory MemoryTileCache.create() {
    MemoryTileCache result = MemoryTileCache._();
    _instances.add(result);
    return result;
  }

  MemoryTileCache._() {
    var storage = WeakReferenceStorage<Tile, TilePicture?>(
      onEvict: (tile, picture) {
        _spatialIndex.removeTile(tile);
        picture?.dispose();
      },
    );
    _cache = LruCache<Tile, TilePicture?>(storage: storage, capacity: 1000);
  }

  @override
  void dispose() {
    _cache.clear();
    _spatialIndex.clear();
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
    _spatialIndex.clear();
  }

  @override
  void purgeByBoundary(BoundingBox boundingBox) {
    // Ultra-fast boundary-based purging using spatial index
    // This provides O(log n) performance instead of O(n) iteration
    final Set<Tile> tilesToRemove = _spatialIndex.getTilesInBoundary(boundingBox);

    // Batch removal to minimize cache operations
    for (final Tile tile in tilesToRemove) {
      _cache.remove(tile);
      _spatialIndex.removeTile(tile);
    }
  }

  @override
  Future<TilePicture?> getOrProduce(Tile tile, Future<TilePicture?> Function(Tile) producer) async {
    final TilePicture? result = await _cache.getOrProduce(tile, producer);

    if (result != null) {
      _spatialIndex.addTile(tile);
    }
    return result;
  }

  @override
  TilePicture? get(Tile tile) {
    try {
      return _cache.get(tile);
    } catch (error) {
      // Exception: Cannot get a value from a producer since the value is a future and the get() method is synchronously
      // a the procuder is still in progress, return null
      return null;
    }
  }
}
