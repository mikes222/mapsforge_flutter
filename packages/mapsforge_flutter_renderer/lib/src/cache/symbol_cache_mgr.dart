import 'package:mapsforge_flutter_renderer/src/cache/file_symbol_cache.dart';
import 'package:mapsforge_flutter_renderer/src/cache/symbol_cache.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';

/// Central manager for symbol caching operations.
///
/// This singleton class provides a unified interface for symbol caching across
/// the rendering system. It manages the lifecycle of cached symbols and handles
/// loading, scaling, and retrieval of bitmap symbols used in map rendering.
///
/// Key features:
/// - Singleton pattern for global cache management
/// - Automatic symbol loading and scaling
/// - File-based caching implementation
/// - Thread-safe symbol retrieval
class SymbolCacheMgr {
  /// Singleton instance of the symbol cache manager.
  static SymbolCacheMgr? _instance;

  /// Underlying symbol cache implementation.
  late SymbolCache symbolCache;

  /// Private constructor for singleton pattern.
  ///
  /// Initializes the symbol cache with a file-based implementation.
  SymbolCacheMgr._() {
    symbolCache = FileSymbolCache();
  }

  /// Factory constructor returning the singleton instance.
  ///
  /// Creates the instance on first access and returns the same instance
  /// for subsequent calls to ensure global cache consistency.
  ///
  /// Returns the singleton SymbolCacheMgr instance
  factory SymbolCacheMgr() {
    if (_instance != null) return _instance!;
    _instance = SymbolCacheMgr._();
    return _instance!;
  }

  /// Disposes all cached symbols. This can be called after usage of mapfiles to free memory.
  void dispose() {
    symbolCache.dispose();
    _instance = null;
  }

  /// Loads and returns the desired symbol with optional scaling.
  ///
  /// Retrieves a symbol from the cache or loads it from the source if not cached.
  /// The symbol can be automatically scaled to the specified dimensions while
  /// maintaining aspect ratio and visual quality.
  ///
  /// [src] Source path or identifier for the symbol
  /// [width] Target width for scaling, 0 to maintain original
  /// [height] Target height for scaling, 0 to maintain original
  /// Returns SymbolImage or null if loading fails
  Future<SymbolImage?> getOrCreateSymbol(String src, int width, int height) async {
    return symbolCache.getOrCreateSymbol(src, width, height);
  }
}
