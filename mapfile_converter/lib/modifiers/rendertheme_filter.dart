import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/special.dart';

class RenderthemeFilter {
  final _log = new Logger('RenderthemeFilter');

  Map<ZoomlevelRange, List<PointOfInterest>> filterNodes(List<PointOfInterest> pois, RenderTheme renderTheme) {
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<PointOfInterest>> nodes = {};
    int noRangeNodes = 0;
    pois.forEach((pointOfInterest) {
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeNode(pointOfInterest);
      if (range == null) {
        ++noRangeNodes;
        return;
      }
      List<PointOfInterest>? bag = nodes[range];
      if (bag == null) {
        bag = [];
        nodes[range] = bag;
      }
      bag.add(pointOfInterest);
    });
    _log.info("Removed $noRangeNodes nodes because we would never draw them according to the render theme");
    return nodes;
  }

  Map<ZoomlevelRange, List<Wayholder>> filterWays(List<Wayholder> ways, RenderTheme renderTheme) {
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<Wayholder>> result = {};
    int noRangeWays = 0;
    for (var wayHolder in ways) {
      assert(wayHolder.closedOutersRead.isNotEmpty || wayHolder.openOutersRead.isNotEmpty, "way must have at least one outer $wayHolder");
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeWay(
        wayHolder.closedOutersRead.isNotEmpty ? wayHolder.closedOutersRead.first : wayHolder.openOutersRead.first,
        wayHolder.tags,
      );
      if (range == null) {
        ++noRangeWays;
        continue;
      }
      List<Wayholder>? bag = result[range];
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
