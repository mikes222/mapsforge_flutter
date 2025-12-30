import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class SubfileCreator {
  final double maxDeviationSize;

  SubfileCreator(this.maxDeviationSize);

  Future<Subfile> createSubfile(
    MapHeaderInfo mapHeaderInfo,
    int minZoomlevel,
    int maxZoomlevel,
    Map<ZoomlevelRange, WayholderCollection> ways,
    Map<ZoomlevelRange, PoiholderCollection> pois,
  ) async {
    Subfile subfile = Subfile(mapHeaderInfo: mapHeaderInfo, baseZoomLevel: minZoomlevel, zoomlevelRange: ZoomlevelRange(minZoomlevel, maxZoomlevel));
    await _fillSubfile(mapHeaderInfo.tilePixelSize, subfile, pois, ways, mapHeaderInfo.boundingBox);
    return subfile;
  }

  Future<void> _fillSubfile(
    int tilePixelSize,
    Subfile subfile,
    Map<ZoomlevelRange, PoiholderCollection> nodes,
    Map<ZoomlevelRange, WayholderCollection> wayHolders,
    BoundingBox boundingBox,
  ) async {
    nodes.forEach((zoomlevelRange, PoiholderCollection poiholderList) {
      if (subfile.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
      if (subfile.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
      subfile.addPoidata(zoomlevelRange, poiholderList.poiholders);
    });
    ISubfileFiller subfileFiller = await IsolateSubfileFiller.create(
      subfileZoomlevelRange: subfile.zoomlevelRange,
      boundingBox: boundingBox,
      maxDeviation: maxDeviationSize,
    );
    //    ISubfileFiller subfileFiller = SubfileFiller(subfile.zoomlevelRange, maxDeviationSize, boundingBox);
    List<Future> wayholderFutures = [];
    for (var entry in wayHolders.entries) {
      ZoomlevelRange zoomlevelRange = entry.key;
      WayholderCollection wayholderlist = entry.value;
      if (wayholderlist.isEmpty) continue;
      if (subfile.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) continue;
      if (subfile.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) continue;
      //    print("create $zoomlevelRange with ${wayholderlist.count} ways for ${subfile.zoomlevelRange}");
      wayholderFutures.add(_isolate(subfile, zoomlevelRange, wayholderlist, subfileFiller));
      if (wayholderFutures.length >= 20) {
        await Future.wait(wayholderFutures);
        wayholderFutures.clear();
      }
    }
    await Future.wait(wayholderFutures);
  }

  Future<void> _isolate(Subfile subfile, ZoomlevelRange zoomlevelRange, WayholderCollection wayholderlist, ISubfileFiller subfileFiller) async {
    // we create deep clones of wayholders because of isolates. This prevents problems later when reducing waypoints for different zoomlevels.
    // Do NOT remove the isolate code without further examination!
    List<Wayholder> wayholders = await subfileFiller.prepareWays(
      wayholderlist,
    ); //SubfileFiller(subfile.zoomlevelRange, maxDeviationSize, boundingBox).prepareWays(wayholderlist);
    subfile.addWaydata(zoomlevelRange, wayholders);
  }
}
