import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mapsforge_flutter_renderer/src/cache/image_loader.dart';

/// An `ImageLoader` that loads image resources from the local file system.
class ImageFileLoader implements ImageLoader {
  final String pathPrefix;

  /// Creates a new `ImageFileLoader`.
  ///
  /// [pathPrefix] The prefix to prepend to the resource path.
  const ImageFileLoader({required this.pathPrefix});

  /// Fetches the image resource from the file system.
  @override
  Future<Uint8List?> fetchResource(String src) async {
    src = "$pathPrefix$src";
    File file = File(src);
    Uint8List bytes = await file.readAsBytes();
    return bytes;
  }
}
