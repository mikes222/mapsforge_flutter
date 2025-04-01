import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:logging/logging.dart';
import 'package:mapfile_converter/osm/osm_writer.dart';
import 'package:mapfile_converter/pbfreader/pbf_analyzer.dart';
import 'package:mapfile_converter/pbfreader/pbf_statistics.dart';
import 'package:mapfile_converter/rendertheme_filter.dart';
import 'package:mapfile_converter/rule_reader.dart';
import 'package:mapfile_converter/zoomlevel_writer.dart';
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
  }

  Future<void> run() async {
    _log.info("Calculating, please wait...");
    PbfStatistics pbfStatistics = await PbfStatistics.readFile(argResults!.option("sourcefile")!);
    pbfStatistics.statistics();
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
    argParser.addOption("sourcefile", abbr: "s", help: "Source filename (PBF file)", mandatory: true);
    argParser.addOption("destinationfile", abbr: "d", help: "Destination filename (mapfile or osm)", mandatory: true);
    argParser.addOption("zoomlevels", abbr: "z", help: "Comma-separated zoomlevels. The last one is the max zoomlevel", defaultsTo: "0,5,9,13,16,20");
    argParser.addOption("boundary", abbr: "b", help: "Boundary in minLat,minLong,maxLat,maxLong order. If omitted the boundary of the source file is used");
    argParser.addFlag("debug", abbr: "f", defaultsTo: false, help: "Writes debug information in the mapfile");
    argParser.addOption("maxdeviation", abbr: "m", help: "Max deviation in pixels to simplify ways", defaultsTo: "5");
    argParser.addOption("maxgap", abbr: "g", help: "Max gap in meters to connect ways", defaultsTo: "200");
  }

  Future<void> run() async {
    _log.info("Converting, please wait...");

    /// Read and analyze render theme
    RuleReader ruleReader = RuleReader();
    final (ruleAnalyzer, renderTheme) = await ruleReader.readFile(argResults!.option("rendertheme")!);

    /// Read and analyze PBF file
    PbfAnalyzer pbfAnalyzer = await PbfAnalyzer.readFile(
      argResults!.option("sourcefile")!,
      ruleAnalyzer,
      maxGapMeter: double.parse(argResults!.option("maxgap")!),
    );
    pbfAnalyzer.statistics();

    /// Now start exporting the data to a mapfile
    BoundingBox boundingBox = pbfAnalyzer.boundingBox!;
    if (argResults!.option("boundary") != null) {
      List<String> coordinatesString = argResults!.option("boundary")!.split(",");
      if (coordinatesString.length != 4) {
        coordinatesString = argResults!.option("boundary")!.split("_");
      }
      if (coordinatesString.length != 4) {
        _log.info("Invalid boundary ${argResults!.option("boundary")}");
        return;
      }
      List<double> coordinates = coordinatesString.map((toElement) => double.parse(toElement)).toList();
      boundingBox = BoundingBox(coordinates[0], coordinates[1], coordinates[2], coordinates[3]);
      // remove items which are outside of the given boundary
      int countPoi = pbfAnalyzer.pois.length;
      int countWay = pbfAnalyzer.ways.length;
      pbfAnalyzer.filterByBoundingBox(boundingBox);
      _log.info("Removed ${countPoi - pbfAnalyzer.pois.length} pois because they are out of boundary");
      _log.info("Removed ${countWay - pbfAnalyzer.ways.length} ways because they are out of boundary");
    }
    List<PointOfInterest> pois = pbfAnalyzer.pois;
    List<Wayholder> ways = pbfAnalyzer.ways;
    ways.addAll(pbfAnalyzer.waysMerged);
    pbfAnalyzer.clear();

    /// Simplify the data: Remove small areas, simplify ways
    RenderthemeFilter renderthemeFilter = RenderthemeFilter();
    Map<ZoomlevelRange, List<PointOfInterest>> poiZoomlevels = renderthemeFilter.filterNodes(pois, renderTheme);
    // pois.forEach((zoomlevelRange, nodelist) {
    //   _log.info("ZoomlevelRange: $zoomlevelRange, nodes: ${nodelist.length}");
    // });
    Map<ZoomlevelRange, List<Wayholder>> wayZoomlevels = renderthemeFilter.filterWays(ways, renderTheme);
    // ways.forEach((zoomlevelRange, waylist) {
    //   _log.info("ZoomlevelRange: $zoomlevelRange, ways: ${waylist.length}");
    // });

    if (argResults!.option("destinationfile")!.toLowerCase().endsWith(".osm")) {
      OsmWriter osmWriter = OsmWriter(argResults!.option("destinationfile")!, boundingBox);
      for (var pois2 in poiZoomlevels.values) {
        for (var poi in pois2) {
          osmWriter.writeNode(poi.position, poi.tags);
        }
      }
      for (var wayholders in wayZoomlevels.values) {
        for (var wayholder in wayholders) {
          osmWriter.writeWay(wayholder.way, wayholder.otherOuters);
        }
      }
      await osmWriter.close();
      _log.info("Process completed");
      return;
    }

    List<String> zoomlevelsString = argResults!.option("zoomlevels")!.split(",");
    if (zoomlevelsString.length < 3) {
      zoomlevelsString = argResults!.option("zoomlevels")!.split("_");
    }
    List<int> zoomlevels = zoomlevelsString.map((toElement) => int.parse(toElement)).toList();

    MapHeaderInfo mapHeaderInfo = MapHeaderInfo(
      boundingBox: boundingBox,
      debugFile: argResults!.flag("debug"),
      zoomlevelRange: ZoomlevelRange(zoomlevels.first, zoomlevels.last),
      //languagesPreference: "ja,es",
    );
    MapfileWriter mapfileWriter = MapfileWriter(filename: argResults!.option("destinationfile")!, mapHeaderInfo: mapHeaderInfo);

    /// Create the zoomlevels in the mapfile
    int? previousZoomlevel;
    ZoomlevelWriter zoomlevelWriter = ZoomlevelWriter(double.parse(argResults!.option("maxdeviation")!));
    for (int zoomlevel in zoomlevels) {
      if (previousZoomlevel != null) {
        await zoomlevelWriter.writeZoomlevel(
          mapfileWriter,
          mapHeaderInfo,
          boundingBox,
          previousZoomlevel,
          zoomlevel == zoomlevels.last ? zoomlevel : zoomlevel - 1,
          wayZoomlevels,
          poiZoomlevels,
        );
      }
      previousZoomlevel = zoomlevel;
    }

    /// Write everything to the file and close the file
    await mapfileWriter.write(double.parse(argResults!.option("maxdeviation")!));
    await mapfileWriter.close();
    _log.info("Process completed");
  }
}
