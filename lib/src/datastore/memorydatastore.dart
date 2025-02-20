import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/datastore.dart';
import 'package:mapsforge_flutter/src/datastore/datastorereadresult.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/datastore/way.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

class MemoryDatastore extends Datastore {
  /// The read POIs.
  final List<PointOfInterest> pointOfInterests = [];

  /// The read ways.
  final List<Way> ways = [];

  @override
  void dispose() {
    pointOfInterests.clear();
    ways.clear();
  }

  @override
  Future<DatastoreReadResult> readLabels(Tile upperLeft, Tile lowerRight) {
    // TODO: implement readLabels
    throw UnimplementedError();
  }

  @override
  Future<DatastoreReadResult> readLabelsSingle(Tile tile) {
    // TODO: implement readLabelsSingle
    throw UnimplementedError();
  }

  @override
  Future<DatastoreReadResult> readMapData(Tile upperLeft, Tile lowerRight) {
    // TODO: implement readMapData
    throw UnimplementedError();
  }

  @override
  Future<DatastoreReadResult> readMapDataSingle(Tile tile) {
    List<PointOfInterest> poiResults = pointOfInterests
        .where((poi) => tile.getBoundingBox().containsLatLong(poi.position))
        .toList();
    List<Way> wayResults = [];
    for (Way way in ways) {
      if (tile.getBoundingBox().intersectsArea(way.latLongs)) {
        wayResults.add(way);
      }
    }
    return Future.value(
        DatastoreReadResult(pointOfInterests: poiResults, ways: wayResults));
  }

  @override
  Future<DatastoreReadResult> readPoiData(Tile upperLeft, Tile lowerRight) {
    // TODO: implement readPoiData
    throw UnimplementedError();
  }

  @override
  Future<DatastoreReadResult> readPoiDataSingle(Tile tile) {
    // TODO: implement readPoiDataSingle
    throw UnimplementedError();
  }

  @override
  Future<bool> supportsTile(Tile tile) {
    // you may want to show neighbouring tiles too in order to display labels.
    return Future.value(true);
    // Projection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
    // for (PointOfInterest poi in pointOfInterests) {
    //   if (projection.boundingBoxOfTile(tile).containsLatLong(poi.position)) return true;
    // }
    // for (Way way in ways) {
    //   for (List<ILatLong> list in way.latLongs) {
    //     for (ILatLong latLong in list) {
    //       if (projection.boundingBoxOfTile(tile).containsLatLong(latLong)) return true;
    //     }
    //   }
    // }
    // return false;
  }

  void addPoi(PointOfInterest poi) {
    pointOfInterests.add(poi);
  }

  void addWay(Way way) {
    ways.add(way);
  }

  @override
  String toString() {
    return 'MemoryDatastore{pointOfInterests: $pointOfInterests, ways: $ways}';
  }

  @override
  Future<BoundingBox> getBoundingBox() {
    return Future.value(Projection.BOUNDINGBOX_MAX);
  }
}
