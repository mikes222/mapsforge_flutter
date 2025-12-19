import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder_collection.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/wayholder_collection.dart';

class BoundaryFilter {
  PoiWayCollections filter(PoiWayCollections poiWayCollections, BoundingBox tileBoundingBox) {
    PoiWayCollections poiWayInfos = PoiWayCollections();
    poiWayCollections.poiholderCollections.forEach((zoomlevel, poiinfo) {
      PoiholderCollection newPoiinfo = PoiholderCollection();
      for (Poiholder poiholder in poiinfo.poiholders) {
        if (tileBoundingBox.containsLatLong(poiholder.poi.position)) {
          newPoiinfo.addPoiholder(poiholder);
        }
      }
      poiWayInfos.poiholderCollections[zoomlevel] = newPoiinfo;
    });

    poiWayCollections.wayholderCollections.forEach((zoomlevel, wayinfo) {
      WayholderCollection newWayinfo = WayholderCollection();
      for (Wayholder wayholder in wayinfo.wayholders) {
        BoundingBox wayBoundingBox = wayholder.boundingBoxCached;
        if (tileBoundingBox.containsBoundingBox(wayBoundingBox)) {
          newWayinfo.addWayholder(wayholder);
        } else if (wayBoundingBox.containsBoundingBox(tileBoundingBox)) {
          newWayinfo.addWayholder(wayholder);
        } else if (tileBoundingBox.intersects(wayBoundingBox)) {
          newWayinfo.addWayholder(wayholder);
        }
      }
      poiWayInfos.wayholderCollections[zoomlevel] = newWayinfo;
    });
    return poiWayInfos;
  }
}
