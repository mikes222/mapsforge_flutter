import 'dart:io';

import 'package:complete_example/services/unzip_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnzipService', () {
    late Directory tempDir;
    late UnzipService unzipService;

    setUp(() async {
      unzipService = UnzipService();
      tempDir = await Directory.systemTemp.createTemp('unzip_service_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('unzipAbsolute extracts Spain-Portugal.zip correctly', () async {
      final zipFile = File('test/Spain-Portugal.zip');
      expect(await zipFile.exists(), isTrue, reason: 'Spain-Portugal.zip should exist in test folder');

      int progressCalls = 0;
      int? lastExtractedFiles;
      int? lastTotalFiles;
      String? lastCurrentFile;

      await unzipService.unzipAbsolute(
        zipFile.path,
        tempDir.path,
        onProgress: (int extractedFiles, int totalFiles, String currentFile) {
          progressCalls++;
          lastExtractedFiles = extractedFiles;
          lastTotalFiles = totalFiles;
          lastCurrentFile = currentFile;
        },
      );

      // Ensure at least one file was extracted and progress was reported
      expect(progressCalls, greaterThan(0), reason: 'Progress callback should be invoked');
      expect(lastExtractedFiles, isNotNull);
      expect(lastTotalFiles, isNotNull);
      expect(lastCurrentFile, isNotNull);

      // Verify that the destination directory now contains extracted files
      final extractedEntities = tempDir.listSync(recursive: true).whereType<File>().toList();
      expect(extractedEntities, isNotEmpty, reason: 'Unzipped directory should contain files');

      // Basic sanity check: re-open one of the extracted files to verify it is readable
      final sampleFile = extractedEntities.first;
      final sampleBytes = await sampleFile.readAsBytes();
      expect(sampleBytes.length, greaterThan(0), reason: 'Sample extracted file should contain data');
    });

    test('unzipAbsolute supports cancellation for large files', () async {
      final zipFile = File('test/Spain-Portugal.zip');
      expect(await zipFile.exists(), isTrue, reason: 'Spain-Portugal.zip should exist in test folder');

      final cancelToken = CancelToken();

      int progressCalls = 0;

      Future<void> unzipFuture = unzipService.unzipAbsolute(
        zipFile.path,
        tempDir.path,
        onProgress: (int extractedFiles, int totalFiles, String currentFile) {
          progressCalls++;
          if (extractedFiles > 0) {
            cancelToken.cancel('Test cancellation');
          }
        },
        cancelToken: cancelToken,
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        cancelToken.cancel("stop");
      });

      await expectLater(unzipFuture, throwsA(isA<Exception>()));

      // Ensure the progress callback was called at least once before cancellation
      expect(progressCalls, greaterThan(0));
    }, skip: true);
  });
}
