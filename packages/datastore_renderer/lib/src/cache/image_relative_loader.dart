import 'dart:io';

import 'package:datastore_renderer/src/cache/image_loader.dart';
import 'package:flutter/services.dart';

class ImageRelativeLoader implements ImageLoader {
  static final String PREFIX_JAR = "jar:";

  final String relativePathPrefix;

  const ImageRelativeLoader({required this.relativePathPrefix});

  ///
  /// Returns the content of the symbol given as [src] as [ByteData]. This method reads the file or resource and returns the requested bytes.
  ///
  @override
  Future<ByteData?> fetchResource(String src) async {
    // compatibility with mapsforge
    if (src.startsWith(PREFIX_JAR)) {
      src = src.substring(PREFIX_JAR.length);
      src = "packages/mapsforge_flutter/assets/$src";
    }
    src = "$relativePathPrefix$src";
    //_log.info("Trying to load symbol from $src");
    File file = File(src);
    if (await file.exists()) {
      Uint8List bytes = await file.readAsBytes();
      return ByteData.view(bytes.buffer);
    }
    return null;
  }
}
