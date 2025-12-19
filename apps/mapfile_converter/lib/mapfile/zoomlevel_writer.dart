import 'package:mapfile_converter/osm/osm_nodeholder.dart';
import 'package:mapfile_converter/osm/osm_wayholder.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class ZoomlevelWriter {
  final double maxDeviationSize;

  ZoomlevelWriter(this.maxDeviationSize);

  Future<SubfileCreator> writeZoomlevel(
    MapfileWriter mapfileWriter,
    int minZoomlevel,
    int maxZoomlevel,
    Map<ZoomlevelRange, List<OsmWayholder>> ways,
    Map<ZoomlevelRange, List<OsmNodeholder>> pois,
  ) async {
    SubfileCreator subfileCreator = SubfileCreator(
      mapHeaderInfo: mapfileWriter.mapHeaderInfo,
      baseZoomLevel: minZoomlevel,
      zoomlevelRange: ZoomlevelRange(minZoomlevel, maxZoomlevel),
    );
    await _fillSubfile(mapfileWriter.mapHeaderInfo.tilePixelSize, subfileCreator, pois, ways, mapfileWriter.mapHeaderInfo.boundingBox);
    mapfileWriter.subfileCreators.add(subfileCreator);
    return subfileCreator;
  }

  Future<void> _fillSubfile(
    int tilePixelSize,
    SubfileCreator subfileCreator,
    Map<ZoomlevelRange, List<OsmNodeholder>> nodes,
    Map<ZoomlevelRange, List<OsmWayholder>> wayHolders,
    BoundingBox boundingBox,
  ) async {
    nodes.forEach((zoomlevelRange, nodelist) {
      if (subfileCreator.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
      if (subfileCreator.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
      List<PointOfInterest> pois = [];
      for (var osmNodeholder in nodelist) {
        pois.add(osmNodeholder.createPoi());
      }
      subfileCreator.addPoidata(zoomlevelRange, pois);
    });
    List<Future> wayholderFutures = [];
    wayHolders.forEach((ZoomlevelRange zoomlevelRange, List<OsmWayholder> wayholderlist) {
      if (wayholderlist.isEmpty) return;
      if (subfileCreator.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
      if (subfileCreator.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
      List<Wayholder> wayholders = [];
      for (var osmWayholder in wayholderlist) {
        Wayholder wayholder = osmWayholder.convertToWayholder();
        wayholders.add(wayholder);
      }
      wayholderFutures.add(_isolate(subfileCreator, zoomlevelRange, wayholders, tilePixelSize, boundingBox));
    });
    await Future.wait(wayholderFutures);
  }

  Future<void> _isolate(
    SubfileCreator subfileCreator,
    ZoomlevelRange zoomlevelRange,
    List<Wayholder> wayholderlist,
    int tilePixelSize,
    BoundingBox boundingBox,
  ) async {
    // we create deep clones of wayholders because of isolates. This prevents problems later when reducing waypoints for different zoomlevels.
    // Do NOT remove the isolate code without further examination!
    List<Wayholder> wayholders = await IsolateSubfileFiller().prepareWays(
      subfileCreator.zoomlevelRange,
      zoomlevelRange,
      wayholderlist,
      boundingBox,
      tilePixelSize,
      maxDeviationSize,
    );
    subfileCreator.addWaydata(zoomlevelRange, wayholders);
  }
}
