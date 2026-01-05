import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';

/// Service for handling ZIP file extraction operations
/// Optimized for large files with streaming, progress tracking, and cancellation support
class UnzipService {
  /// Unzipping a file into the specified [destinationDirectory]
  /// Optimized for large files with streaming, progress tracking, and cancellation support
  Future<void> unzipAbsolute(
    String sourceFilename,
    String destinationDirectory, {
    Function(int extractedFiles, int totalFiles, String currentFile)? onProgress,
    CancelToken? cancelToken,
  }) async {
    // Ensure destination directory exists
    final destDir = Directory(destinationDirectory);
    if (!destDir.existsSync()) {
      await destDir.create(recursive: true);
    }

    await _unzipLargeFile(sourceFilename, destinationDirectory, onProgress, cancelToken);
  }

  Future<void> _unzipLargeFile(
    String source,
    String destinationDirectory,
    Function(int extractedFiles, int totalFiles, String currentFile)? onProgress,
    CancelToken? cancelToken,
  ) async {
    // Use an InputFileStream to access the zip file without storing it in memory.
    // Note that using InputFileStream will result in an error from the web platform
    // as there is no file system there.
    final inputStream = InputFileStream(source);
    // Decode the zip from the InputFileStream. The archive will have the contents of the
    // zip, without having stored the data in memory.
    final archive = ZipDecoder().decodeStream(inputStream);
    final symbolicLinks = []; // keep a list of the symbolic link entities, if any.
    // For all of the entries in the archive
    int totalFiles = archive.length;
    int extractedFiles = 0;
    for (final archiveFile in archive) {
      // You should create symbolic links **after** the rest of the archive has been
      // extracted, otherwise the file being linked might not exist yet.
      if (cancelToken?.isCancelled == true) {
        throw Exception('Unzip operation was cancelled');
      }
      if (archiveFile.isSymbolicLink) {
        symbolicLinks.add(archiveFile);
      } else if (archiveFile.isFile) {
        // Write the file content to a directory called 'out'.
        // In practice, you should make sure file.name doesn't include '..' paths
        // that would put it outside of the extraction directory.
        // An OutputFileStream will write the data to disk.
        final outputStream = OutputFileStream('$destinationDirectory/${archiveFile.name}');
        // The writeContent method will decompress the file content directly to disk without
        // storing the decompressed data in memory.
        archiveFile.writeContent(outputStream, freeMemory: false);
        // Make sure to close the output stream so the File is closed.
        outputStream.closeSync();
        ++extractedFiles;
        onProgress?.call(extractedFiles, totalFiles, archiveFile.name);
      } else {
        // If the entity is a directory, create it. Normally writing a file will create
        // the directories necessary, but sometimes an archive will have an empty directory
        // with no files.
        Directory('$destinationDirectory/${archiveFile.name}').createSync(recursive: true);
      }
    }
    // Create symbolic links **after** the rest of the archive has been extracted to make sure
    // the file being linked exists.
    for (final entity in symbolicLinks) {
      // Before using this in production code, you should ensure the symbolicLink path
      // points to a file within the archive, otherwise it could be a security issue.
      final link = Link('$destinationDirectory/${entity.fullPathName}');
      link.createSync(entity.symbolicLink!, recursive: true);
    }
  }
}
