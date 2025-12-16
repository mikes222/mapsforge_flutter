import 'package:mapfile_converter/osm/osm_wayholder.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class ZoomlevelWriter {
  final double maxDeviationSize;

  ZoomlevelWriter(this.maxDeviationSize);

  Future<SubfileCreator> writeZoomlevel(
    MapfileWriter mapfileWriter,
    MapHeaderInfo mapHeaderInfo,
    BoundingBox boundingBox,
    int minZoomlevel,
    int maxZoomlevel,
    Map<ZoomlevelRange, List<OsmWayholder>> ways,
    Map<ZoomlevelRange, List<PointOfInterest>> pois,
  ) async {
    SubfileCreator subfileCreator = SubfileCreator(
      mapHeaderInfo: mapHeaderInfo,
      baseZoomLevel: minZoomlevel,
      zoomlevelRange: ZoomlevelRange(minZoomlevel, maxZoomlevel),
    );
    await _fillSubfile(mapfileWriter.mapHeaderInfo.tilePixelSize, subfileCreator, pois, ways);
    mapfileWriter.subfileCreators.add(subfileCreator);
    return subfileCreator;
  }

  Future<void> _fillSubfile(
    int tilePixelSize,
    SubfileCreator subfileCreator,
    Map<ZoomlevelRange, List<PointOfInterest>> nodes,
    Map<ZoomlevelRange, List<OsmWayholder>> wayHolders,
  ) async {
    nodes.forEach((zoomlevelRange, nodelist) {
      if (subfileCreator.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
      if (subfileCreator.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
      subfileCreator.addPoidata(zoomlevelRange, nodelist);
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
      wayholderFutures.add(_isolate(subfileCreator, zoomlevelRange, wayholders, tilePixelSize));
    });
    await Future.wait(wayholderFutures);
  }

  Future<void> _isolate(SubfileCreator subfileCreator, ZoomlevelRange zoomlevelRange, List<Wayholder> wayholderlist, int tilePixelSize) async {
    List<Wayholder> wayholders = await IsolateSubfileFiller().prepareWays(
      subfileCreator.zoomlevelRange,
      zoomlevelRange,
      wayholderlist,
      tilePixelSize,
      maxDeviationSize,
    );
    subfileCreator.addWaydata(zoomlevelRange, wayholders);
  }
}
