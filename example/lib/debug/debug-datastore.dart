import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/marker.dart';

class DebugDatastore extends MarkerByItemDataStore {
  final SymbolCache symbolCache;

  Tile? tile;

  DatastoreReadResult? readResult;

  DebugDatastore({required this.symbolCache}) {}

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
      Marker marker = await _createWayMarker(way);
      addMarker(marker);
    }
    setRepaint();
  }

  @override
  Future<void> retrieveMarkersFor(BoundingBox boundary, int zoomLevel) async {}

  Future<Marker> _createMarker(PointOfInterest poi) async {
    CircleMarker marker = CircleMarker(
      center: poi.position,
      item: poi,
      radius: 10,
      strokeWidth: 2,
      fillColor: 0x80eac71c,
      strokeColor: 0xffc2a726,
    );
    return marker;
  }

  Future<Marker> _createWayMarker(Way way) async {
    if (LatLongUtils.isClosedWay(way.latLongs.first)) {
      PolygonMarker marker = PolygonMarker(
        item: way,
        strokeWidth: 2,
        fillWidth: 1,
        fillColor: 0x1088e283,
        strokeColor: 0x50349a2e,
      );
      way.latLongs.first.forEach((element) {
        marker.addLatLong(element);
      });
      await marker.initResources(symbolCache);
      return marker;
    } else {
      PolygonMarker marker = PolygonMarker(
        item: way,
        strokeWidth: 6,
        fillWidth: 0,
        fillColor: 0x0088e283,
        strokeColor: 0x60349a2e,
      );
      way.latLongs.first.forEach((element) {
        marker.addLatLong(element);
      });
      await marker.initResources(symbolCache);
      return marker;
    }
  }
}
