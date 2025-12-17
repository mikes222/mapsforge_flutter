import 'package:logging/logging.dart';
import 'package:mapfile_converter/osm/osm_nodeholder.dart';
import 'package:mapfile_converter/osm/osm_wayholder.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

class RenderthemeFilter {
  final _log = Logger('RenderthemeFilter');

  RenderthemeFilter();

  Map<ZoomlevelRange, List<OsmNodeholder>> convertNodes(List<OsmNodeholder> osmNodes) {
    ZoomlevelRange range = const ZoomlevelRange.standard();
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<OsmNodeholder>> nodes = {};
    List<OsmNodeholder>? bag = [];
    nodes[range] = bag;
    bag.addAll(osmNodes);
    return nodes;
  }

  Map<ZoomlevelRange, List<OsmNodeholder>> filterNodes(List<OsmNodeholder> osmNodes, Rendertheme renderTheme) {
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<OsmNodeholder>> nodes = {};
    int noRangeNodes = 0;
    for (OsmNodeholder osmNode in osmNodes) {
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeNode(osmNode.tagCollection);
      if (range == null) {
        ++noRangeNodes;
        continue;
      }
      List<OsmNodeholder>? bag = nodes[range];
      if (bag == null) {
        bag = [];
        nodes[range] = bag;
      }
      bag.add(osmNode);
    }
    _log.info("Removed $noRangeNodes nodes because we would never draw them according to the render theme");
    return nodes;
  }

  Map<ZoomlevelRange, List<OsmWayholder>> convertWays(List<OsmWayholder> ways) {
    ZoomlevelRange range = const ZoomlevelRange.standard();
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<OsmWayholder>> result = {};
    List<OsmWayholder>? bag = result[range];
    if (bag == null) {
      bag = [];
      result[range] = bag;
    }
    for (var wayHolder in ways) {
      assert(wayHolder.closedOutersIsNotEmpty() || wayHolder.openOutersIsNotEmpty(), "way must have at least one outer $wayHolder");
      bag.add(wayHolder);
    }
    return result;
  }

  Map<ZoomlevelRange, List<OsmWayholder>> filterWays(List<OsmWayholder> ways, Rendertheme renderTheme) {
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<OsmWayholder>> result = {};
    int noRangeWays = 0;
    for (var wayHolder in ways) {
      assert(wayHolder.closedOutersIsNotEmpty() || wayHolder.openOutersIsNotEmpty(), "way must have at least one outer $wayHolder");
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeWay(
        wayHolder.closedOutersIsNotEmpty() ? wayHolder.closedOutersRead.first : wayHolder.openOutersRead.first,
        wayHolder.tagCollection,
      );
      if (range == null) {
        ++noRangeWays;
        continue;
      }
      List<OsmWayholder>? bag = result[range];
      if (bag == null) {
        bag = [];
        result[range] = bag;
      }
      bag.add(wayHolder);
    }
    _log.info("Removed $noRangeWays ways because we would never draw them according to the render theme");

    return result;
  }
}
