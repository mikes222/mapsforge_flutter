import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import '../lib/src/globe_converter.dart';

class ConvertCommand extends Command {
  final _log = Logger('ConvertCommand');

  @override
  String get description => 'Converts NOAA GLOBE DEM tiles (A10G..P10G) into smaller raw int16 little-endian tiles aligned to a user-defined lat/lon grid.';

  @override
  String get name => 'convert';

  ConvertCommand() {
    argParser.addOption('input', abbr: 'i', help: 'Input directory containing uncompressed GLOBE tiles (A10G..P10G).', defaultsTo: ".");

    argParser.addOption('output', abbr: 'o', help: 'Output directory.', defaultsTo: 'output_globe_tiles');

    argParser.addOption('tileWidth', abbr: 'w', help: 'Output tile width in degrees longitude (double).', defaultsTo: "1");
    argParser.addOption('tileHeight', help: 'Output tile height in degrees latitude (double).', defaultsTo: "1");

    argParser.addOption('startLat', help: 'Output extent start latitude (minLat).', defaultsTo: "-90");
    argParser.addOption('startLon', help: 'Output extent start longitude (minLon).', defaultsTo: "-180");
    argParser.addOption('endLat', help: 'Output extent end latitude (maxLat).', defaultsTo: "90");
    argParser.addOption('endLon', help: 'Output extent end longitude (maxLon).', defaultsTo: "180");

    argParser.addOption(
      'resample',
      help: 'Resampling factor (1..100). Output grid cell size becomes resample*(1/120°). 1 keeps original resolution.',
      defaultsTo: '1',
    );

    argParser.addFlag('dryRun', defaultsTo: false, help: 'Print planned output tiles without writing files.');
  }

  @override
  Future<void> run() async {
    final inputDir = Directory(argResults!.option('input')!);
    final outputDir = Directory(argResults!.option('output')!);

    final tileWidthDeg = double.parse(argResults!.option('tileWidth')!);
    final tileHeightDeg = double.parse(argResults!.option('tileHeight')!);

    final startLat = double.parse(argResults!.option('startLat')!);
    final startLon = double.parse(argResults!.option('startLon')!);
    final endLat = double.parse(argResults!.option('endLat')!);
    final endLon = double.parse(argResults!.option('endLon')!);

    final resampleFactor = int.parse(argResults!.option('resample')!);
    if (resampleFactor < 1 || resampleFactor > 100) {
      throw UsageException('resample must be in range 1..100', usage);
    }

    if (startLat >= endLat) throw UsageException('startLat must be < endLat', usage);
    if (startLon >= endLon) throw UsageException('startLon must be < endLon', usage);

    final dryRun = argResults!.flag('dryRun');

    _log.info('Input : ${inputDir.path}');
    _log.info('Output: ${outputDir.path}');

    final converter = GlobeDemConverter();

    await converter.convert(
      inputDir: inputDir,
      outputDir: outputDir,
      tileWidthDeg: tileWidthDeg,
      tileHeightDeg: tileHeightDeg,
      startLat: startLat,
      startLon: startLon,
      endLat: endLat,
      endLon: endLon,
      resampleFactor: resampleFactor,
      dryRun: dryRun,
    );
  }
}
