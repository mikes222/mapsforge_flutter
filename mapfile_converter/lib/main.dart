import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:mapfile_converter/pbfreader/pbf_analyzer.dart';
import 'package:mapfile_converter/rule_reader.dart';
import 'package:mapfile_converter/simplifier.dart';
import 'package:mapfile_converter/zoomlevel_writer.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/special.dart';

void main(List<String> arguments) async {
  final _log = new Logger('main');
  _initLogging();

  var parser = ArgParser();
  parser.addOption("rendertheme", abbr: "r", defaultsTo: "rendertheme.xml", help: "Render theme filename");
  parser.addOption("sourcefile", abbr: "s", help: "Source filename (PBF file)", mandatory: true);
  parser.addOption("destinationfile", abbr: "d", help: "Destination filename (mapfile)", mandatory: true);
  parser.addOption("zoomlevels", abbr: "z", help: "Comma-separated zoomlevels. The last one is the max zoomlevel", defaultsTo: "0,5,9,13,16,20");
  parser.addOption("boundary", abbr: "b", help: "Boundary in minLat,minLong,maxLat,maxLong order. If omitted the boundary of the source file is used");
  parser.addFlag("debug", abbr: "f", defaultsTo: false, help: "Writes debug information in the mapfile");
  parser.addFlag("help", abbr: "h", help: "Prints this help message");

  var args = parser.parse(arguments);

  if (args.flag("help")) {
    _log.info(parser.usage);
    return;
  }

  /// Read and analyze render theme
  RuleReader ruleReader = RuleReader();
  final (ruleAnalyzer, renderTheme) = await ruleReader.readFile(args.option("rendertheme")!);

  /// Read and analyze PBF file
  PbfAnalyzer pbfAnalyzer = await PbfAnalyzer.readFile(args.option("sourcefile")!, ruleAnalyzer);
  pbfAnalyzer.statistics();

  /// Now start exporting the data to a mapfile
  BoundingBox boundingBox = pbfAnalyzer.boundingBox!;
  if (args.option("boundary") != null) {
    List<String> coordinatesString = args.option("boundary")!.split(",");
    if (coordinatesString.length != 4) {
      coordinatesString = args.option("boundary")!.split("_");
    }
    if (coordinatesString.length != 4) {
      _log.info("Invalid boundary ${args.option("boundary")}");
      _log.info(parser.usage);
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

  /// Simplify the data: Remove small areas, simplify ways
  Simplifier simplifier = Simplifier();
  Map<ZoomlevelRange, List<PointOfInterest>> pois = simplifier.simplifyNodes(pbfAnalyzer, renderTheme);
  // pois.forEach((zoomlevelRange, nodelist) {
  //   _log.info("ZoomlevelRange: $zoomlevelRange, nodes: ${nodelist.length}");
  // });
  Map<ZoomlevelRange, List<Wayholder>> ways = simplifier.simplifyWays(pbfAnalyzer, renderTheme);
  // ways.forEach((zoomlevelRange, waylist) {
  //   _log.info("ZoomlevelRange: $zoomlevelRange, ways: ${waylist.length}");
  // });
  pbfAnalyzer.clear();

  List<int> zoomlevels = args.option("zoomlevels")!.split(",").map((toElement) => int.parse(toElement)).toList();

  MapHeaderInfo mapHeaderInfo = MapHeaderInfo(
    boundingBox: boundingBox,
    debugFile: args.flag("debug"),
    zoomlevelRange: ZoomlevelRange(zoomlevels.first, zoomlevels.last),
    //languagesPreference: "ja,es",
  );
  MapfileWriter mapfileWriter = MapfileWriter(filename: args.option("destinationfile")!, mapHeaderInfo: mapHeaderInfo);

  /// Create the zoomlevels in the mapfile
  int? previousZoomlevel;
  ZoomlevelWriter zoomlevelWriter = ZoomlevelWriter();
  for (int zoomlevel in zoomlevels) {
    if (previousZoomlevel != null) {
      await zoomlevelWriter.writeZoomlevel(
        mapfileWriter,
        mapHeaderInfo,
        boundingBox,
        previousZoomlevel,
        zoomlevel == zoomlevels.last ? zoomlevel : zoomlevel - 1,
        ways,
        pois,
      );
    }
    previousZoomlevel = zoomlevel;
  }

  /// Write everything to the file and close the file
  await mapfileWriter.write();
  await mapfileWriter.close();
  _log.info("Process completed");
}

//////////////////////////////////////////////////////////////////////////////

void _initLogging() {
  // Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  Logger.root.level = Level.FINEST;
}
