import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/core.dart';

class ImageBundleLoader implements ImageLoader {
  static final String PREFIX_JAR = "jar:";

  static final String PREFIX_JAR_V1 =
      "jar:/org/mapsforge/android/maps/rendertheme";

  final AssetBundle? bundle;

  const ImageBundleLoader({this.bundle = null});

  ///
  /// Returns the content of the symbol given as [src] as [ByteData]. This method reads the file or resource and returns the requested bytes.
  ///
  @override
  Future<ByteData?> fetchResource(String src) async {
    // compatibility with mapsforge
    if (src.startsWith(PREFIX_JAR)) {
      src = src.substring(PREFIX_JAR.length);
      src = "packages/mapsforge_flutter/assets/" + src;
    } else if (src.startsWith(PREFIX_JAR_V1)) {
      src = src.substring(PREFIX_JAR_V1.length);
      src = "packages/mapsforge_flutter/assets/" + src;
    }
    if (bundle != null) {
      ByteData content = await bundle!.load(src);
      return content;
    }
    return null;
  }
}
