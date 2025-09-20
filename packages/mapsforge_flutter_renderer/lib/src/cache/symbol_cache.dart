import 'package:mapsforge_flutter_renderer/src/cache/image_loader.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';

/// An abstract cache for symbols (small bitmaps used in the map, e.g., stop signs, arrows).
///
/// This class defines the interface for retrieving and caching requested symbols.
/// Implementations are responsible for loading symbols from various sources,
/// caching them, and optionally resizing them.
abstract class SymbolCache {
  SymbolCache();

  /// Disposes the cache and releases all its resources.
  ///
  /// After calling this method, the cache should not be used anymore.
  void dispose() {}

  /// Adds a new [ImageLoader] for a given [prefix].
  ///
  /// The loader is chosen based on the prefix of the requested symbol source path.
  void addLoader(String prefix, ImageLoader imageLoader);

  /// Retrieves a symbol from the cache or creates it if it doesn't exist.
  ///
  /// The symbol is identified by its source path [src]. If [width] and [height]
  /// are provided, the symbol is resized accordingly.
  Future<SymbolImage?> getOrCreateSymbol(String src, int width, int height);
}
