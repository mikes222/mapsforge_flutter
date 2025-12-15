import 'package:logging/logging.dart';
import 'package:mapfile_converter/modifiers/default_osm_primitive_converter.dart';
import 'package:mapfile_converter/osm/osm_data.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

class RenderthemeFilter {
  final _log = Logger('RenderthemeFilter');

  final DefaultOsmPrimitiveConverter converter;

  RenderthemeFilter({required this.converter});

  Map<ZoomlevelRange, List<PointOfInterest>> convertNodes(List<OsmNode> osmNodes) {
    ZoomlevelRange range = const ZoomlevelRange.standard();
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<PointOfInterest>> nodes = {};
    List<PointOfInterest>? bag = nodes[range];
    if (bag == null) {
      bag = [];
      nodes[range] = bag;
    }
    for (OsmNode osmNode in osmNodes) {
      PointOfInterest? pointOfInterest = converter.createNode(osmNode);
      if (pointOfInterest != null) bag.add(pointOfInterest);
    }
    return nodes;
  }

  Map<ZoomlevelRange, List<PointOfInterest>> filterNodes(List<OsmNode> osmNodes, Rendertheme renderTheme) {
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, List<PointOfInterest>> nodes = {};
    int noRangeNodes = 0;
    for (OsmNode osmNode in osmNodes) {
      PointOfInterest? pointOfInterest = converter.createNode(osmNode);
      if (pointOfInterest == null) continue;
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeNode(pointOfInterest.tags);
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
