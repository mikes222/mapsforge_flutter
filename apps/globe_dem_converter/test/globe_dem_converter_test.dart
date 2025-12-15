import 'dart:io';

import 'package:globe_dem_converter/src/globe_converter.dart';
import 'package:test/test.dart';

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

    final converter = GlobeDemConverter();

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
      resampleFactor: 1,
      dryRun: false,
    );

    final outFiles = outDir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.dem')).toList();

    // Extent is 1° x 1° with 0.5° steps => 2 x 2 tiles.
    expect(outFiles.length, 4);

    // Each tile is 0.5° x 0.5° => 60x60 samples, int16 => 7200 bytes.
    const expectedBytes = 60 * 60 * 2;
    for (final f in outFiles) {
      expect(f.lengthSync(), expectedBytes);
    }
  });

  test('convert with resampling factor 2 reduces output size', () async {
    final inputDir = Directory('test');
    expect(inputDir.existsSync(), isTrue);

    final c10g = File('${inputDir.path}${Platform.pathSeparator}c10g');
    expect(c10g.existsSync(), isTrue);

    final outDir = await Directory.systemTemp.createTemp('globe_dem_converter_test_r2_');
    addTearDown(() async {
      if (await outDir.exists()) {
        await outDir.delete(recursive: true);
      }
    });

    final converter = GlobeDemConverter();

    const startLat = 60.0;
    const endLat = 61.0;
    const startLon = 10.0;
    const endLon = 11.0;

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
      resampleFactor: 2,
      dryRun: false,
    );

    final outFiles = outDir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('_r2.dem')).toList();

    expect(outFiles.length, 4);

    // 0.5° tile at factor 2 => output cell size = 2/120°; 0.5° / (2/120) = 30 samples.
    const expectedBytes = 30 * 30 * 2;
    for (final f in outFiles) {
      expect(f.lengthSync(), expectedBytes);
    }
  });
}
