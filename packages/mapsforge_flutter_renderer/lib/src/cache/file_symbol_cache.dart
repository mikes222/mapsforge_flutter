import 'package:collection/collection.dart';
import 'package:ecache/ecache.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/src/cache/image_builder.dart';
import 'package:mapsforge_flutter_renderer/src/cache/image_bundle_loader.dart';
import 'package:mapsforge_flutter_renderer/src/cache/image_loader.dart';
import 'package:mapsforge_flutter_renderer/src/cache/symbol_cache.dart';
import 'package:mapsforge_flutter_renderer/src/exception/symbol_not_found_exception.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';

/// A cache for symbols (small bitmaps used in the map, e.g., stop signs, arrows).
///
/// This class loads symbols from various sources (e.g., assets, files) and
/// caches them in memory to improve performance. It supports different image
/// formats like SVG and PNG, and can resize symbols on the fly.
///
/// The [src] parameter for symbols specifies the filename, including the
/// extension, starting from the assets path (e.g., "patterns/arrow.png").
class FileSymbolCache extends SymbolCache {
  final Map<String, ImageLoader> imageLoaders = {};

  final ImageBuilder imageBuilder;

  final LruCache<String, SymbolImage> _cache = LruCache<String, SymbolImage>(
    onEvict: (key, item) {
      item.dispose();
    },
    capacity: 500,
    name: "FileSymbolCache.Resized",
  );

  final LruCache<String, Uint8List?> _resourceCache = LruCache<String, Uint8List?>(capacity: 500, name: "FileSymbolCache.Original");

  /// Creates a new `FileSymbolCache`.
  ///
  /// By default, it includes a loader for symbols from the app's asset bundle
  /// (using the "jar:" prefix). Additional loaders can be added with [addLoader].
  FileSymbolCache({this.imageBuilder = const ImageBuilder()}) {
    imageLoaders["jar:"] = ImageBundleLoader(bundle: rootBundle);
  }

  @override
  void dispose() {
    _cache.dispose();
    _resourceCache.dispose();
  }

  @override
  /// Adds a new [ImageLoader] for a given [prefix].
  ///
  /// This allows extending the cache to load symbols from different sources.
  @override
  void addLoader(String prefix, ImageLoader imageLoader) {
    imageLoaders[prefix] = imageLoader;
  }

  /// Retrieves a symbol from the cache or creates it if it doesn't exist.
  ///
  /// The returned [SymbolImage] is a clone and must be disposed by the caller.
  @override
  Future<SymbolImage?> getOrCreateSymbol(String? src, int width, int height) async {
    if (src == null || src.isEmpty) {
      // no image source defined
      return null;
    }
    String key = "$src-$width-$height";
    SymbolImage symbolImage = await _cache.getOrProduce(key, (_) async {
      return _createSymbol(src, width, height);
    });
    return symbolImage.clone();
  }

  Future<Uint8List?> _loadResource(String src) {
    return _resourceCache.getOrProduce(src, (_) async {
      var entry = imageLoaders.entries.firstWhereOrNull((entry) => src.startsWith(entry.key));
      if (entry == null) return null;
      src = src.substring(entry.key.length);
      return entry.value.fetchResource(src);
    });
  }

  Future<SymbolImage> _createSymbol(String src, int width, int height) async {
    // we need to hash with the width/height included as the same symbol could be required
    // in a different size and must be cached with a size-specific hash
    var session = PerformanceProfiler().startSession(category: "FileSymbolCache.createSymbol");
    Uint8List? byteData = await _loadResource(src);
    if (byteData == null) throw SymbolNotFoundException(src);
    if (src.toLowerCase().endsWith(".svg")) {
      SymbolImage result = await imageBuilder.createSvgSymbol(byteData, width, height);
      session.complete();
      return result;
    } else if (src.toLowerCase().endsWith(".png")) {
      SymbolImage result = await imageBuilder.createPngSymbol(byteData, width, height);
      session.complete();
      return result;
    } else {
      throw Exception("Unknown resource fileformat $src");
    }
  }
}
