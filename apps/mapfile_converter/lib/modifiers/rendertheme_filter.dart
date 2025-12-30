import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

class RenderthemeFilter {
  final _log = Logger('RenderthemeFilter');

  RenderthemeFilter();

  Map<ZoomlevelRange, PoiholderCollection> convertNodes(List<Poiholder> osmNodes) {
    ZoomlevelRange range = const ZoomlevelRange.standard();
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, PoiholderCollection> nodes = {};
    PoiholderCollection? bag = PoiholderCollection();
    nodes[range] = bag;
    bag.addAllPoiholder(osmNodes);
    return nodes;
  }

  Map<ZoomlevelRange, PoiholderCollection> filterNodes(List<Poiholder> osmNodes, Rendertheme renderTheme) {
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, PoiholderCollection> nodes = {};
    int noRangeNodes = 0;
    for (Poiholder poiholder in osmNodes) {
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeNode(poiholder.tagholderCollection);
      if (range == null) {
        ++noRangeNodes;
        continue;
      }
      PoiholderCollection? bag = nodes[range];
      if (bag == null) {
        bag = PoiholderCollection();
        nodes[range] = bag;
      }
      bag.addPoiholder(poiholder);
    }
    _log.info("Removed $noRangeNodes nodes because we would never draw them according to the render theme");
    return nodes;
  }

  Map<ZoomlevelRange, WayholderCollection> convertWays(List<Wayholder> ways) {
    ZoomlevelRange range = const ZoomlevelRange.standard();
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, WayholderCollection> result = {};
    WayholderCollection? bag = result[range];
    if (bag == null) {
      bag = WayholderCollection();
      result[range] = bag;
    }
    for (var wayHolder in ways) {
      assert(wayHolder.closedOutersIsNotEmpty() || wayHolder.openOutersIsNotEmpty(), "way must have at least one outer $wayHolder");
      bag.addWayholder(wayHolder);
    }
    return result;
  }

  Map<ZoomlevelRange, WayholderCollection> filterWays(List<Wayholder> ways, Rendertheme renderTheme) {
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, WayholderCollection> result = {};
    int noRangeWays = 0;
    for (var wayHolder in ways) {
      assert(wayHolder.closedOutersIsNotEmpty() || wayHolder.openOutersIsNotEmpty(), "way must have at least one outer $wayHolder");
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeWay(
        wayHolder.closedOutersIsNotEmpty() ? wayHolder.closedOutersRead.first : wayHolder.openOutersRead.first,
        wayHolder.tagholderCollection,
      );
      if (range == null) {
        ++noRangeWays;
        continue;
      }
      WayholderCollection? bag = result[range];
      if (bag == null) {
        bag = WayholderCollection();
        result[range] = bag;
      }
      bag.addWayholder(wayHolder);
    }
    _log.info("Removed $noRangeWays ways because we would never draw them according to the render theme");

    return result;
  }
}
