import 'package:flutter/services.dart';
import 'package:mapsforge_flutter_renderer/src/cache/image_loader.dart';

class ImageBundleLoader implements ImageLoader {
  final AssetBundle bundle;

  final String pathPrefix;

  const ImageBundleLoader({required this.bundle, this.pathPrefix = "packages/mapsforge_flutter_rendertheme/assets/"});

  ///
  /// Returns the content of the symbol given as [src] as [ByteData]. This method reads the file or resource and returns the requested bytes.
  ///
  @override
  Future<Uint8List?> fetchResource(String src) async {
    src = "$pathPrefix$src";
    ByteData content = await bundle.load(src);
    return content.buffer.asUint8List();
  }
}
