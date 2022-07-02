import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_example/debug/debug-datastore.dart';
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
      MapViewPosition position,
      Dimension screen,
      TapEvent event) {
    return DebugContextMenu(
      screen: screen,
      event: event,
      mapModel: mapModel,
      viewModel: viewModel,
      position: position,
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
      required MapViewPosition position,
      required this.datastore})
      : super(
            screen: screen,
            event: event,
            viewModel: viewModel,
            position: position);

  @override
  State<StatefulWidget> createState() {
    return _DebugContextMenuState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _DebugContextMenuState extends DefaultContextMenuState {
  @override
  DebugContextMenu get widget => super.widget as DebugContextMenu;

  @override
  List<Widget> buildColumns(BuildContext context) {
    int tileY = widget.viewModel.mapViewPosition!.projection!
        .latitudeToTileY(widget.event.latitude);
    int tileX = widget.viewModel.mapViewPosition!.projection!
        .longitudeToTileX(widget.event.longitude);
    Tile tile = Tile(tileX, tileY, widget.viewModel.mapViewPosition!.zoomLevel,
        widget.viewModel.mapViewPosition!.indoorLevel);
    DebugDatastore datastore = widget.mapModel.markerDataStores
        .firstWhere((element) => element is DebugDatastore) as DebugDatastore;

    List<Widget> result = super.buildColumns(context);
    if (datastore.tile == null || datastore.tile != tile)
      result.add(FutureBuilder<DatastoreReadResult?>(
          future: _buildTile(tile),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) return const Text("wait...");
            DatastoreReadResult result = snapshot.data;
            // will throw an execption if the datastore is not available. This is ok since it is only for debug purposes
            datastore.setInfos(tile, result);
            return const SizedBox();
          }));
    if (datastore.tile != null) {
      result.add(TextButton(
          onPressed: () {
            datastore.setInfos(null, null);
          },
          child: const Text("Clear")));
    }
    if (datastore.readResult != null) {
      for (Marker marker in datastore.isTapped(widget.event)) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: poi.tags.map((e) => Text("${e.key} = ${e.value}")).toList(),
        ),
      ),
    );
  }

  Widget _buildWayInfo(Way way) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.green)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: way.tags.map((e) => Text("${e.key} = ${e.value}")).toList(),
        ),
      ),
    );
  }

  Future<DatastoreReadResult?> _buildTile(Tile tile) async {
    DatastoreReadResult? result =
        await widget.datastore.readMapDataSingle(tile);
    return result;
  }
}
