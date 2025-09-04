import 'dart:typed_data';

abstract class ImageLoader {
  Future<Uint8List?> fetchResource(String src);
}
