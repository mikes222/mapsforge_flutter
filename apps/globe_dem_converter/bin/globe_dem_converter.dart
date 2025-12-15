import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';

import 'convert.dart';

void main(List<String> arguments) async {
  _initLogging();

  final runner = CommandRunner('globe_dem_converter', 'Convert GLOBE DEM tiles (A10G..P10G) into smaller lat/lon chunk tiles.');
  runner.addCommand(ConvertCommand());

  try {
    await runner.run(arguments);
  } on UsageException catch (error) {
    // ignore: avoid_print
    print(error);
    exit(255);
  }
  exit(0);
}

void _initLogging() {
  Logger.root.onRecord.listen((LogRecord r) {
    // ignore: avoid_print
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  Logger.root.level = Level.INFO;
}
