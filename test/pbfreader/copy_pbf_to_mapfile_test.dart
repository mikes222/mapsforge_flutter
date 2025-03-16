import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/pbf.dart';
import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/readbufferfile.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/mapfile_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/subfile_creator.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/subfile_filler.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/rule.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/rule_analyzer.dart';
import 'package:mapsforge_flutter/src/utils/timing.dart';

import '../testassetbundle.dart';

main() async {
  final _log = new Logger('CopyPbfToMapfileTest');

  test("Read pbf file and convert it to mapfile", () async {
    _initLogging();

    Timing timing = Timing(log: _log);
    // prepare render theme
    DisplayModel displayModel = DisplayModel(maxZoomLevel: 20);
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();
    String content = await TestAssetBundle().loadString("lightrender.xml");
    renderThemeBuilder.parseXml(displayModel, content);
    RenderTheme renderTheme = renderThemeBuilder.build();
    RuleAnalyzer ruleAnalyzer = RuleAnalyzer();
    for (Rule rule in renderTheme.rulesList) {
      ruleAnalyzer.apply(rule);
    }

    // read and prepare pbf file
    ReadbufferSource readbufferSource = ReadbufferFile(TestAssetBundle()
        .correctFilename(
            "map_default_46_16.pbf")); //"map_default_46_16.pbf")); monaco-latest.osm.pbf
    int length = await readbufferSource.length();
    PbfAnalyzer pbfAnalyzer = PbfAnalyzer();
    pbfAnalyzer.converter = MyTagModifier(
        allowedNodeTags: ruleAnalyzer.nodeValueinfos(),
        allowedWayTags: ruleAnalyzer.wayValueinfos(),
        negativeNodeTags: ruleAnalyzer.nodeNegativeValueinfos(),
        negativeWayTags: ruleAnalyzer.wayNegativeValueinfos(),
        keys: ruleAnalyzer.keys);
    await pbfAnalyzer.analyze(readbufferSource, length);
    pbfAnalyzer.statistics();
    timing.lap(1000, "Analyzer completed");

    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<PointOfInterest>> nodes = {};
    Map<ZoomlevelRange, List<Wayholder>> ways = {};
    int noRangeNodes = 0;
    pbfAnalyzer.pois.forEach((pointOfInterest) {
      ZoomlevelRange? range =
          renderTheme.getZoomlevelRangeNode(pointOfInterest);
      if (range == null) {
        ++noRangeNodes;
        return;
      }
      if (nodes[range] == null) nodes[range] = [];
      nodes[range]!.add(pointOfInterest);
    });
    timing.lap(1000, "Processing pois completed");
    int noRangeWays = 0;
    pbfAnalyzer.ways.forEach((wayHolder) {
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeWay(wayHolder.way);
      if (range == null) {
        ++noRangeWays;
        return;
      }
      // if (wayHolder.way.hasTagValue("natural", "water"))
      //   print("found $range ${wayHolder.way}");
      if (ways[range] == null) ways[range] = [];
      ways[range]!.add(wayHolder);
    });
    timing.lap(1000, "Processing ways completed");
    pbfAnalyzer.waysMerged.forEach((wayHolder) {
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeWay(wayHolder.way);
      if (range == null) {
        ++noRangeWays;
        return;
      }
      if (ways[range] == null) ways[range] = [];
      ways[range]!.add(wayHolder);
    });
    timing.lap(1000, "Processing relations completed");
    _log.info(
        "Removed $noRangeNodes nodes because we would never draw them according to the render theme");
    _log.info(
        "Removed $noRangeWays ways because we would never draw them according to the render theme");

    nodes.forEach((zoomlevelRange, nodelist) {
      _log.info("ZoomlevelRange: $zoomlevelRange, nodes: ${nodelist.length}");
    });
    ways.forEach((zoomlevelRange, waylist) {
      _log.info("ZoomlevelRange: $zoomlevelRange, ways: ${waylist.length}");
    });

    // prepare the mapfile writer
    BoundingBox boundingBox = pbfAnalyzer.boundingBox!;
    pbfAnalyzer.clear();
    MapHeaderInfo mapHeaderInfo = MapHeaderInfo(
      boundingBox: boundingBox,
      debugFile: false,
      zoomlevelRange: const ZoomlevelRange.standard(),
      //languagesPreference: "ja,es",
    );
    MapfileWriter mapfileWriter =
        MapfileWriter(filename: "test.map", mapHeaderInfo: mapHeaderInfo);
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
    SubfileCreator subfileCreator = SubfileCreator(
        mapHeaderInfo: mapHeaderInfo,
        baseZoomLevel: 0,
        boundingBox: boundingBox,
        zoomlevelRange: const ZoomlevelRange(0, 8));
    await fillSubfile(mapfileWriter, subfileCreator, nodes, ways, _log);
    timing.lap(1000, "Subfile 1 completed");

    subfileCreator = SubfileCreator(
        mapHeaderInfo: mapHeaderInfo,
        baseZoomLevel: 9,
        boundingBox: boundingBox,
        zoomlevelRange: const ZoomlevelRange(9, 12));
    await fillSubfile(mapfileWriter, subfileCreator, nodes, ways, _log);
    timing.lap(1000, "Subfile 2 completed");

    subfileCreator = SubfileCreator(
        mapHeaderInfo: mapHeaderInfo,
        baseZoomLevel: 13,
        boundingBox: boundingBox,
        zoomlevelRange: const ZoomlevelRange(13, 15));
    await fillSubfile(mapfileWriter, subfileCreator, nodes, ways, _log);
    timing.lap(1000, "Subfile 3 completed");

    subfileCreator = SubfileCreator(
        mapHeaderInfo: mapHeaderInfo,
        baseZoomLevel: 16,
        boundingBox: boundingBox,
        zoomlevelRange: const ZoomlevelRange(16, 20));
    await fillSubfile(mapfileWriter, subfileCreator, nodes, ways, _log);
    timing.lap(1000, "Subfile 4 completed");

    // now start with writing the actual file
    await mapfileWriter.write();
    await mapfileWriter.close();

    timing.lap(1000, "Process completed");
  });
}

Future<void> fillSubfile(
    MapfileWriter mapfileWriter,
    SubfileCreator subfileCreator,
    Map<ZoomlevelRange, List<PointOfInterest>> nodes,
    Map<ZoomlevelRange, List<Wayholder>> wayHolders,
    _log) async {
  nodes.forEach((zoomlevelRange, nodelist) {
    if (subfileCreator.zoomlevelRange.zoomlevelMin >
        zoomlevelRange.zoomlevelMax) return;
    if (subfileCreator.zoomlevelRange.zoomlevelMax <
        zoomlevelRange.zoomlevelMin) return;
    subfileCreator.addPoidata(zoomlevelRange, nodelist);
  });
  // SubfileFiller subfileFiller =
  //     SubfileFiller(subfileCreator.zoomlevelRange, subfileCreator.boundingBox);
  List<Future> wayholderFutures = [];
  wayHolders
      .forEach((ZoomlevelRange zoomlevelRange, List<Wayholder> wayholderlist) {
    if (wayholderlist.isEmpty) return;
    wayholderFutures.add(_isolate(subfileCreator, zoomlevelRange, wayholderlist,
        mapfileWriter.mapHeaderInfo.tilePixelSize));
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

Future<void> _isolate(
    SubfileCreator subfileCreator,
    ZoomlevelRange zoomlevelRange,
    List<Wayholder> wayholderlist,
    int tilePixelSize) async {
  List<Wayholder> wayholders = await IsolateSubfileFiller().prepareWays(
      subfileCreator.zoomlevelRange,
      subfileCreator.boundingBox,
      zoomlevelRange,
      wayholderlist,
      tilePixelSize);
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

class MyTagModifier extends PbfAnalyzerConverter {
  final Map<String, ValueInfo> allowedNodeTags;

  final Map<String, ValueInfo> allowedWayTags;

  final Map<String, ValueInfo> negativeNodeTags;

  final Map<String, ValueInfo> negativeWayTags;

  final Set<String> keys;

  MyTagModifier(
      {required this.allowedNodeTags,
      required this.allowedWayTags,
      required this.negativeNodeTags,
      required this.negativeWayTags,
      required this.keys});

  @override
  void modifyNodeTags(OsmNode node, List<Tag> tags) {
    tags.removeWhere((test) {
      if (keys.contains(test.key)) return false;
      if (test.key == "name") return false;
      if (test.key == "loc_name") return false;
      if (test.key == "int_name") return false;
      if (test.key == "official_name") return false;
      if (test.key!.startsWith("name:")) return false;
      if (test.key!.startsWith("official_name:")) return false;
      ValueInfo? valueInfo = allowedNodeTags[test.key];
      if (valueInfo != null) {
        if (valueInfo.values.contains("*")) return false;
        if (valueInfo.values.contains(test.value)) return false;
      }
      valueInfo = negativeNodeTags[test.key];
      if (valueInfo != null) {
        return false;
        // if (valueInfo.values.contains("*")) return false;
        // if (valueInfo.values.contains(test.value)) return false;
      }
      return true;
    });
  }

  @override
  void modifyWayTags(OsmWay way, List<Tag> tags) {
    tags.removeWhere((test) {
      if (keys.contains(test.key)) return false;
      if (test.key == "name") return false;
      if (test.key == "loc_name") return false;
      if (test.key == "int_name") return false;
      if (test.key == "official_name") return false;
      if (test.key!.startsWith("name:")) return false;
      if (test.key!.startsWith("official_name:")) return false;
      ValueInfo? valueInfo = allowedWayTags[test.key];
      if (valueInfo != null) {
        if (valueInfo.values.contains("*")) return false;
        if (valueInfo.values.contains(test.value)) return false;
      }
      valueInfo = negativeWayTags[test.key];
      if (valueInfo != null) {
        return false;
        // if (valueInfo.values.contains("*")) return false;
        // if (valueInfo.values.contains(test.value)) return false;
      }
      return true;
    });
  }

  @override
  void modifyRelationTags(OsmRelation relation, List<Tag> tags) {
    tags.removeWhere((test) {
      if (keys.contains(test.key)) return false;
      if (test.key == "name") return false;
      if (test.key == "loc_name") return false;
      if (test.key == "int_name") return false;
      if (test.key == "official_name") return false;
      if (test.key!.startsWith("name:")) return false;
      if (test.key!.startsWith("official_name:")) return false;
      ValueInfo? valueInfo = allowedWayTags[test.key];
      if (valueInfo != null) {
        if (valueInfo.values.contains("*")) return false;
        if (valueInfo.values.contains(test.value)) return false;
      }
      valueInfo = negativeWayTags[test.key];
      if (valueInfo != null) {
        return false;
        // if (valueInfo.values.contains("*")) return false;
        // if (valueInfo.values.contains(test.value)) return false;
      }
      return true;
    });
  }
}
