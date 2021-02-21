import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/datastore.dart';
import 'package:mapsforge_flutter/src/datastore/datastorereadresult.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/datastore/way.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

class MemoryDatastore extends Datastore {
  /// The read POIs.
  final List<PointOfInterest> pointOfInterests = List();

  /// The read ways.
  final List<Way> ways = List();

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
    MercatorProjectionImpl mercatorProjection = MercatorProjectionImpl(DisplayModel.DEFAULT_TILE_SIZE, 16);
    List poiResults = pointOfInterests.where((poi) => tile.getBoundingBox(mercatorProjection).containsLatLong(poi.position)).toList();
    List<Way> wayResults = List();
    for (Way way in ways) {
      if (tile.getBoundingBox(mercatorProjection).intersectsArea(way.latLongs)) {
        wayResults.add(way);
      }
    }
    return Future.value(DatastoreReadResult(pointOfInterests: poiResults, ways: wayResults));
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
  bool supportsTile(Tile tile) {
    MercatorProjectionImpl mercatorProjection = MercatorProjectionImpl(DisplayModel.DEFAULT_TILE_SIZE, 16);
    for (PointOfInterest poi in pointOfInterests) {
      if (tile.getBoundingBox(mercatorProjection).containsLatLong(poi.position)) return true;
    }
    for (Way way in ways) {
      for (List<ILatLong> list in way.latLongs) {
        for (ILatLong latLong in list) {
          if (tile.getBoundingBox(mercatorProjection).containsLatLong(latLong)) return true;
        }
      }
    }
    return false;
  }

  @override
  Future<void> init() {
    return null;
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
}
