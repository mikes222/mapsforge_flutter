import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

class RenderthemeFilter {
  final _log = Logger('RenderthemeFilter');

  RenderthemeFilter();

  Future<Map<ZoomlevelRange, IPoiholderCollection>> convertNodes(IPoiholderCollection poiholderCollection) async {
    ZoomlevelRange range = const ZoomlevelRange.standard();
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, IPoiholderCollection> nodes = {};
    IPoiholderCollection? bag = HolderCollectionFactory().createPoiholderCollection("renderthemefilter");
    nodes[range] = bag;
    await poiholderCollection.forEach((poiholder) {
      bag.add(poiholder);
    });
    return nodes;
  }

  Future<Map<ZoomlevelRange, IPoiholderCollection>> filterNodes(IPoiholderCollection poiholderCollection, Rendertheme renderTheme) async {
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, IPoiholderCollection> nodes = {};
    int noRangeNodes = 0;
    await poiholderCollection.forEach((poiholder) {
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeNode(poiholder.tagholderCollection);
      if (range == null) {
        ++noRangeNodes;
        return;
      }
      IPoiholderCollection? bag = nodes[range];
      if (bag == null) {
        // PoiholderCollection();
        bag = HolderCollectionFactory().createPoiholderCollection("renderthemefilter_${range.zoomlevelMin}_${range.zoomlevelMax}");
        nodes[range] = bag;
      }
      bag.add(poiholder);
    });
    if (noRangeNodes > 0) _log.info("Removed $noRangeNodes nodes because we would never draw them according to the render theme");
    return nodes;
  }

  Future<Map<ZoomlevelRange, IWayholderCollection>> convertWays(IWayholderCollection wayholderCollection) async {
    ZoomlevelRange range = const ZoomlevelRange.standard();
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, IWayholderCollection> result = {};
    IWayholderCollection? bag = result[range];
    if (bag == null) {
      bag = HolderCollectionFactory().createWayholderCollection("renderthemefilter");
      result[range] = bag;
    }
    await wayholderCollection.forEach((wayholder) {
      assert(wayholder.closedOutersIsNotEmpty() || wayholder.openOutersIsNotEmpty(), "way must have at least one outer $wayholder");
      bag!.add(wayholder);
    });
    return result;
  }

  Future<Map<ZoomlevelRange, IWayholderCollection>> filterWays(IWayholderCollection wayholderCollection, Rendertheme renderTheme) async {
    // apply each node/way to the rendertheme and find their min/max zoomlevel
    Map<ZoomlevelRange, IWayholderCollection> result = {};
    int noRangeWays = 0;
    // int time = DateTime.now().millisecondsSinceEpoch;
    // await wayholderCollection.forEach((poiholder) {});
    // _log.info("forEach needs ${DateTime.now().millisecondsSinceEpoch - time} milliseconds for ${wayholderCollection.length} ways");
    await wayholderCollection.forEach((wayholder) {
      assert(wayholder.closedOutersIsNotEmpty() || wayholder.openOutersIsNotEmpty(), "way must have at least one outer $wayholder");
      ZoomlevelRange? range = renderTheme.getZoomlevelRangeWay(
        wayholder.closedOutersIsNotEmpty() ? wayholder.closedOutersRead.first : wayholder.openOutersRead.first,
        wayholder.tagholderCollection,
      );
      if (range == null) {
        ++noRangeWays;
        return;
      }
      IWayholderCollection? bag = result[range];
      if (bag == null) {
        bag = HolderCollectionFactory().createWayholderCollection("renderthemefilter_${range.zoomlevelMin}_${range.zoomlevelMax}");
        //bag = WayholderCollection();
        result[range] = bag;
      }
      bag.add(wayholder);
    });
    if (noRangeWays > 0) _log.info("Removed $noRangeWays ways because we would never draw them according to the render theme");

    return result;
  }
}
