import 'package:dcache/dcache.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

class MemoryBitmapCache {
  Cache _bitmaps = new SimpleCache<Tile, TileBitmap>(
      storage: new SimpleStorage<Tile, TileBitmap>(size: 100),
      onEvict: (key, item) {
        item.decrementRefCount();
      });

  TileBitmap getTileBitmap(Tile tile) {
    return _bitmaps.get(tile);
  }

  void addTileBitmap(Tile tile, TileBitmap tileBitmap) {
    TileBitmap bitmap = _bitmaps.get(tile);
    if (bitmap != null) {
      bitmap.decrementRefCount();
    }
    tileBitmap.incrementRefCount();
    _bitmaps[tile] = tileBitmap;
  }
}
