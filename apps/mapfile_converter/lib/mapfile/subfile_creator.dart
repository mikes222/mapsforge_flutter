import 'package:mapfile_converter/modifiers/poiholder_file_collection.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

import '../modifiers/wayholder_file_collection.dart';

class SubfileCreator {
  final double maxDeviationSize;

  SubfileCreator(this.maxDeviationSize);

  Future<Subfile> createSubfile(
    MapHeaderInfo mapHeaderInfo,
    int minZoomlevel,
    int maxZoomlevel,
    Map<ZoomlevelRange, IWayholderCollection> ways,
    Map<ZoomlevelRange, IPoiholderCollection> pois,
  ) async {
    PoiWayCollections poiWayCollections = PoiWayCollections();
    for (int zoomlevel = minZoomlevel; zoomlevel <= maxZoomlevel; ++zoomlevel) {
      poiWayCollections.poiholderCollections[zoomlevel] = PoiholderFileCollection(
        filename: "subfile_nodes_${zoomlevel}_${DateTime.timestamp().millisecondsSinceEpoch}.tmp",
        spillBatchSize: 10000,
      );
      poiWayCollections.wayholderCollections[zoomlevel] = WayholderFileCollection(
        filename: "subfile_ways_${zoomlevel}_${DateTime.timestamp().millisecondsSinceEpoch}.tmp",
      );
    }

    Subfile subfile = Subfile(
      mapHeaderInfo: mapHeaderInfo,
      baseZoomLevel: minZoomlevel,
      zoomlevelRange: ZoomlevelRange(minZoomlevel, maxZoomlevel),
      poiWayCollections: poiWayCollections,
    );
    await _fillSubfile(mapHeaderInfo.tilePixelSize, subfile, pois, ways, mapHeaderInfo.boundingBox);
    return subfile;
  }

  Future<void> _fillSubfile(
    int tilePixelSize,
    Subfile subfile,
    Map<ZoomlevelRange, IPoiholderCollection> nodes,
    Map<ZoomlevelRange, IWayholderCollection> wayHolders,
    BoundingBox boundingBox,
  ) async {
    for (var entry in nodes.entries) {
      ZoomlevelRange zoomlevelRange = entry.key;
      IPoiholderCollection poiholderCollection = entry.value;
      if (subfile.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) continue;
      if (subfile.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) continue;
      subfile.addPoidata(zoomlevelRange, await poiholderCollection.getAll());
    }
    ISubfileFiller subfileFiller = await IsolateSubfileFiller.create(
      subfileZoomlevelRange: subfile.zoomlevelRange,
      boundingBox: boundingBox,
      maxDeviation: maxDeviationSize,
    );
    //    ISubfileFiller subfileFiller = SubfileFiller(subfile.zoomlevelRange, maxDeviationSize, boundingBox);
    List<Future> wayholderFutures = [];
    for (var entry in wayHolders.entries) {
      ZoomlevelRange zoomlevelRange = entry.key;
      IWayholderCollection wayholderlist = entry.value;
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

  Future<void> _isolate(Subfile subfile, ZoomlevelRange zoomlevelRange, IWayholderCollection wayholderlist, ISubfileFiller subfileFiller) async {
    // we create deep clones of wayholders because of isolates. This prevents problems later when reducing waypoints for different zoomlevels.
    // Do NOT remove the isolate code without further examination!
    List<Wayholder> wayholders = await subfileFiller.prepareWays(wayholderlist);
    //SubfileFiller(subfile.zoomlevelRange, maxDeviationSize, boundingBox).prepareWays(wayholderlist);
    subfile.addWaydata(zoomlevelRange, wayholders);
  }
}
