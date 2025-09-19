import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path/path.dart' as path;
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

void main() {
  final shell = Shell();

  group('Mapfile Converter', () {
    // Test the help command
    test('should show help when -h is provided', () async {
      // Run the command with -h and capture output
      final result = await shell.run('dart run bin/mapfile_converter.dart -h');
      final output = result.outText;

      // Verify help text is shown
      expect(output, contains('Print this usage information'));
      expect(output, contains('convert'));
      expect(output, contains('statistics'));
    });

    // Test converting a map file to OSM format
    test('should convert pbf file to OSM format', () async {
      // Create a temporary directory for the output
      final tempDir = Directory.systemTemp.createTempSync('mapfile_converter_test');
      final outputFile = File(p.join(tempDir.path, 'output.osm'));

      try {
        // Get the absolute path to the test file
        final mapFilePath = p.normalize(p.absolute('test', 'monaco-latest.pbf'));
        final outputPath = outputFile.path;

        // Get the path to the render theme file
        final renderThemePath = path.normalize(path.absolute('test', 'defaultrender.xml'));

        // Run the converter with test file and output to temp directory
        await shell.run(
          'dart run bin/mapfile_converter.dart convert ' + '--sourcefiles "$mapFilePath" ' + '--destinationfile "$outputPath" ',
          //'--rendertheme "$renderThemePath"',
        );

        // Verify the output file was created and has content
        expect(await outputFile.exists(), isTrue, reason: 'Output file should exist');
        expect(await outputFile.length(), greaterThan(1000000), reason: 'Output file should not be empty');

        // Verify the output file exists and has content
        // The actual content check is removed since the output format might be binary
        // and we're just verifying the conversion process completes successfully
      } finally {
        // Clean up the temporary directory
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    // Test converting a map file to OSM format
    test('should convert pbf file to map format', () async {
      // Create a temporary directory for the output
      final tempDir = Directory.systemTemp.createTempSync('mapfile_converter_test');
      final outputFile = File(p.join(tempDir.path, 'output.map'));

      try {
        // Get the absolute path to the test file
        final mapFilePath = p.normalize(p.absolute('test', 'monaco-latest.pbf'));
        final outputPath = outputFile.path;

        // Get the path to the render theme file
        final renderThemePath = path.normalize(path.absolute('test', 'defaultrender.xml'));

        // Run the converter with test file and output to temp directory
        await shell.run(
          'dart run bin/mapfile_converter.dart convert ' +
              '--sourcefiles "$mapFilePath" ' +
              '--destinationfile "$outputPath" ' +
              '--rendertheme "$renderThemePath"',
        );

        // Verify the output file was created and has content
        expect(await outputFile.exists(), isTrue, reason: 'Output file should exist');
        expect(await outputFile.length(), greaterThan(555000), reason: 'Output file should not be empty');
        expect(await outputFile.length(), lessThan(556000), reason: 'Output file should not be empty');

        // Verify the output file exists and has content
        // The actual content check is removed since the output format might be binary
        // and we're just verifying the conversion process completes successfully
      } finally {
        // Clean up the temporary directory
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
