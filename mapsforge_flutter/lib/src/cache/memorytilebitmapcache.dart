import 'package:dcache/dcache.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

import 'tilebitmapcache.dart';

class MemoryTileBitmapCache extends TileBitmapCache {
  Cache<Tile, TileBitmap> _bitmaps = new SimpleCache<Tile, TileBitmap>(
    storage: SimpleStorage<Tile, TileBitmap>(onEvict: (key, item) {
      item.decrementRefCount();
    }),
    capacity: 100,
  );

  @override
  void dispose() {
    _bitmaps.clear();
  }

  TileBitmap getTileBitmap(Tile tile) {
    return _bitmaps.get(tile);
  }

  void addTileBitmap(Tile tile, TileBitmap tileBitmap) {
    assert(tile != null);
    assert(tileBitmap != null);
    tileBitmap.incrementRefCount();
    TileBitmap bitmap = _bitmaps.get(tile);
    if (bitmap != null) {
      bitmap.decrementRefCount();
    }
    _bitmaps[tile] = tileBitmap;
  }

  @override
  void purgeAll() {
    _bitmaps.clear();
  }

  @override
  void purgeByBoundary(BoundingBox boundingBox) {
    _bitmaps.storage.keys.where((Tile tile) {
      if (tile.getBoundingBox().intersects(boundingBox)) {
        return true;
      }
      return false;
    }).forEach((tile) {
      _bitmaps.remove(tile);
    });
  }
}
