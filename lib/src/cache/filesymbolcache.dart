import 'package:ecache/ecache.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/exceptions/symbolnotfoundexception.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';

///
/// A cache for symbols (small bitmaps used in the map, eg. stopsigns, arrows). The [src] parameter specifies the filename including the
/// extension starting from the assets-path. eg. "patterns/arrow.png"
///
class FileSymbolCache extends SymbolCache {
  late ImageLoader imageLoader;

  final ImageBuilder imageBuilder;

  LruCache<String, ResourceBitmap> _cache =
      new LruCache<String, ResourceBitmap>(
    storage: StatisticsStorage<String, ResourceBitmap>(onEvict: (key, item) {
      item.dispose();
    }),
    capacity: 500,
  );

  ///
  /// Creates a new FileSymbolCache which loads symbols from file-sources and
  /// holds them in memory. By specifying the [imageLoader] one can define the
  /// source or method how to retrieve the binary data for a symbol.
  ///
  FileSymbolCache(
      {ImageLoader? imageLoader = null,
      this.imageBuilder = const ImageBuilder()}) {
    this.imageLoader = imageLoader ?? ImageBundleLoader(bundle: rootBundle);
  }

  @override
  void dispose() {
    print("Statistics for FileSymbolCache: ${_cache.storage.toString()}");
    _cache.clear();
  }

  //Future? future;
  @override
  Future<ResourceBitmap?> getOrCreateSymbol(
      String? src, int width, int height) async {
    if (src == null || src.length == 0) {
      // no image source defined
      return null;
    }
    String key = "$src-$width-$height";
    ResourceBitmap? resourceBitmap = _cache.get(key);
    if (resourceBitmap != null) {
      return resourceBitmap.clone();
    }

    resourceBitmap = await _createSymbol(src, width, height);
    _cache.set(key, resourceBitmap);
    return resourceBitmap.clone();
  }

  Future<ResourceBitmap> _createSymbol(
      String src, int width, int height) async {
// we need to hash with the width/height included as the same symbol could be required
// in a different size and must be cached with a size-specific hash
    ByteData? byteData = await imageLoader.fetchResource(src);
    if (byteData == null) throw SymbolNotFoundException(src);
    if (src.toLowerCase().endsWith(".svg")) {
      return imageBuilder.createSvgSymbol(byteData, src, width, height);
    } else if (src.toLowerCase().endsWith(".png")) {
      return imageBuilder.createPngSymbol(byteData, src, width, height);
    } else {
      throw Exception("Unknown resource fileformat $src");
    }
  }
}
