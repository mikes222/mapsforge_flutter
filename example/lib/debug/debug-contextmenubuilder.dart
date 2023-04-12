import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_example/debug/debug-datastore.dart';
import 'package:mapsforge_example/mapfileanalyze/labeltextcustom.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/marker.dart';

class DebugContextMenuBuilder extends ContextMenuBuilder {
  final Datastore datastore;

  DebugContextMenuBuilder({required this.datastore});

  @override
  Widget buildContextMenu(
      BuildContext context,
      MapModel mapModel,
      ViewModel viewModel,
      MapViewPosition mapViewPosition,
      Dimension screen,
      TapEvent event) {
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
      : super(
            screen: screen,
            event: event,
            viewModel: viewModel,
            mapViewPosition: mapViewPosition);

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

  @override
  void initState() {
    super.initState();
    debugDatastore = widget.mapModel.markerDataStores
        .firstWhere((element) => element is DebugDatastore) as DebugDatastore;
  }

  @override
  List<Widget> buildColumns(BuildContext context) {
    int tileY = widget.viewModel.mapViewPosition!.projection!
        .latitudeToTileY(widget.event.latitude);
    int tileX = widget.viewModel.mapViewPosition!.projection!
        .longitudeToTileX(widget.event.longitude);
    Tile tile = Tile(tileX, tileY, widget.viewModel.mapViewPosition!.zoomLevel,
        widget.viewModel.mapViewPosition!.indoorLevel);

    List<Widget> result = super.buildColumns(context);
    if (debugDatastore.tile == null || debugDatastore.tile != tile)
      result.add(FutureBuilder<DatastoreReadResult?>(
          future: _buildTile(tile),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) return const Text("wait...");
            DatastoreReadResult result = snapshot.data;
            // will throw an execption if the datastore is not available. This is ok since it is only for debug purposes
            debugDatastore.setInfos(tile, result);
            return const SizedBox();
          }));
    if (debugDatastore.tile != null) {
      result.add(TextButton(
          onPressed: () {
            debugDatastore.setInfos(null, null);
            widget.viewModel.clearTapEvent();
          },
          child: const Text("Clear")));
      result.add(LabeltextCustom(
        label: "ZoomLevel",
        value: "${tile.zoomLevel}",
      ));
      result.add(LabeltextCustom(
        label: "IndoorLevel",
        value: "${tile.indoorLevel}",
      ));
    }
    if (debugDatastore.readResult != null) {
      for (Marker marker in debugDatastore.isTapped(widget.event)) {
        if (marker.item is PointOfInterest) {
          PointOfInterest poi = marker.item;
          result.add(_buildPoiInfo(poi));
        } else {
          Way way = marker.item;
          result.add(_buildWayInfo(way));
        }
      }
    }
    return result;
  }

  Widget _buildPoiInfo(PointOfInterest poi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.orange)),
        child: Row(
          children: [
            const Text("Poi"),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  poi.tags.map((e) => Text("${e.key} = ${e.value}")).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWayInfo(Way way) {
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(
                  color: LatLongUtils.isClosedWay(way.latLongs[0])
                      ? Colors.yellow
                      : Colors.red)),
          child: Row(
            children: [
              if (LatLongUtils.isClosedWay(way.latLongs[0]))
                Text("Closed Way ${way.layer}"),
              if (!LatLongUtils.isClosedWay(way.latLongs[0]))
                Text("Open Way ${way.layer}"),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    way.tags.map((e) => Text("${e.key} = ${e.value}")).toList(),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        debugDatastore.createWayMarker(way);
      },
    );
  }

  Future<DatastoreReadResult?> _buildTile(Tile tile) async {
    DatastoreReadResult? result =
        await widget.datastore.readMapDataSingle(tile);
    return result;
  }
}
