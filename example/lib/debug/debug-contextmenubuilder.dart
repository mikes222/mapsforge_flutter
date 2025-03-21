import 'package:flutter/material.dart';
import 'package:mapsforge_example/debug/debug-datastore.dart';
import 'package:mapsforge_example/mapfileanalyze/labeltextcustom.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/marker.dart';

class DebugContextMenuBuilder extends ContextMenuBuilder {
  final Datastore datastore;

  DebugContextMenuBuilder({required this.datastore});

  @override
  Widget buildContextMenu(BuildContext context, MapModel mapModel, ViewModel viewModel, MapViewPosition mapViewPosition, Dimension screen, TapEvent event) {
    return DebugContextMenu(
      screen: screen,
      event: event,
      mapModel: mapModel,
      viewModel: viewModel,
      mapViewPosition: mapViewPosition,
      datastore: this.datastore,
    );
  }
}

/////////////////////////////////////////////////////////////////////////////

class DebugContextMenu extends DefaultContextMenu {
  final MapModel mapModel;

  final Datastore datastore;

  DebugContextMenu(
      {required Dimension screen,
      required TapEvent event,
      required this.mapModel,
      required ViewModel viewModel,
      required MapViewPosition mapViewPosition,
      required this.datastore})
      : super(screen: screen, event: event, viewModel: viewModel, mapViewPosition: mapViewPosition);

  @override
  State<StatefulWidget> createState() {
    return _DebugContextMenuState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _DebugContextMenuState extends DefaultContextMenuState {
  @override
  DebugContextMenu get widget => super.widget as DebugContextMenu;

  late DebugDatastore debugDatastore;

  late RenderTheme renderTheme;

  @override
  void initState() {
    super.initState();
    debugDatastore = widget.mapModel.markerDataStores.firstWhere((element) => element is DebugDatastore) as DebugDatastore;
    renderTheme = (widget.mapModel.renderer as MapDataStoreRenderer).renderTheme;
  }

  @override
  List<Widget> buildColumns(BuildContext context) {
    int tileY = widget.viewModel.mapViewPosition!.projection.latitudeToTileY(widget.event.latitude);
    int tileX = widget.viewModel.mapViewPosition!.projection.longitudeToTileX(widget.event.longitude);
    Tile tile = Tile(tileX, tileY, widget.viewModel.mapViewPosition!.zoomLevel, widget.viewModel.mapViewPosition!.indoorLevel);

    List<Widget> result = super.buildColumns(context);
    result.add(TextButton(
        onPressed: () {
          debugDatastore.setInfos(null, null);
          widget.viewModel.clearTapEvent();
        },
        child: const Text("Clear")));
    result.add(LabeltextCustom(
      label: "Tile",
      value: "${tile}",
    ));
    if (debugDatastore.tile == null || debugDatastore.tile != tile) {
      result.add(FutureBuilder<DatastoreReadResult?>(
          future: _buildTile(tile),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) return const Text("wait...");
            List<Widget> inner = [];
            addInfos(inner, tile);
            return Column(
              children: inner,
              crossAxisAlignment: CrossAxisAlignment.start,
            );
          }));
    } else {
      addInfos(result, tile);
    }
    return result;
  }

  void addInfos(List<Widget> result, Tile tile) {
    if (debugDatastore.readResult != null) {
      for (Marker marker in debugDatastore.isTapped(widget.event)) {
        if (marker.item is PointOfInterest) {
          PointOfInterest poi = marker.item;
          result.add(_buildPoiInfo(poi, tile));
        } else if (marker.item == null) {
          // tile
        } else {
          WayInfo wayinfo = marker.item;
          result.add(_buildWayInfo(wayinfo, tile));
        }
      }
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
        RenderthemeLevel renderthemeLevel = renderTheme.prepareZoomlevel(tile.zoomLevel);
        List<Shape> shapes = renderthemeLevel.matchNode(tile, NodeProperties(poi));
        shapes.forEach((shape) => print(shape.toString()));
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
        debugDatastore.createWayMarker(wayinfo.way, wayinfo.latLongs, wayinfo.idx);
        print("Way: ${wayinfo.way} (idx: ${wayinfo.idx}), ${LatLongUtils.isClosedWay(wayinfo.latLongs) ? "Closed" : "Open"}");
        // way.latLongs.forEach((latlongs) {
        //   List<String> results = [];
        //   String result = "";
        //   latlongs.forEach((latlong) {
        //     result +=
        //         "const LatLong(${(latlong.latitude).toStringAsFixed(6)},${(latlong.longitude).toStringAsFixed(6)}),";
        //     if (result.length > 250) {
        //       results.add(result);
        //       result = "";
        //     }
        //   });
        //   if (result.isNotEmpty) results.add(result);
        //   results.forEach((action) {
        //     print("  $action");
        //   });
        // });

        RenderthemeLevel renderthemeLevel = renderTheme.prepareZoomlevel(tile.zoomLevel);
        if (LatLongUtils.isClosedWay(wayinfo.latLongs)) {
          List<Shape> shapes = renderthemeLevel.matchClosedWay(tile, wayinfo.way);
          shapes.forEach((shape) => print(shape.toString()));
        } else {
          List<Shape> shapes = renderthemeLevel.matchLinearWay(tile, wayinfo.way);
          shapes.forEach((shape) => print(shape.toString()));
        }
      },
    );
  }

  Future<DatastoreReadResult?> _buildTile(Tile tile) async {
    DatastoreReadResult? datastoreReadResult = await widget.datastore.readMapDataSingle(tile);
    // will throw an execption if the datastore is not available. This is ok since it is only for debug purposes
    await debugDatastore.setInfos(tile, datastoreReadResult);
    return datastoreReadResult;
  }
}
