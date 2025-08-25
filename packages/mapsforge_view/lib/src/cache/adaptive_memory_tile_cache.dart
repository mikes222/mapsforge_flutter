import 'package:dart_common/model.dart';
import 'package:datastore_renderer/ui.dart';
import 'package:ecache/ecache.dart';
import 'package:mapsforge_view/src/cache/memory_pressure_monitor.dart';
import 'package:mapsforge_view/src/cache/spatial_tile_index.dart';
import 'package:mapsforge_view/src/cache/tile_cache.dart';

/// An adaptive tile cache that automatically adjusts its size based on memory pressure
class AdaptiveMemoryTileCache extends TileCache {
  static final List<AdaptiveMemoryTileCache> _instances = [];

  late final Storage<Tile, TilePicture> storage;
  late LruCache<Tile, TilePicture> _cache;
  final MemoryPressureMonitor _memoryMonitor;
  final SpatialTileIndex _spatialIndex = SpatialTileIndex(cellSize: 0.1);

  int _currentCapacity;
  final int _initialCapacity;
  final int _minCapacity;
  final int _maxCapacity;

  // Performance tracking
  int _capacityAdjustments = 0;
  int _memoryPressureEvents = 0;
  DateTime? _lastCapacityChange;

  factory AdaptiveMemoryTileCache.create({int initialCapacity = 1000, int minCapacity = 100, int maxCapacity = 2000, MemoryPressureMonitor? memoryMonitor}) {
    final monitor = memoryMonitor ?? MemoryPressureMonitor();
    final AdaptiveMemoryTileCache result = AdaptiveMemoryTileCache._(
      initialCapacity: initialCapacity,
      minCapacity: minCapacity,
      maxCapacity: maxCapacity,
      memoryMonitor: monitor,
    );
    _instances.add(result);
    return result;
  }

  AdaptiveMemoryTileCache._({required int initialCapacity, required int minCapacity, required int maxCapacity, required MemoryPressureMonitor memoryMonitor})
    : _initialCapacity = initialCapacity,
      _minCapacity = minCapacity,
      _maxCapacity = maxCapacity,
      _currentCapacity = initialCapacity,
      _memoryMonitor = memoryMonitor {
    storage = WeakReferenceStorage<Tile, TilePicture>(
      onEvict: (tile, picture) {
        _spatialIndex.removeTile(tile);
      },
    );
    _cache = LruCache<Tile, TilePicture>(storage: storage, capacity: _currentCapacity);

    // Set up memory pressure monitoring
    _memoryMonitor.setCacheSizeLimits(minSize: _minCapacity, maxSize: _maxCapacity);
    _memoryMonitor.addPressureCallback(_onMemoryPressureChange);
    _memoryMonitor.startMonitoring();
  }

  @override
  void dispose() {
    _memoryMonitor.removePressureCallback(_onMemoryPressureChange);
    _memoryMonitor.dispose();
    _cache.clear();
    _spatialIndex.clear();
    _instances.remove(this);
  }

  /// Handles memory pressure level changes
  void _onMemoryPressureChange(MemoryPressureLevel level) {
    _memoryPressureEvents++;
    final int newCapacity = _calculateOptimalCapacity(level);

    if (newCapacity != _currentCapacity) {
      _adjustCacheCapacity(newCapacity);
    }
  }

  /// Calculates optimal cache capacity based on memory pressure
  int _calculateOptimalCapacity(MemoryPressureLevel level) {
    switch (level) {
      case MemoryPressureLevel.critical:
        return _minCapacity;
      case MemoryPressureLevel.high:
        return (_minCapacity + (_maxCapacity - _minCapacity) * 0.25).round();
      case MemoryPressureLevel.moderate:
        return (_minCapacity + (_maxCapacity - _minCapacity) * 0.6).round();
      case MemoryPressureLevel.normal:
        return _maxCapacity;
    }
  }

  /// Adjusts the cache capacity and performs cleanup if needed
  void _adjustCacheCapacity(int newCapacity) {
    final int oldCapacity = _currentCapacity;
    _currentCapacity = newCapacity;
    _capacityAdjustments++;
    _lastCapacityChange = DateTime.now();

    // Create new cache with updated capacity
    final LruCache<Tile, TilePicture> oldCache = _cache;
    _cache = LruCache<Tile, TilePicture>(storage: storage, capacity: newCapacity);

    // If reducing capacity, we need to migrate the most recently used items
    if (newCapacity < oldCapacity) {
      _migrateMostRecentItems(oldCache, newCapacity);
    }

    // Trigger aggressive cleanup for critical memory pressure
    if (_memoryMonitor.currentPressureLevel == MemoryPressureLevel.critical) {
      _performAggressiveCleanup();
    }
  }

  /// Migrates the most recently used items to the new cache
  void _migrateMostRecentItems(LruCache<Tile, TilePicture> oldCache, int maxItems) {
    // This is a simplified migration - in a real implementation,
    // we would need access to the LRU order from the cache
    int migrated = 0;
    final List<Tile> tilesToMigrate = _spatialIndex.tileToGridCells.keys.take(maxItems).toList();

    for (final Tile tile in tilesToMigrate) {
      final TilePicture? picture = oldCache.get(tile);
      if (picture != null && migrated < maxItems) {
        _cache.set(tile, picture);
        migrated++;
      }
    }
  }

  /// Performs aggressive cleanup during critical memory pressure
  void _performAggressiveCleanup() {
    // Clear spatial index to free memory
    _spatialIndex.clear();

    // Force garbage collection hint (platform-specific)
    // This is a hint to the runtime, not guaranteed to trigger GC
    storage.clear();
  }

  @override
  void purgeAll() {
    _cache.clear();
    _spatialIndex.clear();
  }

  @override
  void purgeByBoundary(BoundingBox boundingBox) {
    final Set<Tile> tilesToRemove = _spatialIndex.getTilesInBoundary(boundingBox);

    for (final Tile tile in tilesToRemove) {
      _cache.remove(tile);
      _spatialIndex.removeTile(tile);
    }
  }

  @override
  Future<TilePicture> getOrProduce(Tile tile, Future<TilePicture> Function(Tile) producer) async {
    final TilePicture result = await _cache.getOrProduce(tile, producer);

    if (_cache.get(tile) != null) {
      _spatialIndex.addTile(tile);
    }

    return result;
  }

  @override
  TilePicture? get(Tile tile) {
    try {
      return _cache.get(tile);
    } catch (error) {
      return null;
    }
  }

  /// Gets current cache statistics including adaptive behavior
  Map<String, dynamic> getStatistics() {
    final Map<String, dynamic> memoryStats = _memoryMonitor.getMemoryStats();
    final Map<String, dynamic> spatialStats = _spatialIndex.getStatistics();

    return {
      'currentCapacity': _currentCapacity,
      'initialCapacity': _initialCapacity,
      'minCapacity': _minCapacity,
      'maxCapacity': _maxCapacity,
      'capacityAdjustments': _capacityAdjustments,
      'memoryPressureEvents': _memoryPressureEvents,
      'lastCapacityChange': _lastCapacityChange?.toIso8601String(),
      'memoryStats': memoryStats,
      'spatialStats': spatialStats,
      'cacheUtilization': _cache.length / _currentCapacity,
    };
  }

  /// Forces a memory pressure check and potential cache adjustment
  void checkMemoryPressure() {
    _memoryMonitor.forceCheck();
  }

  /// Gets the current memory pressure level
  MemoryPressureLevel get currentMemoryPressure => _memoryMonitor.currentPressureLevel;

  /// Gets the current cache capacity
  int get currentCapacity => _currentCapacity;

  /// Gets the current cache size
  int get currentSize => _cache.length;

  /// Static methods for managing all instances

  static void purgeAllCaches() {
    for (AdaptiveMemoryTileCache cache in _instances) {
      cache.purgeAll();
    }
  }

  static void purgeCachesByBoundary(BoundingBox boundingBox) {
    for (AdaptiveMemoryTileCache cache in _instances) {
      cache.purgeByBoundary(boundingBox);
    }
  }

  static void checkAllMemoryPressure() {
    for (AdaptiveMemoryTileCache cache in _instances) {
      cache.checkMemoryPressure();
    }
  }

  static Map<String, dynamic> getGlobalStatistics() {
    final List<Map<String, dynamic>> instanceStats = _instances.map((cache) => cache.getStatistics()).toList();

    int totalCapacity = 0;
    int totalSize = 0;
    int totalAdjustments = 0;

    for (final Map<String, dynamic> stats in instanceStats) {
      totalCapacity += stats['currentCapacity'] as int;
      totalSize += stats['spatialStats']['totalTiles'] as int;
      totalAdjustments += stats['capacityAdjustments'] as int;
    }

    return {
      'totalInstances': _instances.length,
      'totalCapacity': totalCapacity,
      'totalSize': totalSize,
      'totalCapacityAdjustments': totalAdjustments,
      'instanceStats': instanceStats,
    };
  }
}
