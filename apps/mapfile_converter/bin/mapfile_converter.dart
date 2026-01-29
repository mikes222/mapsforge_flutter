import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:mapfile_converter/modifiers/custom_osm_primitive_modifier.dart';
import 'package:mapfile_converter/modifiers/default_osm_primitive_converter.dart';
import 'package:mapfile_converter/modifiers/holder_collection_file_implementation.dart';
import 'package:mapfile_converter/runner/pbf_convert.dart';
import 'package:mapfile_converter/runner/pbf_statistics.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

void main(List<String> arguments) async {
  _initLogging();

  var runner = CommandRunner("mapfile_converter", "Mapfile converter");
  runner.addCommand(ConvertCommand());
  runner.addCommand(StatisticsCommand());
  try {
    await runner.run(arguments);
  } on UsageException catch (error) {
    print(error);
    exit(255);
  }
  exit(0);
}

//////////////////////////////////////////////////////////////////////////////

void _initLogging() {
  // Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  Logger.root.level = Level.FINEST;
}

//////////////////////////////////////////////////////////////////////////////

class StatisticsCommand extends Command {
  static final _log = Logger('StatisticsCommand');

  @override
  String get description => "Prints statistical information about the given pbf file";

  @override
  String get name => "statistics";

  StatisticsCommand() {
    argParser.addOption("rendertheme", abbr: "r", help: "Render theme filename for filtering tags", mandatory: false);
    argParser.addOption("sourcefile", abbr: "s", help: "Source filename (PBF file)", mandatory: true);
    argParser.addOption("find", abbr: "f", help: "Find items with the given tag", mandatory: false);
    argParser.addOption("spillover", abbr: "p", defaultsTo: "1000000", help: "Number of items in memory before spillover to filesystem starts");
  }

  @override
  Future<void> run() async {
    _log.info("Calculating, please wait...");
    int spillover = int.parse(argResults!.option("spillover")!);

    DefaultOsmPrimitiveConverter converter = DefaultOsmPrimitiveConverter();

    if (argResults!.option("rendertheme") != null) {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile(argResults!.option("rendertheme")!);
      RuleAnalyzer ruleAnalyzer = RuleAnalyzer();
      for (Rule rule in renderTheme.rulesList) {
        ruleAnalyzer.apply(rule);
      }

      converter = CustomOsmPrimitiveConverter(
        allowedNodeTags: ruleAnalyzer.nodeValueinfos(),
        allowedWayTags: ruleAnalyzer.wayValueinfos(),
        negativeNodeTags: ruleAnalyzer.nodeNegativeValueinfos(),
        negativeWayTags: ruleAnalyzer.wayNegativeValueinfos(),
        keys: ruleAnalyzer.keys,
      );
    }
    if (spillover >= 10) HolderCollectionFactory().setImplementation(HolderCollectionFileImplementation(spillover));
    PbfStatistics pbfStatistics = PbfStatistics(converter, spillover);
    await pbfStatistics.readFile(argResults!.option("sourcefile")!);
    await pbfStatistics.analyze();
    pbfStatistics.statistics();
    await pbfStatistics.find(argResults!.option("find"));
  }
}

//////////////////////////////////////////////////////////////////////////////

class ConvertCommand extends Command {
  static final _log = Logger('ConvertCommand');

  @override
  String get description => "Converts a pbf file to mapfile";

  @override
  String get name => "convert";

  ConvertCommand() {
    argParser.addOption("rendertheme", abbr: "r", help: "Render theme filename", mandatory: false);
    argParser.addOption("sourcefiles", abbr: "s", help: "Source filenames (PBF or osm files), separated by #", mandatory: true);
    argParser.addOption("destinationfile", abbr: "d", help: "Destination filename (mapfile, PBF or osm)", mandatory: true);
    argParser.addOption(
      "zoomlevels",
      abbr: "z",
      help: "Comma-separated zoomlevels. The last one is the max zoomlevel, separator=#",
      defaultsTo: "0#5#9#13#16#20",
    );
    argParser.addOption(
      "boundary",
      abbr: "b",
      help: "Boundary in minLat,minLong,maxLat,maxLong order. If omitted the boundary of the source file is used, separator=#",
    );
    argParser.addFlag("debug", abbr: "f", defaultsTo: false, help: "Writes debug information in the mapfile");
    argParser.addOption("maxdeviation", abbr: "m", help: "Max deviation in pixels to simplify ways", defaultsTo: "5");
    argParser.addOption("maxgap", abbr: "g", help: "Max gap in meters to connect ways", defaultsTo: "200");
    argParser.addFlag("quiet", abbr: "q", defaultsTo: false, help: "Quiet mode, less output");
    argParser.addOption("isolates", abbr: "i", defaultsTo: "6", help: "Number of isolates to use, less isolates reduces performance but also memory usage");
    argParser.addOption("languagesPreference", abbr: "l", defaultsTo: "", help: "List of languages to use, separated by #");
    argParser.addOption("spillover", abbr: "p", defaultsTo: "1000000", help: "Number of items in memory before spillover to filesystem starts");
  }

  @override
  Future<void> run() async {
    List<String> zoomlevelsString = _split(argResults!.option("zoomlevels")!);
    List<int> zoomlevels = zoomlevelsString.map((toElement) => int.parse(toElement)).toList();

    BoundingBox? finalBoundingBox = _parseBoundingBoxFromCli();
    List<String> sourcefiles = _split(argResults!.option("sourcefiles")!);
    double maxGapMeter = double.parse(argResults!.option("maxgap")!);
    bool quiet = argResults!.flag("quiet");
    bool debug = argResults!.flag("debug");
    String destinationfile = argResults!.option("destinationfile")!;
    String languagePreference = argResults!.option("languagesPreference")!;
    double maxDeviation = double.parse(argResults!.option("maxdeviation")!);
    int isolates = int.parse(argResults!.option("isolates")!);
    int spillover = int.parse(argResults!.option("spillover")!);

    //_log.info("Converting, please wait...");

    PbfConvert convert = PbfConvert();
    await convert.convert(
      zoomlevels: zoomlevels,
      renderthemeFile: argResults!.option("rendertheme"),
      finalBoundingBox: finalBoundingBox,
      sourcefiles: sourcefiles,
      maxgap: maxGapMeter,
      quiet: quiet,
      debug: debug,
      destinationfile: destinationfile,
      languagePreference: languagePreference,
      maxDeviation: maxDeviation,
      isolates: isolates,
      spillover: spillover,
    );
    //_log.info("Process completed");
    exit(0);
  }

  BoundingBox? _parseBoundingBoxFromCli() {
    if (argResults!.option("boundary") != null) {
      List<String> coordinatesString = _split(argResults!.option("boundary")!);
      if (coordinatesString.length != 4) {
        _log.warning("Invalid boundary ${argResults!.option("boundary")}");
        return null;
      }
      List<double> coordinates = coordinatesString.map((toElement) => double.parse(toElement)).toList();
      return BoundingBox(coordinates[0], coordinates[1], coordinates[2], coordinates[3]);
    }
    return null;
  }

  List<String> _split(String value) {
    return value.split("#");
  }
}
