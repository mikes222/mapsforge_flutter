import 'dart:collection';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:mapfile_converter/mapfile/zoomlevel_writer.dart';
import 'package:mapfile_converter/modifiers/pbf_analyzer.dart';
import 'package:mapfile_converter/modifiers/rendertheme_filter.dart';
import 'package:mapfile_converter/osm/osm_writer.dart';
import 'package:mapfile_converter/pbf/pbf_writer.dart';
import 'package:mapfile_converter/pbf_statistics.dart';
import 'package:mapfile_converter/rule_reader.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/special.dart';

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
  final _log = new Logger('StatisticsCommand');

  @override
  String get description => "Prints statistical information about the given pbf file";

  @override
  String get name => "statistics";

  StatisticsCommand() {
    argParser.addOption("sourcefile", abbr: "s", help: "Source filename (PBF file)", mandatory: true);
    argParser.addOption("find", abbr: "f", help: "Find items with the given tag", mandatory: false);
  }

  @override
  Future<void> run() async {
    _log.info("Calculating, please wait...");
    PbfStatistics pbfStatistics = await PbfStatistics.readFile(argResults!.option("sourcefile")!);
    pbfStatistics.statistics();
    pbfStatistics.find(argResults!.option("find"));
  }
}

//////////////////////////////////////////////////////////////////////////////

class ConvertCommand extends Command {
  final _log = new Logger('ConvertCommand');

  @override
  String get description => "Converts a pbf file to mapfile";

  @override
  String get name => "convert";

  ConvertCommand() {
    argParser.addOption("rendertheme", abbr: "r", defaultsTo: "rendertheme.xml", help: "Render theme filename");
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
  }

  @override
  Future<void> run() async {
    /// Read and analyze render theme
    List<String> zoomlevelsString = _split(argResults!.option("zoomlevels")!);
    List<int> zoomlevels = zoomlevelsString.map((toElement) => int.parse(toElement)).toList();
    RuleReader ruleReader = RuleReader();
    final (ruleAnalyzer, renderTheme) = await ruleReader.readFile(argResults!.option("rendertheme")!, maxZoomLevel: zoomlevels.last);

    BoundingBox? finalBoundingBox = _parseBoundingBoxFromCli();

    List<PointOfInterest> pois = [];
    List<Wayholder> ways = [];

    List<String> sourcefiles = _split(argResults!.option("sourcefiles")!);
    for (var sourcefile in sourcefiles) {
      _log.info("Reading $sourcefile, please wait...");
      if (sourcefile.toLowerCase().endsWith(".osm")) {
        PbfAnalyzer pbfAnalyzer = await PbfAnalyzer.readOsmFile(
          sourcefile,
          ruleAnalyzer,
          maxGapMeter: double.parse(argResults!.option("maxgap")!),
          finalBoundingBox: finalBoundingBox,
        );

        finalBoundingBox ??= pbfAnalyzer.boundingBox!;
        if (!argResults!.flag("quiet")) pbfAnalyzer.statistics();
        pois.addAll(pbfAnalyzer.pois);
        ways.addAll(await pbfAnalyzer.ways);
        ways.addAll(pbfAnalyzer.waysMerged);
        pbfAnalyzer.clear();
      } else {
        /// Read and analyze PBF file
        PbfAnalyzer pbfAnalyzer = await PbfAnalyzer.readFile(
          sourcefile,
          ruleAnalyzer,
          maxGapMeter: double.parse(argResults!.option("maxgap")!),
          finalBoundingBox: finalBoundingBox,
        );

        /// Now start exporting the data to a mapfile
        finalBoundingBox ??= pbfAnalyzer.boundingBox!;
        if (!argResults!.flag("quiet")) pbfAnalyzer.statistics();
        pois.addAll(pbfAnalyzer.pois);
        ways.addAll(await pbfAnalyzer.ways);
        ways.addAll(pbfAnalyzer.waysMerged);
        pbfAnalyzer.clear();
      }
    }

    /// Simplify the data: Remove small areas, simplify ways
    RenderthemeFilter renderthemeFilter = RenderthemeFilter();
    Map<ZoomlevelRange, List<PointOfInterest>> poiZoomlevels = renderthemeFilter.filterNodes(pois, renderTheme);
    Map<ZoomlevelRange, List<Wayholder>> wayZoomlevels = renderthemeFilter.filterWays(ways, renderTheme);
    pois.clear();
    ways.clear();

    _log.info("Writing ${argResults!.option("destinationfile")!}");
    if (argResults!.option("destinationfile")!.toLowerCase().endsWith(".osm")) {
      OsmWriter osmWriter = OsmWriter(argResults!.option("destinationfile")!, finalBoundingBox!);
      for (var pois2 in poiZoomlevels.values) {
        for (var poi in pois2) {
          osmWriter.writeNode(poi.position, poi.tags);
        }
      }
      poiZoomlevels.clear();
      for (var wayholders in wayZoomlevels.values) {
        for (var wayholder in wayholders) {
          osmWriter.writeWay(wayholder);
        }
      }
      wayZoomlevels.clear();
      await osmWriter.close();
    } else if (argResults!.option("destinationfile")!.toLowerCase().endsWith(".pbf")) {
      PbfWriter pbfWriter = PbfWriter(argResults!.option("destinationfile")!, finalBoundingBox!);
      for (var pois2 in poiZoomlevels.values) {
        for (var poi in pois2) {
          await pbfWriter.writeNode(poi.position, poi.tags);
        }
      }
      poiZoomlevels.clear();
      for (var wayholders in wayZoomlevels.values) {
        for (var wayholder in wayholders) {
          await pbfWriter.writeWay(wayholder);
        }
      }
      wayZoomlevels.clear();
      await pbfWriter.close();
    } else {
      poiZoomlevels.removeWhere((key, value) => key.zoomlevelMin > zoomlevels.last || key.zoomlevelMax < zoomlevels.first);
      wayZoomlevels.removeWhere((key, value) => key.zoomlevelMin > zoomlevels.last || key.zoomlevelMax < zoomlevels.first);
      if (!argResults!.flag("quiet")) {
        SplayTreeMap treeMap = SplayTreeMap.from(poiZoomlevels, (a, b) => a.zoomlevelMin.compareTo(b.zoomlevelMin));
        treeMap.forEach((zoomlevelRange, nodelist) {
          _log.info("Nodes: ZoomlevelRange: $zoomlevelRange, ${nodelist.length}");
        });
      }
      if (!argResults!.flag("quiet")) {
        SplayTreeMap treeMap = SplayTreeMap.from(wayZoomlevels, (a, b) => a.zoomlevelMin.compareTo(b.zoomlevelMin));
        treeMap.forEach((zoomlevelRange, waylist) {
          _log.info("Ways: ZoomlevelRange: $zoomlevelRange, ${waylist.length}");
        });
      }

      MapHeaderInfo mapHeaderInfo = MapHeaderInfo(
        boundingBox: finalBoundingBox!,
        debugFile: argResults!.flag("debug"),
        zoomlevelRange: ZoomlevelRange(zoomlevels.first, zoomlevels.last),
        languagesPreference: argResults!.option("languagesPreference")! == "" ? null : argResults!.option("languagesPreference")!,
      );
      MapfileWriter mapfileWriter = MapfileWriter(filename: argResults!.option("destinationfile")!, mapHeaderInfo: mapHeaderInfo);

      /// Create the zoomlevels in the mapfile
      int? previousZoomlevel;
      ZoomlevelWriter zoomlevelWriter = ZoomlevelWriter(double.parse(argResults!.option("maxdeviation")!));
      for (int zoomlevel in zoomlevels) {
        if (previousZoomlevel != null) {
          SubfileCreator subfileCreator = await zoomlevelWriter.writeZoomlevel(
            mapfileWriter,
            mapHeaderInfo,
            finalBoundingBox,
            previousZoomlevel,
            zoomlevel == zoomlevels.last ? zoomlevel : zoomlevel - 1,
            wayZoomlevels,
            poiZoomlevels,
          );
          if (!argResults!.flag("quiet")) subfileCreator.statistics();
        }
        previousZoomlevel = zoomlevel;
      }

      /// Write everything to the file and close the file
      await mapfileWriter.write(double.parse(argResults!.option("maxdeviation")!), int.parse(argResults!.option("isolates")!));
      await mapfileWriter.close();
    }
    _log.info("Process completed");
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
