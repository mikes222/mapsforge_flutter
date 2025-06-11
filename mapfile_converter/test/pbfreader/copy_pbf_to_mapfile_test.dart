import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapfile_converter/modifiers/pbf_analyzer.dart';
import 'package:mapfile_converter/modifiers/rendertheme_filter.dart';
import 'package:mapfile_converter/rule_reader.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/readbufferfile.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/mapfile_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/subfile_creator.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/subfile_filler.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';
import 'package:mapsforge_flutter/src/utils/timing.dart';

import '../testassetbundle.dart';

Future<void> main() async {
  final _log = Logger('CopyPbfToMapfileTest');

  test("Read pbf file and convert it to mapfile", () async {
    _initLogging();

    Timing timing = Timing(log: _log);

    RuleReader ruleReader = RuleReader();
    String content = await TestAssetBundle().loadString("lightrender.xml");
    final (ruleAnalyzer, renderTheme) = await ruleReader.readSource(content);

    ReadbufferSource readbufferSource = ReadbufferFile(
      TestAssetBundle().correctFilename("map_default_46_16.pbf"),
    ); //"map_default_46_16.pbf")); monaco-latest.osm.pbf
    PbfAnalyzer pbfAnalyzer = await PbfAnalyzer.readSource(readbufferSource, ruleAnalyzer);
    pbfAnalyzer.statistics();

    RenderthemeFilter simplifier = RenderthemeFilter();
    Map<ZoomlevelRange, List<PointOfInterest>> pois = simplifier.filterNodes(pbfAnalyzer.pois, renderTheme);
    Map<ZoomlevelRange, List<Wayholder>> ways = simplifier.filterWays(
      await pbfAnalyzer.ways
        ..addAll(pbfAnalyzer.waysMerged),
      renderTheme,
    );
    // prepare render theme

    // prepare the mapfile writer
    BoundingBox boundingBox = pbfAnalyzer.boundingBox!;
    pbfAnalyzer.clear();
    MapHeaderInfo mapHeaderInfo = MapHeaderInfo(
      boundingBox: boundingBox,
      debugFile: false,
      zoomlevelRange: const ZoomlevelRange.standard(),
      //languagesPreference: "ja,es",
    );
    MapfileWriter mapfileWriter = MapfileWriter(filename: "test.map", mapHeaderInfo: mapHeaderInfo);
    // baseZoomLevel: 5,
    // zoomLevelMax: 7,
    // zoomLevelMin: 0,

    // baseZoomLevel: 10,
    // zoomLevelMax: 11,
    // zoomLevelMin: 8,

    // baseZoomLevel: 14,
    // zoomLevelMax: 21,
    // zoomLevelMin: 12,

    // write the subfiles
    SubfileCreator subfileCreator = SubfileCreator(mapHeaderInfo: mapHeaderInfo, baseZoomLevel: 0, zoomlevelRange: const ZoomlevelRange(0, 8));
    await fillSubfile(mapfileWriter, subfileCreator, pois, ways, _log);
    timing.lap(1000, "Subfile 1 completed");

    subfileCreator = SubfileCreator(mapHeaderInfo: mapHeaderInfo, baseZoomLevel: 9, zoomlevelRange: const ZoomlevelRange(9, 12));
    await fillSubfile(mapfileWriter, subfileCreator, pois, ways, _log);
    timing.lap(1000, "Subfile 2 completed");

    subfileCreator = SubfileCreator(mapHeaderInfo: mapHeaderInfo, baseZoomLevel: 13, zoomlevelRange: const ZoomlevelRange(13, 15));
    await fillSubfile(mapfileWriter, subfileCreator, pois, ways, _log);
    timing.lap(1000, "Subfile 3 completed");

    subfileCreator = SubfileCreator(mapHeaderInfo: mapHeaderInfo, baseZoomLevel: 16, zoomlevelRange: const ZoomlevelRange(16, 20));
    await fillSubfile(mapfileWriter, subfileCreator, pois, ways, _log);
    timing.lap(1000, "Subfile 4 completed");

    // now start with writing the actual file
    await mapfileWriter.write(5, 6);
    await mapfileWriter.close();

    timing.done(1000, "Process completed");
  });
}

Future<void> fillSubfile(
  MapfileWriter mapfileWriter,
  SubfileCreator subfileCreator,
  Map<ZoomlevelRange, List<PointOfInterest>> nodes,
  Map<ZoomlevelRange, List<Wayholder>> wayHolders,
  _log,
) async {
  nodes.forEach((zoomlevelRange, nodelist) {
    if (subfileCreator.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
    if (subfileCreator.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
    subfileCreator.addPoidata(zoomlevelRange, nodelist);
  });
  // SubfileFiller subfileFiller =
  //     SubfileFiller(subfileCreator.zoomlevelRange, subfileCreator.boundingBox);
  List<Future> wayholderFutures = [];
  wayHolders.forEach((ZoomlevelRange zoomlevelRange, List<Wayholder> wayholderlist) {
    if (wayholderlist.isEmpty) return;
    wayholderFutures.add(_isolate(subfileCreator, zoomlevelRange, wayholderlist, mapfileWriter.mapHeaderInfo.tilePixelSize));
    // List<Wayholder> wayholders = subfileFiller.prepareWays(
    //     subfileCreator.zoomlevelRange,
    //     zoomlevelRange,
    //     List.from(wayholderlist));
    //subfileCreator.addWaydata(zoomlevelRange, wayholders);
  });
  await Future.wait(wayholderFutures);
  _log.info("=== Subfile:");
  subfileCreator.statistics();
  mapfileWriter.subfileCreators.add(subfileCreator);
}

Future<void> _isolate(SubfileCreator subfileCreator, ZoomlevelRange zoomlevelRange, List<Wayholder> wayholderlist, int tilePixelSize) async {
  List<Wayholder> wayholders = await IsolateSubfileFiller().prepareWays(subfileCreator.zoomlevelRange, zoomlevelRange, wayholderlist, tilePixelSize);
  subfileCreator.addWaydata(zoomlevelRange, wayholders);
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
