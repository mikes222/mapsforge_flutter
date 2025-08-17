import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/marker.dart';

class DebugDatastore extends MarkerDataStore {
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
    if (tile != null) await createTileMarker(tile);
    if (readResult == null) return;
    for (PointOfInterest poi in readResult.pointOfInterests) {
      //print(poi);
      Marker marker = await _createMarker(poi);
      addMarker(marker);
    }

    for (Way way in readResult.ways) {
      int idx = 0;
      for (List<ILatLong> latLongs in way.latLongs) {
        await _createWayMarker(latLongs, idx, way, false);
        ++idx;
      }
    }
    setRepaint();
  }

  Future<void> createTileMarker(Tile tile) async {
    Marker marker = RectMarker(
        minLatLon: LatLong(tile.getBoundingBox().minLatitude, tile.getBoundingBox().minLongitude),
        maxLatLon: LatLong(tile.getBoundingBox().maxLatitude, tile.getBoundingBox().maxLongitude),
        displayModel: displayModel);
    addMarker(marker);
  }

  Future<void> createWayMarker(Way way, List<ILatLong> latLongs, int idx) async {
    clearMarkers();
    if (tile != null) await createTileMarker(tile!);
    Marker circleMarker = CircleMarker(
        center: latLongs.first,
        displayModel: displayModel,
        fillColor: 0x802be690, // greenish
        radius: 10);
    addMarker(circleMarker);
    circleMarker = CircleMarker(
        center: latLongs.elementAt(1),
        displayModel: displayModel,
        fillColor: 0x802be690, // greenish
        radius: 6);
    addMarker(circleMarker);
    // latLongs.skip(1).forEach((element) {
    //   circleMarker = CircleMarker(center: element, displayModel: displayModel, strokeColor: 0xffff0000, radius: 10);
    //   addMarker(circleMarker);
    // });
    await _createWayMarker(latLongs, idx, way, true);
    circleMarker = CircleMarker(center: latLongs.last, displayModel: displayModel, fillColor: 0x80e97656, radius: 4);
    addMarker(circleMarker);
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

  Future<void> _createWayMarker(List<ILatLong> latLongs, int idx, Way way, bool intense) async {
    if (LatLongUtils.isClosedWay(latLongs)) {
      PolygonMarker marker = PolygonMarker(
        item: WayInfo(way, latLongs, idx),
        strokeWidth: intense ? 10 : 2,
        fillColor: 0x10c8c623,
        strokeColor: 0x80c8c623, // yellowish
        displayModel: displayModel,
      );
      latLongs.forEach((element) {
        marker.addLatLong(element);
      });
      await marker.initResources(symbolCache);
      addMarker(marker);
    } else {
      PathMarker marker = PathMarker(
        item: WayInfo(way, latLongs, idx),
        strokeWidth: intense ? 10 : 2,
        //fillColor: 0x0088e283,
        strokeColor: 0x80e97656, // redish
        displayModel: displayModel,
      );
      latLongs.forEach((element) {
        marker.addLatLong(element);
      });
      //await marker.initResources(symbolCache);
      addMarker(marker);
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class WayInfo {
  final Way way;

  final List<ILatLong> latLongs;

  final int idx;

  WayInfo(this.way, this.latLongs, this.idx);
}
