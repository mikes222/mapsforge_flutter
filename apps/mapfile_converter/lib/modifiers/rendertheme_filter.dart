import 'package:dart_rendertheme/rendertheme.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile.dart';

class RenderthemeFilter {
  final _log = Logger('RenderthemeFilter');

  Map<ZoomlevelRange, List<PointOfInterest>> convertNodes(List<PointOfInterest> pois) {
    ZoomlevelRange range = const ZoomlevelRange.standard();
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<PointOfInterest>> nodes = {};
    for (var pointOfInterest in pois) {
      List<PointOfInterest>? bag = nodes[range];
      if (bag == null) {
        bag = [];
        nodes[range] = bag;
      }
      bag.add(pointOfInterest);
    }
    return nodes;
  }

  Map<ZoomlevelRange, List<PointOfInterest>> filterNodes(List<PointOfInterest> pois, Rendertheme renderTheme) {
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<PointOfInterest>> nodes = {};
    int noRangeNodes = 0;
    for (var pointOfInterest in pois) {
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeNode(pointOfInterest);
      if (range == null) {
        ++noRangeNodes;
        continue;
      }
      List<PointOfInterest>? bag = nodes[range];
      if (bag == null) {
        bag = [];
        nodes[range] = bag;
      }
      bag.add(pointOfInterest);
    }
    _log.info("Removed $noRangeNodes nodes because we would never draw them according to the render theme");
    return nodes;
  }

  Map<ZoomlevelRange, List<Wayholder>> convertWays(List<Wayholder> ways) {
    ZoomlevelRange range = const ZoomlevelRange.standard();
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<Wayholder>> result = {};
    for (var wayHolder in ways) {
      assert(wayHolder.closedOutersRead.isNotEmpty || wayHolder.openOutersRead.isNotEmpty, "way must have at least one outer $wayHolder");
      List<Wayholder>? bag = result[range];
      if (bag == null) {
        bag = [];
        result[range] = bag;
      }
      bag.add(wayHolder);
    }
    return result;
  }

  Map<ZoomlevelRange, List<Wayholder>> filterWays(List<Wayholder> ways, Rendertheme renderTheme) {
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
