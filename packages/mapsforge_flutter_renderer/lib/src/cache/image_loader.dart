import 'dart:typed_data';

/// An abstract class that defines the interface for loading image resources.
///
/// Implementations of this class are responsible for fetching the raw byte data
/// of an image from a specific source, such as the file system or an asset bundle.
abstract class ImageLoader {
  /// Fetches the image resource from the given [src] path.
  Future<Uint8List?> fetchResource(String src);
}
