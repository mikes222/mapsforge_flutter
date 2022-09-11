import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/utils/filehelper.dart';

class ImageRelativeLoader implements ImageLoader {
  static final String PREFIX_JAR = "jar:";

  static final String PREFIX_JAR_V1 =
      "jar:/org/mapsforge/android/maps/rendertheme";

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
      src = "packages/mapsforge_flutter/assets/" + src;
    } else if (src.startsWith(PREFIX_JAR_V1)) {
      src = src.substring(PREFIX_JAR_V1.length);
      src = "packages/mapsforge_flutter/assets/" + src;
    }
    String dir = await FileHelper.findLocalPath();
    src = dir + "/" + relativePathPrefix + src;
    //_log.info("Trying to load symbol from $src");
    File file = File(src);
    if (await file.exists()) {
      Uint8List bytes = await file.readAsBytes();
      return ByteData.view(bytes.buffer);
    }
    return null;
  }
}
