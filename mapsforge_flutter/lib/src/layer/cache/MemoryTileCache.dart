import 'package:dcache/dcache.dart';
import 'package:mapsforge_flutter/src/cache/tilecache.dart';
import 'package:mapsforge_flutter/src/model/observable.dart';
import 'package:mapsforge_flutter/src/model/observer.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/projection/mercatorprojectionimpl.dart';

/**
 * A thread-safe cache for tile images with a variable size and LRU policy.
 */
class MemoryTileCache extends TileCache {
  final Map<int, _ZoomLevelTileCache> _caches = Map();

  Observable observable;

  /**
   * @param capacity the maximum number of entries in this cache.
   * @throws IllegalArgumentException if the capacity is negative.
   */
  MemoryTileCache() {
    this.observable = new Observable();
  }

  @override
  void destroy() {
    purge();
  }

  @override
  void purge() {}

  /**
   * Sets the new size of this cache. If this cache already contains more items than the new capacity allows, items
   * are discarded based on the cache policy.
   *
   * @param capacity the new maximum number of entries in this cache.
   * @throws IllegalArgumentException if the capacity is negative.
   */
  void setCapacity(int capacity) {}

  @override
  void addObserver(final Observer observer) {
    this.observable.addObserver(observer);
  }

  @override
  void removeObserver(final Observer observer) {
    this.observable.removeObserver(observer);
  }

  @override
  Tile getTile(int x, int y, int zoomLevel, double tileSize) {
    _ZoomLevelTileCache cache = _caches[zoomLevel];
    if (cache == null) {
      cache = _ZoomLevelTileCache(zoomLevel, tileSize);
      _caches[zoomLevel] = cache;
    }
    return cache.getTile(x, y);
  }
}

/////////////////////////////////////////////////////////////////////////////

class _ZoomLevelTileCache {
  Cache _tilePositions = new SimpleCache<int, Tile>(
      storage: new SimpleStorage<int, Tile>(size: 100),
      onEvict: (idx, tile) {
        tile.dispose();
      });

  int xCount;

  int yCount;

  final double tileSize;

  final int zoomLevel;

  _ZoomLevelTileCache(this.zoomLevel, this.tileSize)
      : assert(zoomLevel >= 0),
        assert(tileSize > 0) {
    _getTilePositions(zoomLevel, tileSize);
    //_bitmaps = List(_tilePositions.length);
  }

  void _getTilePositions(int zoomLevel, double tileSize) {
    MercatorProjectionImpl mercatorProjectionImpl = MercatorProjectionImpl(tileSize, zoomLevel);
    int tileLeft = 0;
    int tileTop = 0;
    int tileRight = mercatorProjectionImpl.longitudeToTileX(MercatorProjectionImpl.LONGITUDE_MAX);
    int tileBottom = mercatorProjectionImpl.latitudeToTileY(MercatorProjectionImpl.LATITUDE_MIN);

    xCount = tileRight - tileLeft + 1;
    yCount = tileBottom - tileTop + 1;
    assert(xCount >= 0);
    assert(yCount >= 0);

    //_tilePositions = List<Tile>(xCount * yCount);
  }

  Tile getTile(int x, int y) {
    Tile result = _tilePositions.get(y * xCount + x);
    if (result == null) {
      result = Tile(x, y, zoomLevel, tileSize);
      _tilePositions[y * xCount + x] = result;
    }
    //assert(result != null);
    return result;
  }
}
