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

///
/// A cache for symbols (small bitmaps used in the map, eg. stopsigns, arrows). The [src] parameter specifies the filename including the
/// extension starting from the assets-path. eg. "patterns/arrow.png"
///
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

  ///
  /// Creates a new FileSymbolCache which loads symbols from file-sources and
  /// holds them in memory. By specifying the [imageLoader] one can define the
  /// source or method how to retrieve the binary data for a symbol.
  ///
  FileSymbolCache({this.imageBuilder = const ImageBuilder()}) {
    imageLoaders["jar:"] = ImageBundleLoader(bundle: rootBundle);
  }

  @override
  void dispose() {
    _cache.dispose();
    _resourceCache.dispose();
  }

  @override
  void addLoader(String prefix, ImageLoader imageLoader) {
    imageLoaders[prefix] = imageLoader;
  }

  // Returns or creates the requested symbol image. The returned image must be dispose()-ed
  @override
  Future<SymbolImage?> getOrCreateSymbol(String? src, int width, int height) async {
    if (src == null || src.isEmpty) {
      // no image source defined
      return null;
    }
    String key = "$src-$width-$height";
    SymbolImage symbolImage = await _cache.getOrProduce(key, (_) async {
      return await _createSymbol(src, width, height);
    });
    return symbolImage.clone();
  }

  Future<Uint8List?> _loadResource(String src) async {
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
