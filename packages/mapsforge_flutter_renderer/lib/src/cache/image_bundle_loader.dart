import 'package:mapsforge_flutter_renderer/src/cache/image_loader.dart';
import 'package:flutter/services.dart';

class ImageBundleLoader implements ImageLoader {
  static final String PREFIX_JAR = "jar:";

  final AssetBundle? bundle;

  const ImageBundleLoader({this.bundle});

  ///
  /// Returns the content of the symbol given as [src] as [ByteData]. This method reads the file or resource and returns the requested bytes.
  ///
  @override
  Future<ByteData?> fetchResource(String src) async {
    // compatibility with mapsforge
    if (src.startsWith(PREFIX_JAR)) {
      src = src.substring(PREFIX_JAR.length);
      src = "packages/dart_rendertheme/assets/$src";
    }
    if (bundle != null) {
      ByteData content = await bundle!.load(src);
      return content;
    }
    return null;
  }
}
