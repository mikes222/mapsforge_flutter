import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/special.dart';

class ZoomlevelWriter {
  final double maxDeviationSize;

  ZoomlevelWriter(this.maxDeviationSize);

  Future<SubfileCreator> writeZoomlevel(
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
    await _fillSubfile(mapfileWriter.mapHeaderInfo.tilePixelSize, subfileCreator, pois, ways);
    mapfileWriter.subfileCreators.add(subfileCreator);
    return subfileCreator;
  }

  Future<void> _fillSubfile(
    int tilePixelSize,
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
      wayholderFutures.add(_isolate(subfileCreator, zoomlevelRange, wayholderlist, tilePixelSize));
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
