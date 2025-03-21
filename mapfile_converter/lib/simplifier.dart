import 'package:logging/logging.dart';
import 'package:mapfile_converter/pbfreader/pbf_analyzer.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';

class Simplifier {
  final _log = new Logger('Simplifier');

  Map<ZoomlevelRange, List<PointOfInterest>> simplifyNodes(PbfAnalyzer pbfAnalyzer, RenderTheme renderTheme) {
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<PointOfInterest>> nodes = {};
    int noRangeNodes = 0;
    pbfAnalyzer.pois.forEach((pointOfInterest) {
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeNode(pointOfInterest);
      if (range == null) {
        ++noRangeNodes;
        return;
      }
      if (nodes[range] == null) nodes[range] = [];
      nodes[range]!.add(pointOfInterest);
    });
    _log.info("Removed $noRangeNodes nodes because we would never draw them according to the render theme");
    return nodes;
  }

  Map<ZoomlevelRange, List<Wayholder>> simplifyWays(PbfAnalyzer pbfAnalyzer, RenderTheme renderTheme) {
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<Wayholder>> ways = {};
    int noRangeWays = 0;
    pbfAnalyzer.ways.forEach((wayHolder) {
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeWay(wayHolder.way);
      if (range == null) {
        ++noRangeWays;
        return;
      }
      if (ways[range] == null) ways[range] = [];
      ways[range]!.add(wayHolder);
    });
    pbfAnalyzer.waysMerged.forEach((wayHolder) {
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeWay(wayHolder.way);
      if (range == null) {
        ++noRangeWays;
        return;
      }
      if (ways[range] == null) ways[range] = [];
      ways[range]!.add(wayHolder);
    });
    _log.info("Removed $noRangeWays ways because we would never draw them according to the render theme");

    return ways;
  }
}
