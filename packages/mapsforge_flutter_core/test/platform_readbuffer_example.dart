import 'dart:html' as html;

import 'package:mapsforge_flutter_core/src/buffer/readbuffer_factory.dart';
import 'package:mapsforge_flutter_core/src/buffer/readbuffer_source.dart';

/// Example usage patterns for cross-platform file reading
class PlatformReadbufferExample {
  /// Example 1: Reading a local file on native platforms
  static Future<void> readNativeFile(String filePath) async {
    if (ReadbufferFactory.supportsFilePaths) {
      final source = ReadbufferFactory.fromPath(filePath);

      // Read file length
      final length = await source.length();
      print('File length: $length bytes');

      // Read first 1024 bytes
      final buffer = await source.readFromFileAt(0, 1024);
      //print('Read ${buffer.length} bytes from position 0');

      source.dispose();
    } else {
      print('File paths not supported on this platform');
    }
  }

  /// Example 2: Reading a user-selected file on web
  static Future<void> readWebFile(html.File file) async {
    if (ReadbufferFactory.supportsFileObjects) {
      final source = ReadbufferFactory.fromFile(file);

      // Read file length
      final length = await source.length();
      print('File length: $length bytes');

      // Read chunks of 4KB each
      const chunkSize = 4096;
      for (int pos = 0; pos < length; pos += chunkSize) {
        final remainingBytes = (length - pos).clamp(0, chunkSize);
        final buffer = await source.readFromFileAt(pos, remainingBytes);
        //print('Read ${buffer.length} bytes from position $pos');

        // Process the chunk here
        await processChunk(buffer);
      }

      source.dispose();
    } else {
      print('File objects not supported on this platform');
    }
  }

  /// Example 3: Reading a remote file via HTTP Range requests
  static Future<void> readRemoteFile(String url) async {
    if (ReadbufferFactory.supportsUrlReading) {
      final source = ReadbufferFactory.fromUrl(url);

      try {
        // Read file length
        final length = await source.length();
        print('Remote file length: $length bytes');

        // Read specific ranges (useful for map tiles, headers, etc.)
        final header = await source.readFromFileAt(0, 512);
        //print('Read header: ${header.length} bytes');

        final middle = await source.readFromFileAt(length ~/ 2, 1024);
        //print('Read middle section: ${middle.length} bytes');

        source.dispose();
      } catch (e) {
        print('Error reading remote file: $e');
        print('Server may not support Range requests');
      }
    } else {
      print('URL reading not supported on this platform');
    }
  }

  /// Example 4: Universal file reading with platform detection
  static Future<ReadbufferSource?> createSource({String? filePath, html.File? file, String? url}) async {
    // Try native file path first
    if (filePath != null && ReadbufferFactory.supportsFilePaths) {
      return ReadbufferFactory.fromPath(filePath);
    }

    // Try web file object
    if (file != null && ReadbufferFactory.supportsFileObjects) {
      return ReadbufferFactory.fromFile(file);
    }

    // Try remote URL
    if (url != null && ReadbufferFactory.supportsUrlReading) {
      return ReadbufferFactory.fromUrl(url);
    }

    return null;
  }

  /// Example 5: File input handler for web
  static void setupFileInput() {
    if (ReadbufferFactory.supportsFileObjects) {
      final fileInput = html.FileUploadInputElement()
        ..accept =
            '.map,.mbtiles' // Accept map files
        ..multiple = false;

      fileInput.onChange.listen((e) async {
        final files = fileInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files.first;
          print('Selected file: ${file.name} (${file.size} bytes)');

          // Create ReadbufferSource and start processing
          await readWebFile(file);
        }
      });

      // Add to DOM
      html.document.body?.append(fileInput);
    }
  }

  /// Process a chunk of data (placeholder for actual processing logic)
  static Future<void> processChunk(dynamic buffer) async {
    // Your map file processing logic here
    await Future.delayed(const Duration(milliseconds: 1));
  }
}

/// Integration example for existing mapsforge code
class MapfileWebAdapter {
  /// Adapt existing mapfile reading code for web compatibility
  static Future<ReadbufferSource> createMapfileSource({String? nativeFilePath, html.File? webFile, String? remoteUrl}) async {
    final source = await PlatformReadbufferExample.createSource(filePath: nativeFilePath, file: webFile, url: remoteUrl);

    if (source == null) {
      throw UnsupportedError('No compatible file source available for current platform');
    }

    return source;
  }

  /// Example of how to modify existing mapfile constructor
  static Future<void> loadMapfile({String? nativeFilePath, html.File? webFile, String? remoteUrl}) async {
    final source = await createMapfileSource(nativeFilePath: nativeFilePath, webFile: webFile, remoteUrl: remoteUrl);

    // Use the source with existing mapfile reading logic
    // This replaces the RandomAccessFile usage in your current code

    try {
      final length = await source.length();
      print('Mapfile size: $length bytes');

      // Read mapfile header (typically first few KB)
      final headerBuffer = await source.readFromFileAt(0, 4096);

      // Continue with existing mapfile parsing logic...
      // The ReadbufferSource interface remains the same
    } finally {
      source.dispose();
    }
  }
}
