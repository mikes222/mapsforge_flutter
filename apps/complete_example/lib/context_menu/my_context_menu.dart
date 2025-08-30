import 'package:complete_example/context_menu/mapfile_analyze/labeltextcustom.dart';
import 'package:complete_example/context_menu/mapfile_analyze/mapheaderpage.dart';
import 'package:complete_example/models/app_models.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapsforge_flutter/context_menu.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';

class MyContextMenu extends StatelessWidget {
  final ContextMenuInfo info;

  final MarkerDatastore markerDatastore;

  final MapModel mapModel;

  final AppConfiguration configuration;

  final String downloadFile;

  final MarkerDatastore debugDatastore;

  final Datastore? datastore;

  const MyContextMenu({
    super.key,
    required this.info,
    required this.markerDatastore,
    required this.debugDatastore,
    required this.mapModel,
    required this.configuration,
    required this.downloadFile,
    this.datastore,
  });

  @override
  Widget build(BuildContext context) {
    if (info.diffX < -info.halfScreenWidth ||
        info.diffX > 3 * info.halfScreenWidth ||
        info.diffY < -info.halfScreenHeight ||
        info.diffY > 3 * info.halfScreenHeight) {
      info.mapModel.tap(null);
      return const SizedBox();
    }

    int tileY = info.projection.latitudeToTileY(info.latitude);
    int tileX = info.projection.longitudeToTileX(info.longitude);
    Tile tile = Tile(tileX, tileY, info.projection.scalefactor.zoomlevel, mapModel.lastPosition!.indoorLevel);

    return SimpleContextMenuWidget(
      info: info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              info.mapModel.tap(null);
            },
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: "${info.latitude.toStringAsFixed(6)}, ${info.longitude.toStringAsFixed(6)}"));
            },
            child: Text("${info.latitude.toStringAsFixed(6)} / ${info.longitude.toStringAsFixed(6)}"),
          ),
          LabeltextCustom(label: "Tile", value: "$tile"),
          OutlinedButton(
            onPressed: () {
              // add a marker to the database, the old marker with the same key will be replaced.
              markerDatastore.addMarker(CircleMarker(latLong: info.latLong, key: "circle"));
              //MarkerdemoDatabase.addToDatabase(widget.event);
              // // The Datastore will listen to changes in the database and update the UI
              // // hide the contextmenu
              mapModel.tap(null);
            },
            child: const Text("New marker"),
          ),
          if (configuration.rendererType.isOffline)
            OutlinedButton(
              onPressed: () async {
                String renderthemeString = await rootBundle.loadString(configuration.renderTheme!.fileName);
                Rendertheme rendertheme = RenderThemeBuilder.createFromString(renderthemeString.toString());

                Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => MapHeaderPage(rendertheme, downloadFile)));
                //MarkerdemoDatabase.addToDatabase(widget.event);
                // // The Datastore will listen to changes in the database and update the UI
                // // hide the contextmenu
                mapModel.tap(null);
              },
              child: const Text("Analyze mapfile"),
            ),
          OutlinedButton(
            onPressed: () {
              debugDatastore.clearMarkers();
              mapModel.tap(null);
            },
            child: const Text("Clear"),
          ),
          OutlinedButton(
            onPressed: () {
              _readTile(tile);
              mapModel.tap(null);
            },
            child: const Text("Debug tile"),
          ),
          ...debugDatastore.getTappedMarkers(info.event).map((marker) {
            return _createMarkerInfo(marker, tile);
          }),
        ],
      ),
    );
  }

  Widget _createMarkerInfo(Marker marker, Tile tile) {
    if (marker.key is PointOfInterest) {
      PointOfInterest poi = marker.key;
      return _buildPoiInfo(poi, tile);
    } else if (marker.key == "tile") {
      // tile
      return const SizedBox();
    } else {
      WayInfo wayinfo = marker.key;
      return _buildWayInfo(wayinfo, tile);
    }
  }

  Widget _buildPoiInfo(PointOfInterest poi, Tile tile) {
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.orange)),
          child: Row(
            children: [
              const Icon(Icons.location_on),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: poi.tags.map((e) => Text("${e.key} = ${e.value}", style: const TextStyle(fontSize: 10))).toList(),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        // RenderthemeLevel renderthemeLevel = renderTheme.prepareZoomlevel(tile.zoomLevel);
        // List<Shape> shapes = renderthemeLevel.matchNode(tile, NodeProperties(poi));
        // shapes.forEach((shape) => print(shape.toString()));
      },
    );
  }

  Widget _buildWayInfo(WayInfo wayinfo, Tile tile) {
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: LatLongUtils.isClosedWay(wayinfo.latLongs) ? Colors.yellow : Colors.red)),
          child: Row(
            children: [
              if (LatLongUtils.isClosedWay(wayinfo.latLongs) && wayinfo.way.latLongs.length > 1) const Icon(Icons.rectangle),
              if (LatLongUtils.isClosedWay(wayinfo.latLongs) && wayinfo.way.latLongs.length <= 1) const Icon(Icons.rectangle_outlined),
              if (!LatLongUtils.isClosedWay(wayinfo.latLongs) && wayinfo.way.latLongs.length > 1) const Icon(Icons.polymer),
              if (!LatLongUtils.isClosedWay(wayinfo.latLongs) && wayinfo.way.latLongs.length <= 1) const Icon(Icons.polyline_rounded),
              const SizedBox(width: 4),
              Text("Layer ${wayinfo.way.layer}"),
              const SizedBox(width: 4),
              Text("Idx ${wayinfo.idx}"),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: wayinfo.way.tags.map((e) => Text("${e.key} = ${e.value}", style: const TextStyle(fontSize: 10))).toList(),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        //debugDatastore.createWayMarker(wayinfo.way, wayinfo.latLongs, wayinfo.idx);
        print("Way: ${wayinfo.way} (idx: ${wayinfo.idx}), ${LatLongUtils.isClosedWay(wayinfo.latLongs) ? "Closed" : "Open"}");
        // RenderthemeLevel renderthemeLevel = renderTheme.prepareZoomlevel(tile.zoomLevel);
        // if (LatLongUtils.isClosedWay(wayinfo.latLongs)) {
        //   List<Shape> shapes = renderthemeLevel.matchClosedWay(tile, wayinfo.way);
        //   shapes.forEach((shape) => print(shape.toString()));
        // } else {
        //   List<Shape> shapes = renderthemeLevel.matchLinearWay(tile, wayinfo.way);
        //   shapes.forEach((shape) => print(shape.toString()));
        // }
      },
    );
  }

  Future<void> _readTile(Tile tile) async {
    DatastoreBundle? bundle = await datastore!.readMapDataSingle(tile);
    debugDatastore.clearMarkers();
    if (bundle == null) return;
    debugDatastore.addMarker(_createTileMarker(tile));
    for (PointOfInterest poi in bundle.pointOfInterests) {
      Marker marker = _createPoiMarker(poi);
      debugDatastore.addMarker(marker);
    }

    for (Way way in bundle.ways) {
      int idx = 0;
      for (List<ILatLong> latLongs in way.latLongs) {
        _addWayMarkers(way, latLongs, idx);
        ++idx;
      }
    }
  }

  Marker _createTileMarker(Tile tile) {
    Marker marker = RectMarker(
      key: "tile",
      minLatLon: LatLong(tile.getBoundingBox().minLatitude, tile.getBoundingBox().minLongitude),
      maxLatLon: LatLong(tile.getBoundingBox().maxLatitude, tile.getBoundingBox().maxLongitude),
      strokeMinZoomLevel: MapsforgeSettingsMgr.defaultMaxZoomlevel,
      strokeWidth: 2 * MapsforgeSettingsMgr().getDeviceScaleFactor(),
    );
    return marker;
  }

  Marker _createPoiMarker(PointOfInterest poi) {
    CircleMarker marker = CircleMarker(
      key: poi,
      latLong: poi.position,
      radius: 5 * MapsforgeSettingsMgr().getDeviceScaleFactor(),
      strokeWidth: 2 * MapsforgeSettingsMgr().getDeviceScaleFactor(),
      fillColor: 0x80eac71c,
      strokeColor: 0xffc2a726,
      strokeMinZoomLevel: MapsforgeSettingsMgr.defaultMaxZoomlevel,
    );
    return marker;
  }

  void _addWayMarkers(Way way, List<ILatLong> latLongs, int idx) {
    Marker circleMarker = CircleMarker(
      key: "$way $idx first",
      latLong: latLongs.first,
      fillColor: 0x802be690, // greenish
      radius: 10 * MapsforgeSettingsMgr().getDeviceScaleFactor(),
      strokeMinZoomLevel: MapsforgeSettingsMgr.defaultMaxZoomlevel,
    );
    debugDatastore.addMarker(circleMarker);
    circleMarker = CircleMarker(
      key: "$way $idx second",
      latLong: latLongs.elementAt(1),
      fillColor: 0x802be690, // greenish
      radius: 6 * MapsforgeSettingsMgr().getDeviceScaleFactor(),
      strokeMinZoomLevel: MapsforgeSettingsMgr.defaultMaxZoomlevel,
    );
    debugDatastore.addMarker(circleMarker);

    _createWayMarker(latLongs, idx, way, true);
    circleMarker = CircleMarker(
      key: "$way $idx last",
      latLong: latLongs.last,
      fillColor: 0x80e97656,
      radius: 4 * MapsforgeSettingsMgr().getDeviceScaleFactor(),
      strokeMinZoomLevel: MapsforgeSettingsMgr.defaultMaxZoomlevel,
    );
    debugDatastore.addMarker(circleMarker);
  }

  void _createWayMarker(List<ILatLong> latLongs, int idx, Way way, bool intense) {
    if (LatLongUtils.isClosedWay(latLongs)) {
      AreaMarker marker = AreaMarker(
        key: WayInfo(way, latLongs, idx),
        strokeWidth: intense ? 10 * MapsforgeSettingsMgr().getDeviceScaleFactor() : 2 * MapsforgeSettingsMgr().getDeviceScaleFactor(),
        fillColor: 0x10c8c623,
        strokeColor: 0x80c8c623, // yellowish
        path: latLongs,
        strokeMinZoomLevel: MapsforgeSettingsMgr.defaultMaxZoomlevel,
      );
      debugDatastore.addMarker(marker);
    } else {
      PolylineMarker marker = PolylineMarker(
        key: WayInfo(way, latLongs, idx),
        strokeWidth: intense ? 10 * MapsforgeSettingsMgr().getDeviceScaleFactor() : 2 * MapsforgeSettingsMgr().getDeviceScaleFactor(),
        //fillColor: 0x0088e283,
        strokeColor: 0x80e97656, // redish
        path: latLongs,
        strokeMinZoomLevel: MapsforgeSettingsMgr.defaultMaxZoomlevel,
      );
      debugDatastore.addMarker(marker);
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
