import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

import 'tilebitmapcache.dart';

///
/// This is a memory-only implementation of the [TileBitmapCache]. It stores the bitmaps in memory.
///
class MemoryTileBitmapCache extends TileBitmapCache {
  final SimpleStorage<Tile, TileBitmap> storage = SimpleStorage<Tile, TileBitmap>(onEvict: (key, item) {
    item.decrementRefCount();
  });
  late Cache<Tile, TileBitmap> _bitmaps;

  MemoryTileBitmapCache() {
    _bitmaps = new LruCache<Tile, TileBitmap>(
      storage: storage,
      capacity: 100,
    );
  }

  @override
  void dispose() {
    _bitmaps.clear();
  }

  @override
  TileBitmap? getTileBitmapSync(Tile tile) {
    return _bitmaps.get(tile);
  }

  @override
  Future<TileBitmap?> getTileBitmapAsync(Tile tile) async {
    return _bitmaps.get(tile);
  }

  void addTileBitmap(Tile tile, TileBitmap tileBitmap) {
    tileBitmap.incrementRefCount();
    // TileBitmap bitmap = _bitmaps.get(tile);
    // if (bitmap != null) {
    //   bitmap.decrementRefCount();
    // }
    _bitmaps[tile] = tileBitmap;
  }

  @override
  void purgeAll() {
    _bitmaps.clear();
  }

  @override
  void purgeByBoundary(BoundingBox boundingBox) {
    storage.keys.where((Tile tile) {
      Projection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
      if (projection.boundingBoxOfTile(tile).intersects(boundingBox)) {
        return true;
      }
      return false;
    }).forEach((tile) {
      _bitmaps.remove(tile);
    });
  }
}
