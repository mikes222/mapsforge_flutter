import 'dart:io';

import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'package:globe_dem_converter/src/globe_converter.dart';

void main() {
  test('convert a small extent from C10G into 0.5x0.5 degree tiles', () async {
    final inputDir = Directory('test');
    expect(inputDir.existsSync(), isTrue);

    // Ensure test data is present.
    final c10g = File('${inputDir.path}${Platform.pathSeparator}c10g');
    expect(c10g.existsSync(), isTrue);

    final outDir = await Directory.systemTemp.createTemp('globe_dem_converter_test_');
    addTearDown(() async {
      if (await outDir.exists()) {
        await outDir.delete(recursive: true);
      }
    });

    final converter = GlobeDemConverter(log: Logger('test'));

    // C10G bounds: lat 50..90, lon 0..90.
    // Choose an extent fully inside.
    const startLat = 60.0;
    const endLat = 61.0;
    const startLon = 10.0;
    const endLon = 11.0;

    // 0.5 degrees corresponds to 60 samples at 1/120°.
    const tileWidthDeg = 0.5;
    const tileHeightDeg = 0.5;

    await converter.convert(
      inputDir: inputDir,
      outputDir: outDir,
      tileWidthDeg: tileWidthDeg,
      tileHeightDeg: tileHeightDeg,
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      dryRun: false,
    );

    final outFiles = outDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.bin'))
        .toList();

    // Extent is 1° x 1° with 0.5° steps => 2 x 2 tiles.
    expect(outFiles.length, 4);

    // Each tile is 0.5° x 0.5° => 60x60 samples, int16 => 7200 bytes.
    const expectedBytes = 60 * 60 * 2;
    for (final f in outFiles) {
      expect(f.lengthSync(), expectedBytes);
    }
  });
}
