import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';

///
/// An abstract cache for symbols (small bitmaps used in the map, eg. stopsigns, arrows). The class retrieves and caches requested symbols. It also resizes them if desired.
///
abstract class SymbolCache {

  /**
   * Default size is 20x20px (400px) at baseline mdpi (160dpi).
   */
  static int DEFAULT_SIZE = 20;

  SymbolCache();

  ///
  /// Disposes the cache. It should not be used afterwards
  ///
  void dispose() {}

  ///
  /// loads and returns the desired symbol, optionally rescales it to the given width and height
  ///
  Future<ResourceBitmap?> getSymbol(String? src, int width, int height, int? percent);
}
