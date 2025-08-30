import 'package:mapsforge_flutter_core/src/buffer/readbuffer_file.dart';
// Conditional imports for platform-specific implementations
import 'package:mapsforge_flutter_core/src/buffer/readbuffer_file_web.dart'
    if (dart.library.io) 'package:mapsforge_flutter_core/src/buffer/readbuffer_file.dart';
import 'package:mapsforge_flutter_core/src/buffer/readbuffer_source.dart';

/// Factory class for creating platform-appropriate ReadbufferSource instances
class ReadbufferFactory {
  /// Create a ReadbufferSource from a file path
  ///
  /// On native platforms (Android, iOS, Desktop): Uses RandomAccessFile
  /// On web: Throws UnsupportedError - use fromFile() or fromUrl() instead
  static ReadbufferSource fromPath(String filePath) {
    if (identical(0, 0.0)) {
      // Web platform - file paths are not supported
      throw UnsupportedError(
        'File paths are not supported on web. Use ReadbufferFactory.fromFile() '
        'for user-selected files or ReadbufferFactory.fromUrl() for remote files.',
      );
    } else {
      // Native platforms
      return ReadbufferFile(filePath);
    }
  }

  /// Create a ReadbufferSource from a user-selected file (web only)
  ///
  /// This method is only available on web platforms and requires the
  /// dart:html File object obtained from file input elements.
  static ReadbufferSource fromFile(dynamic file) {
    if (identical(0, 0.0)) {
      // Web platform
      return ReadbufferFileWeb.fromFile(file);
    } else {
      throw UnsupportedError(
        'fromFile() is only supported on web platforms. '
        'Use fromPath() on native platforms.',
      );
    }
  }

  /// Create a ReadbufferSource from a URL (web only)
  ///
  /// This method creates a ReadbufferSource that uses HTTP Range requests
  /// to read portions of remote files. The server must support Range requests.
  static ReadbufferSource fromUrl(String url) {
    if (identical(0, 0.0)) {
      // Web platform
      return ReadbufferFileWeb.fromUrl(url);
    } else {
      throw UnsupportedError(
        'fromUrl() is only supported on web platforms. '
        'Use fromPath() on native platforms.',
      );
    }
  }

  /// Check if the current platform supports file paths
  static bool get supportsFilePaths => !identical(0, 0.0);

  /// Check if the current platform supports File objects
  static bool get supportsFileObjects => identical(0, 0.0);

  /// Check if the current platform supports URL-based reading
  static bool get supportsUrlReading => identical(0, 0.0);
}
