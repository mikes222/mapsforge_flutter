import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/special.dart';

class ZoomlevelWriter {
  final double maxDeviationSize;

  ZoomlevelWriter(this.maxDeviationSize);

  Future<void> writeZoomlevel(
    MapfileWriter mapfileWriter,
    MapHeaderInfo mapHeaderInfo,
    BoundingBox boundingBox,
    int minZoomlevel,
    int maxZoomlevel,
    Map<ZoomlevelRange, List<Wayholder>> ways,
    Map<ZoomlevelRange, List<PointOfInterest>> pois,
  ) async {
    SubfileCreator subfileCreator = SubfileCreator(
      mapHeaderInfo: mapHeaderInfo,
      baseZoomLevel: minZoomlevel,
      zoomlevelRange: ZoomlevelRange(minZoomlevel, maxZoomlevel),
    );
    await _fillSubfile(mapfileWriter, subfileCreator, pois, ways);
  }

  Future<void> _fillSubfile(
    MapfileWriter mapfileWriter,
    SubfileCreator subfileCreator,
    Map<ZoomlevelRange, List<PointOfInterest>> nodes,
    Map<ZoomlevelRange, List<Wayholder>> wayHolders,
  ) async {
    nodes.forEach((zoomlevelRange, nodelist) {
      if (subfileCreator.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
      if (subfileCreator.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
      subfileCreator.addPoidata(zoomlevelRange, nodelist);
    });
    List<Future> wayholderFutures = [];
    wayHolders.forEach((ZoomlevelRange zoomlevelRange, List<Wayholder> wayholderlist) {
      if (wayholderlist.isEmpty) return;
      if (subfileCreator.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
      if (subfileCreator.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
      wayholderFutures.add(_isolate(subfileCreator, zoomlevelRange, wayholderlist, mapfileWriter.mapHeaderInfo.tilePixelSize));
    });
    await Future.wait(wayholderFutures);
    subfileCreator.statistics();
    mapfileWriter.subfileCreators.add(subfileCreator);
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
