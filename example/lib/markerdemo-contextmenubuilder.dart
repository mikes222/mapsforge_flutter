import 'package:flutter/material.dart';
import 'package:mapsforge_example/markerdemo-database.dart';
import 'package:mapsforge_flutter/core.dart';

class MarkerdemoContextMenuBuilder extends ContextMenuBuilder {
  @override
  Widget buildContextMenu(
      BuildContext context,
      MapModel mapModel,
      ViewModel viewModel,
      MapViewPosition mapViewPosition,
      Dimension screen,
      TapEvent event) {
    return MarkerdemoContextMenu(
      screen: screen,
      event: event,
      mapModel: mapModel,
      viewModel: viewModel,
      mapViewPosition: mapViewPosition,
    );
  }
}

/////////////////////////////////////////////////////////////////////////////

class MarkerdemoContextMenu extends DefaultContextMenu {
  final MapModel mapModel;

  MarkerdemoContextMenu(
      {required Dimension screen,
      required TapEvent event,
      required this.mapModel,
      required ViewModel viewModel,
      required MapViewPosition mapViewPosition})
      : super(
            screen: screen,
            event: event,
            viewModel: viewModel,
            mapViewPosition: mapViewPosition);

  @override
  State<StatefulWidget> createState() {
    return _MarkerdemoContextMenuState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class _MarkerdemoContextMenuState extends DefaultContextMenuState {
  @override
  MarkerdemoContextMenu get widget => super.widget as MarkerdemoContextMenu;

  @override
  List<Widget> buildColumns(BuildContext context) {
    List<Widget> result = super.buildColumns(context);
    result.add(OutlinedButton(
      onPressed: () {
        // add a marker to the database
        MarkerdemoDatabase.addToDatabase(widget.event);
        // The Datastore will listen to changes in the database and update the UI
        // hide the contextmenu
        widget.viewModel.clearTapEvent();
      },
      child: const Text("New marker"),
    ));
    widget.mapModel.markerDataStores.forEach((markerDataStore) {
      markerDataStore.isTapped(widget.event).forEach((marker) {
        result.add(OutlinedButton(
            onPressed: () {
              MarkerdemoDatabase.removeFromDatabase(widget.event, marker);

              widget.viewModel.clearTapEvent();
            },
            child: const Text(
              'Remove marker',
              style: TextStyle(color: Colors.red),
            )));
      });
    });
    return result;
  }
}
