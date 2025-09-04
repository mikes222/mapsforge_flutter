import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Cross-platform file download service
/// Handles downloads for both native platforms and web
class PlatformFileDownloadService {
  final Dio _dio = Dio();

  /// Download a file with progress tracking
  ///
  /// For native platforms: Saves to specified file path
  /// For web: Triggers browser download with user-specified filename
  Future<void> downloadFile({
    required String url,
    required String filename,
    String? savePath, // Used on native platforms
    Function(int received, int total)? onProgress,
  }) async {
    if (kIsWeb) {
      await _downloadForWeb(url, filename, onProgress);
    } else {
      await _downloadForNative(url, filename, savePath, onProgress);
    }
  }

  /// Download file for web platform using browser download
  Future<void> _downloadForWeb(String url, String filename, Function(int received, int total)? onProgress) async {
    // Download the file data
    final response = await _dio.get(
      url,
      onReceiveProgress: onProgress,
      options: Options(responseType: ResponseType.bytes, followRedirects: false, validateStatus: (status) => status != null && status < 500),
    );

    // For web, we'll use a method channel to trigger download
    if (kIsWeb) {
      await _triggerWebDownload(response.data, filename);
    }
  }

  /// Download file for native platforms
  Future<void> _downloadForNative(String url, String filename, String? savePath, Function(int received, int total)? onProgress) async {
    final response = await _dio.get(
      url,
      onReceiveProgress: onProgress,
      options: Options(responseType: ResponseType.bytes, followRedirects: false, validateStatus: (status) => status != null && status < 400),
    );

    await _saveNativeFile(response.data, savePath ?? filename);
  }

  /// Trigger download on web platform
  Future<void> _triggerWebDownload(List<int> data, String filename) async {
    try {
      // Use method channel for web downloads
      const platform = MethodChannel('file_download');
      await platform.invokeMethod('downloadFile', {'data': data, 'filename': filename});
    } catch (error, stacktrace) {
      print(error);
      print(stacktrace);
      // Fallback: create a data URL and try to download
      final bytes = Uint8List.fromList(data);
      final base64 = _bytesToBase64(bytes);
      final dataUrl = 'data:application/octet-stream;base64,$base64';

      // This is a simplified approach - in a real app you'd need proper web integration
      throw Exception('Web download not fully implemented. Data ready as base64: ${dataUrl.substring(0, 100)}...');
    }
  }

  /// Save file on native platforms
  Future<void> _saveNativeFile(List<int> data, String filePath) async {
    File file = File(filePath);
    await file.writeAsBytes(data);

    if (filePath.endsWith(".zip")) {
      String destination = filePath.substring(0, filePath.lastIndexOf("/"));
      await unzipAbsolute(filePath, destination);
    }
  }

  /// unzipping a file into the specified [destinationDirectory]
  Future<void> unzipAbsolute(String sourceFilename, String destinationDirectory) async {
    List<int> content = await File(sourceFilename).readAsBytes();
    Archive archive = ZipDecoder().decodeBytes(content);
    for (ArchiveFile file in archive) {
      if (file.isFile) {
        //        _log.info("Unzipping ${file.name} to $destinationDirectory/${file.name}");
        List<int> unzipped = file.content;
        File destinationFile = File("$destinationDirectory/${file.name}");
        // wait until the file has been written
        await destinationFile.writeAsBytes(unzipped);
      } else {
        //      _log.info("Unzipping directory ${file.name} to $destinationDirectory/${file.name}");
        Directory directory = Directory("$destinationDirectory/${file.name}");
        await directory.create(recursive: true);
      }
      //break;
    }
  }

  /// Convert bytes to base64 string
  String _bytesToBase64(Uint8List bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    String result = '';

    for (int i = 0; i < bytes.length; i += 3) {
      int byte1 = bytes[i];
      int byte2 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      int byte3 = i + 2 < bytes.length ? bytes[i + 2] : 0;

      int combined = (byte1 << 16) | (byte2 << 8) | byte3;

      result += chars[(combined >> 18) & 63];
      result += chars[(combined >> 12) & 63];
      result += i + 1 < bytes.length ? chars[(combined >> 6) & 63] : '=';
      result += i + 2 < bytes.length ? chars[combined & 63] : '=';
    }

    return result;
  }

  /// Get suggested download directory for native platforms
  Future<String?> getSuggestedDownloadPath() async {
    if (kIsWeb) return null;

    try {
      const platform = MethodChannel('file_download');
      return await platform.invokeMethod('getSuggestedPath');
    } catch (error, stacktrace) {
      print(error);
      print(stacktrace);
      // Fallback path
      return '/storage/emulated/0/Download';
    }
  }

  /// Check if platform supports custom save paths
  bool get supportsCustomSavePath => !kIsWeb;

  /// Check if platform requires user interaction for downloads
  bool get requiresUserInteraction => kIsWeb;

  void dispose() {
    _dio.close();
  }
}
