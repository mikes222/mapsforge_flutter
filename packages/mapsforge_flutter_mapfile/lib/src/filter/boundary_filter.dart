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

  /// Removes ways and pois which are not needed anymore. We remember the first tile and since the tiles comes in order we can remove everything
  /// which is contained in the boundary referenced by the first tile and the most current one. Do this just once in a while.
  void remove(PoiWayCollections poiWayCollections, BoundingBox tileBoundingBox) {
    int poicountBefore = poiWayCollections.poiholderCollections.values.fold(0, (idx, combine) => idx + combine.poiholders.length);
    poiWayCollections.poiholderCollections.forEach((zoomlevel, poiinfo) {
      for (Poiholder poiholder in List.from(poiinfo.poiholders)) {
        if (tileBoundingBox.containsLatLong(poiholder.poi.position)) {
          poiinfo.poiholders.remove(poiholder);
        }
      }
    });
    int poicountAfter = poiWayCollections.poiholderCollections.values.fold(0, (idx, combine) => idx + combine.poiholders.length);
    int waycountBefore = poiWayCollections.wayholderCollections.values.fold(0, (idx, combine) => idx + combine.wayholders.length);
    poiWayCollections.wayholderCollections.forEach((zoomlevel, wayinfo) {
      for (Wayholder wayholder in List.from(wayinfo.wayholders)) {
        BoundingBox wayBoundingBox = wayholder.boundingBoxCached;
        if (tileBoundingBox.containsBoundingBox(wayBoundingBox)) {
          wayinfo.wayholders.remove(wayholder);
        }
      }
    });
    int waycountAfter = poiWayCollections.wayholderCollections.values.fold(0, (idx, combine) => idx + combine.wayholders.length);
  }
}
