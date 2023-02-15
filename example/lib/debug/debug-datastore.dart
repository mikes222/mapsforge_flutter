import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/marker.dart';

class DebugDatastore extends MarkerByItemDataStore {
  final SymbolCache symbolCache;

  Tile? tile;

  DatastoreReadResult? readResult;

  final DisplayModel displayModel;

  DebugDatastore({required this.symbolCache, required this.displayModel}) {}

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> setInfos(Tile? tile, DatastoreReadResult? readResult) async {
    this.tile = tile;
    this.readResult = readResult;

    // result.ways.forEach((element) {
    //   print(element);
    // });

    clearMarkers();
    if (readResult == null) return;
    for (PointOfInterest poi in readResult.pointOfInterests) {
      //print(poi);
      Marker marker = await _createMarker(poi);
      addMarker(marker);
    }

    for (Way way in readResult.ways) {
      Marker marker = await _createWayMarker(way, false);
      addMarker(marker);
    }
    setRepaint();
  }

  Future<void> createWayMarker(Way way) async {
    clearMarkers();
    Marker marker = await _createWayMarker(way, true);
    addMarker(marker);
    setRepaint();
  }

  @override
  Future<void> retrieveMarkersFor(BoundingBox boundary, int zoomLevel) async {}

  Future<Marker> _createMarker(PointOfInterest poi) async {
    CircleMarker marker = CircleMarker(
      center: poi.position,
      item: poi,
      radius: 5,
      strokeWidth: 2,
      fillColor: 0x80eac71c,
      strokeColor: 0xffc2a726,
      displayModel: displayModel,
    );
    return marker;
  }

  Future<Marker> _createWayMarker(Way way, bool intense) async {
    if (LatLongUtils.isClosedWay(way.latLongs.first)) {
      PolygonMarker marker = PolygonMarker(
        item: way,
        strokeWidth: intense ? 10 : 2,
        fillColor: 0x10c8c623,
        strokeColor: 0x80c8c623, // yellowish
        displayModel: displayModel,
      );
      way.latLongs.first.forEach((element) {
        marker.addLatLong(element);
      });
      await marker.initResources(symbolCache);
      return marker;
    } else {
      PathMarker marker = PathMarker(
        item: way,
        strokeWidth: intense ? 10 : 2,
        //fillColor: 0x0088e283,
        strokeColor: 0x80e97656, // redish
        displayModel: displayModel,
      );
      way.latLongs.first.forEach((element) {
        marker.addLatLong(element);
      });
      //await marker.initResources(symbolCache);
      return marker;
    }
  }
}
