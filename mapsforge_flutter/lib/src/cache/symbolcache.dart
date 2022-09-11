import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';

///
/// An abstract cache for symbols (small bitmaps used in the map, eg. stopsigns, arrows). The class retrieves and caches requested symbols. It also resizes them if desired.
///
abstract class SymbolCache {
  SymbolCache();

  ///
  /// Disposes the cache. It should not be used afterwards
  ///
  void dispose() {}

  ///
  /// loads and returns the desired symbol, optionally rescales it to the given width and height
  ///
  Future<ResourceBitmap?> getOrCreateSymbol(String src, int width, int height);
}
