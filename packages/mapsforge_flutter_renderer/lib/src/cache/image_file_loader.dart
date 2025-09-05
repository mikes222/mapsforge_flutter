import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mapsforge_flutter_renderer/src/cache/image_loader.dart';

class ImageFileLoader implements ImageLoader {
  final String pathPrefix;

  const ImageFileLoader({required this.pathPrefix});

  ///
  /// Returns the content of the symbol given as [src] as [ByteData]. This method reads the file or resource and returns the requested bytes.
  ///
  @override
  Future<Uint8List?> fetchResource(String src) async {
    src = "$pathPrefix$src";
    File file = File(src);
    Uint8List bytes = await file.readAsBytes();
    return bytes;
  }
}
