import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class BoundaryFilter {
  // Returns a new collection with all poiWayCollections which are contained in the given tileBoundingBox.
  Future<PoiWayCollections> filter(PoiWayCollections poiWayCollections, BoundingBox tileBoundingBox) async {
    PoiWayCollections poiWayInfos = PoiWayCollections();
    for (var entry in poiWayCollections.poiholderCollections.entries) {
      int zoomlevel = entry.key;
      IPoiholderCollection poiholderCollection = entry.value;
      IPoiholderCollection newPoiholderCollection = HolderCollectionFactory().createPoiholderCollection("boundary_$zoomlevel");
      await poiholderCollection.forEach((poiholder) {
        if (tileBoundingBox.containsLatLong(poiholder.position)) {
          newPoiholderCollection.add(poiholder);
        }
      });
      poiWayInfos.poiholderCollections[zoomlevel] = newPoiholderCollection;
    }

    for (var entry in poiWayCollections.wayholderCollections.entries) {
      int zoomlevel = entry.key;
      IWayholderCollection wayholderCollection = entry.value;
      IWayholderCollection newWayholderCollection = HolderCollectionFactory().createWayholderCollection("boundary_$zoomlevel");
      await wayholderCollection.forEach((wayholder) {
        BoundingBox wayBoundingBox = wayholder.boundingBoxCached;
        if (tileBoundingBox.containsBoundingBox(wayBoundingBox)) {
          newWayholderCollection.add(wayholder);
        } else if (wayBoundingBox.containsBoundingBox(tileBoundingBox)) {
          newWayholderCollection.add(wayholder);
        } else if (tileBoundingBox.intersects(wayBoundingBox)) {
          newWayholderCollection.add(wayholder);
        }
      });
      poiWayInfos.wayholderCollections[zoomlevel] = newWayholderCollection;
    }
    return poiWayInfos;
  }

  /// Removes ways and pois which are not needed anymore. We remember the first tile and since the tiles comes in order we can remove everything
  /// which is contained in the boundary referenced by the first tile and the most current one. Do this just once in a while.
  Future<void> remove(PoiWayCollections poiWayCollections, BoundingBox tileBoundingBox) async {
    for (IPoiholderCollection poiholderCollection in poiWayCollections.poiholderCollections.values) {
      await poiholderCollection.removeWhere((poiholder) {
        if (tileBoundingBox.containsLatLong(poiholder.position)) return true;
        return false;
      });
    }
    for (IWayholderCollection wayholderCollection in poiWayCollections.wayholderCollections.values) {
      await wayholderCollection.removeWhere((wayholder) {
        BoundingBox wayBoundingBox = wayholder.boundingBoxCached;
        if (tileBoundingBox.containsBoundingBox(wayBoundingBox)) return true;
        return false;
      });
    }
  }
}
