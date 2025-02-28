import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/pbf.dart';
import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffermemory.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/mapfile_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/subfile_creator.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/rule.dart';
import 'package:mapsforge_flutter/src/rendertheme/rule/rule_analyzer.dart';
import 'package:mapsforge_flutter/src/utils/reducehelper.dart';

import '../testassetbundle.dart';

main() async {
  test("Read pbf file from memory", () async {
    _initLogging();

    // prepare render theme
    DisplayModel displayModel = DisplayModel();
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();
    String content = await TestAssetBundle().loadString("lightrender.xml");
    renderThemeBuilder.parseXml(displayModel, content);
    RenderTheme renderTheme = renderThemeBuilder.build();
    RuleAnalyzer ruleAnalyzer = RuleAnalyzer();
    for (Rule rule in renderTheme.rulesList) {
      ruleAnalyzer.apply(rule);
    }

    // read and prepare pbf file
    ByteData byteData = await TestAssetBundle().load("monaco-latest.osm.pbf");
    Uint8List data = byteData.buffer.asUint8List();
    ReadbufferSource readbufferSource = ReadbufferMemory(data);
    PbfAnalyzer pbfAnalyzer = PbfAnalyzer();
    pbfAnalyzer.converter = MyTagModifier(
        allowedNodeTags: ruleAnalyzer.nodeValueinfos(),
        allowedWayTags: ruleAnalyzer.wayValueinfos(),
        negativeNodeTags: ruleAnalyzer.nodeNegativeValueinfos(),
        negativeWayTags: ruleAnalyzer.wayNegativeValueinfos(),
        keys: ruleAnalyzer.keys);
    await pbfAnalyzer.analyze(readbufferSource, data.length);
    //pbfAnalyzer.statistics();

    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<PointOfInterest>> nodes = {};
    Map<ZoomlevelRange, List<Way>> ways = {};
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
    int noRangeWays = 0;
    pbfAnalyzer.waysMerged.forEach((way) {
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeWay(way);
      if (range == null) {
        ++noRangeWays;
        return;
      }
      if (ways[range] == null) ways[range] = [];
      ways[range]!.add(way);
    });
    pbfAnalyzer.ways.forEach((way) {
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeWay(way);
      if (range == null) {
        ++noRangeWays;
        return;
      }
      if (ways[range] == null) ways[range] = [];
      ways[range]!.add(way);
    });
    print(
        "Removed $noRangeNodes nodes because we would never draw them according to the render theme");
    print(
        "Removed $noRangeWays ways because we would never draw them according to the render theme");

    nodes.forEach((zoomlevelRange, nodelist) {
      print("ZoomlevelRange: $zoomlevelRange, nodes: ${nodelist.length}");
    });
    ways.forEach((zoomlevelRange, waylist) {
      print("ZoomlevelRange: $zoomlevelRange, ways: ${waylist.length}");
    });

    // prepare the mapfile writer
    BoundingBox boundingBox = pbfAnalyzer.boundingBox!;
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
        baseZoomLevel: 5,
        boundingBox: boundingBox,
        zoomlevelRange: const ZoomlevelRange(0, 7));
    fillSubfile(mapfileWriter, subfileCreator, nodes, ways);

    subfileCreator = SubfileCreator(
        mapHeaderInfo: mapHeaderInfo,
        baseZoomLevel: 10,
        boundingBox: boundingBox,
        zoomlevelRange: const ZoomlevelRange(8, 11));
    fillSubfile(mapfileWriter, subfileCreator, nodes, ways);

    subfileCreator = SubfileCreator(
        mapHeaderInfo: mapHeaderInfo,
        baseZoomLevel: 14,
        boundingBox: boundingBox,
        zoomlevelRange: const ZoomlevelRange(12, 21));
    fillSubfile(mapfileWriter, subfileCreator, nodes, ways);

    // now start with writing the actual file
    mapfileWriter.write();
    await mapfileWriter.close();
  });
}

void fillSubfile(
    MapfileWriter mapfileWriter,
    SubfileCreator subfileCreator,
    Map<ZoomlevelRange, List<PointOfInterest>> nodes,
    Map<ZoomlevelRange, List<Way>> ways) {
  nodes.forEach((zoomlevelRange, nodelist) {
    subfileCreator.addPoidata(zoomlevelRange, nodelist, mapfileWriter.poiTags);
  });
  _SizeFilter sizeFilter =
      _SizeFilter(subfileCreator.zoomlevelRange.zoomlevelMax, 20);
  _SimplifyFilter simplifyFilter =
      _SimplifyFilter(subfileCreator.zoomlevelRange.zoomlevelMax, 10);
  ways.forEach((zoomlevelRange, waylist) {
    List<Way> ways = List.from(waylist);
    ways.removeWhere((test) => sizeFilter.shouldFilter(test));
    int count = waylist.length - ways.length;
    //if (count > 0) print("$count removed from ${waylist.length}");

    List<Way> ways2 = ways.map((way) => simplifyFilter.reduce(way)).toList();
    subfileCreator.addWaydata(zoomlevelRange, ways2, mapfileWriter.wayTags);
  });
  mapfileWriter.subfileCreators.add(subfileCreator);
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
      if (test.key!.startsWith("name:")) return false;
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
      if (test.key!.startsWith("name:")) return false;
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

//////////////////////////////////////////////////////////////////////////////

/// Filter ways by size. If the way would be too small in max zoom of the desired
/// subfile (hence maxZoomlevel) we do not want to include it at all.
class _SizeFilter {
  PixelProjection projection;

  double filterSize;

  _SizeFilter(int zoomlevel, this.filterSize)
      : projection = PixelProjection(zoomlevel);

  bool shouldFilter(Way way) {
    BoundingBox boundingBox = way.getBoundingBox();
    double x = projection.longitudeToPixelX(boundingBox.maxLongitude) -
        projection.longitudeToPixelX(boundingBox.minLongitude);
    if (x.abs() > filterSize) return false;
    double y = projection.latitudeToPixelY(boundingBox.maxLatitude) -
        projection.latitudeToPixelY(boundingBox.minLatitude);
    if (y.abs() > filterSize) return false;
    return true;
  }
}

//////////////////////////////////////////////////////////////////////////////

class _SimplifyFilter {
  PixelProjection projection;

  double maxDeviationPixel;

  _SimplifyFilter(int zoomlevel, this.maxDeviationPixel)
      : projection = PixelProjection(zoomlevel) {}

  Way reduce(Way way) {
    int oldCount = 0;
    int newCount = 0;
    double? maxDeviationLatLong;
    List<List<ILatLong>> newLatLongs = [];
    for (List<ILatLong> latLongs in way.latLongs) {
      if (latLongs.length <= 3) continue;
      maxDeviationLatLong ??= projection.longitudeDiffPerPixel(
          latLongs.first.longitude, maxDeviationPixel);
      oldCount += latLongs.length;
      List<ILatLong> res1 =
          ReduceHelper.reduceLatLong(latLongs, maxDeviationLatLong);
      newCount += res1.length;
      newLatLongs.add(res1);
    }
    //print("Way ${way.tags} reduced from $oldCount to $newCount");
    if (newCount >= 3 && newCount / oldCount < 0.8) {
      // at most 80% of the previous nodes
      return Way(way.layer, way.tags, newLatLongs, way.labelPosition);
    }
    return way;
  }
}
