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
      boundingBox: boundingBox,
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
    // SubfileFiller subfileFiller =
    //     SubfileFiller(subfileCreator.zoomlevelRange, subfileCreator.boundingBox);
    List<Future> wayholderFutures = [];
    wayHolders.forEach((ZoomlevelRange zoomlevelRange, List<Wayholder> wayholderlist) {
      if (wayholderlist.isEmpty) return;
      wayholderFutures.add(_isolate(subfileCreator, zoomlevelRange, wayholderlist, mapfileWriter.mapHeaderInfo.tilePixelSize));
      // List<Wayholder> wayholders = subfileFiller.prepareWays(
      //     subfileCreator.zoomlevelRange,
      //     zoomlevelRange,
      //     List.from(wayholderlist));
      //subfileCreator.addWaydata(zoomlevelRange, wayholders);
    });
    await Future.wait(wayholderFutures);
    subfileCreator.statistics();
    mapfileWriter.subfileCreators.add(subfileCreator);
  }

  Future<void> _isolate(SubfileCreator subfileCreator, ZoomlevelRange zoomlevelRange, List<Wayholder> wayholderlist, int tilePixelSize) async {
    List<Wayholder> wayholders = await IsolateSubfileFiller().prepareWays(
      subfileCreator.zoomlevelRange,
      subfileCreator.boundingBox,
      zoomlevelRange,
      wayholderlist,
      tilePixelSize,
      maxDeviationSize,
    );
    subfileCreator.addWaydata(zoomlevelRange, wayholders);
  }
}
