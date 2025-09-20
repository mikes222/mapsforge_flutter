import 'package:flutter/services.dart';
import 'package:mapsforge_flutter_renderer/src/cache/image_loader.dart';

/// An `ImageLoader` that loads image resources from a Flutter `AssetBundle`.
class ImageBundleLoader implements ImageLoader {
  final AssetBundle bundle;

  final String pathPrefix;

  /// Creates a new `ImageBundleLoader`.
  ///
  /// [bundle] The asset bundle to load from.
  /// [pathPrefix] An optional prefix to prepend to the resource path.
  const ImageBundleLoader({required this.bundle, this.pathPrefix = "packages/mapsforge_flutter_rendertheme/assets/"});

  /// Fetches the image resource from the asset bundle.
  @override
  Future<Uint8List?> fetchResource(String src) async {
    src = "$pathPrefix$src";
    ByteData content = await bundle.load(src);
    return content.buffer.asUint8List();
  }
}
