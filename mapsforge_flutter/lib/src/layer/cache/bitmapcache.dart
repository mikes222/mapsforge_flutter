import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

abstract class BitmapCache {
  void dispose();

  TileBitmap getTileBitmap(Tile tile);

  Future<TileBitmap> getTileBitmapAsync(Tile tile) async {
    return getTileBitmap(tile);
  }

  void addTileBitmap(Tile tile, TileBitmap tileBitmap);

  void purge();
}
