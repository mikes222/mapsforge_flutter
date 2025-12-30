import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class BoundaryFilter {
  // Returns a new collection with all poiWayCollections which are contained in the given tileBoundingBox.
  PoiWayCollections filter(PoiWayCollections poiWayCollections, BoundingBox tileBoundingBox) {
    PoiWayCollections poiWayInfos = PoiWayCollections();
    poiWayCollections.poiholderCollections.forEach((zoomlevel, poiholderCollection) {
      PoiholderCollection newPoiinfo = PoiholderCollection();
      for (Poiholder poiholder in poiholderCollection.poiholders) {
        if (tileBoundingBox.containsLatLong(poiholder.position)) {
          newPoiinfo.addPoiholder(poiholder);
        }
      }
      poiWayInfos.poiholderCollections[zoomlevel] = newPoiinfo;
    });

    poiWayCollections.wayholderCollections.forEach((zoomlevel, wayholderCollection) {
      WayholderCollection newWayinfo = WayholderCollection();
      for (Wayholder wayholder in wayholderCollection.wayholders) {
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
    poiWayCollections.poiholderCollections.forEach((zoomlevel, poiholderCollection) {
      for (Poiholder poiholder in List.from(poiholderCollection.poiholders)) {
        if (tileBoundingBox.containsLatLong(poiholder.position)) {
          poiholderCollection.poiholders.remove(poiholder);
        }
      }
    });
    poiWayCollections.wayholderCollections.forEach((zoomlevel, wayinfo) {
      for (Wayholder wayholder in List.from(wayinfo.wayholders)) {
        BoundingBox wayBoundingBox = wayholder.boundingBoxCached;
        if (tileBoundingBox.containsBoundingBox(wayBoundingBox)) {
          wayinfo.wayholders.remove(wayholder);
        }
      }
    });
  }
}
