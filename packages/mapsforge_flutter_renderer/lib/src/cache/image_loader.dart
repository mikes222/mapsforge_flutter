import 'dart:typed_data';

abstract class ImageLoader {
  Future<ByteData?> fetchResource(String src);
}
