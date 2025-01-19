import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/core.dart';

/// Loads images based on the absolute path given to the constructor
class ImageAbsoluteLoader implements ImageLoader {
  static final String PREFIX_JAR = "jar:";

  static final String PREFIX_JAR_V1 =
      "jar:/org/mapsforge/android/maps/rendertheme";

  static final String PREFIX_FILE = "file:";

  final String absolutePathPrefix;

  const ImageAbsoluteLoader({required this.absolutePathPrefix});

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
    } else if (src.startsWith(PREFIX_FILE)) {
      src = src.substring(PREFIX_FILE.length);
    }
    if (!absolutePathPrefix.endsWith("/")) {
      src = "/$src";
    }
    src = absolutePathPrefix + src;
    File file = File(src);
    if (await file.exists()) {
      Uint8List bytes = await file.readAsBytes();
      return ByteData.view(bytes.buffer);
    }
    return null;
  }
}
