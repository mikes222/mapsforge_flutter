import 'package:mapsforge_flutter_renderer/src/cache/image_builder.dart';
import 'package:mapsforge_flutter_renderer/src/cache/image_bundle_loader.dart';
import 'package:mapsforge_flutter_renderer/src/cache/image_loader.dart';
import 'package:mapsforge_flutter_renderer/src/cache/symbol_cache.dart';
import 'package:mapsforge_flutter_renderer/src/exception/symbol_not_found_exception.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';
import 'package:ecache/ecache.dart';
import 'package:flutter/services.dart';

///
/// A cache for symbols (small bitmaps used in the map, eg. stopsigns, arrows). The [src] parameter specifies the filename including the
/// extension starting from the assets-path. eg. "patterns/arrow.png"
///
class FileSymbolCache extends SymbolCache {
  late ImageLoader imageLoader;

  final ImageBuilder imageBuilder;

  final LruCache<String, SymbolImage> _cache = LruCache<String, SymbolImage>(
    storage: StatisticsStorage<String, SymbolImage>(
      onEvict: (key, item) {
        item.dispose();
      },
    ),
    capacity: 500,
  );

  ///
  /// Creates a new FileSymbolCache which loads symbols from file-sources and
  /// holds them in memory. By specifying the [imageLoader] one can define the
  /// source or method how to retrieve the binary data for a symbol.
  ///
  FileSymbolCache({ImageLoader? imageLoader, this.imageBuilder = const ImageBuilder()}) {
    this.imageLoader = imageLoader ?? ImageBundleLoader(bundle: rootBundle);
  }

  @override
  void dispose() {
    print("Statistics for FileSymbolCache: ${_cache.storage.toString()}");
    _cache.clear();
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

  Future<SymbolImage> _createSymbol(String src, int width, int height) async {
    // we need to hash with the width/height included as the same symbol could be required
    // in a different size and must be cached with a size-specific hash
    ByteData? byteData = await imageLoader.fetchResource(src);
    if (byteData == null) throw SymbolNotFoundException(src);
    if (src.toLowerCase().endsWith(".svg")) {
      return imageBuilder.createSvgSymbol(byteData, width, height);
    } else if (src.toLowerCase().endsWith(".png")) {
      return imageBuilder.createPngSymbol(byteData, width, height);
    } else {
      throw Exception("Unknown resource fileformat $src");
    }
  }
}
