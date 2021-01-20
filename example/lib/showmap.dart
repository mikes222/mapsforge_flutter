import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';

import 'main.dart';
import 'mapmodelhelper.dart';

class Showmap extends StatefulWidget {
  final MapInfo mapInfo;

  final bool online;

  const Showmap({Key key, this.mapInfo, this.online = false})
      : assert(online != null),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ShowmapState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class ShowmapState extends State<Showmap> {
  Timer timer;

  MapModel mapModel;

  ViewModel viewModel;

  @override
  void initState() {
    super.initState();
    MapModelHelper.prepareMapModel(widget.mapInfo.mapfile, widget.mapInfo.lat, widget.mapInfo.lon, 8, widget.online).then((mapModel) {
      setState(() {
        this.mapModel = mapModel;
        viewModel = ViewModel(displayModel: mapModel.displayModel);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapsforge map'),
      ),
      body: mapModel == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : _buildMapModel(mapModel),
    );
  }

  Widget _buildMapModel(MapModel mapModel) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            RaisedButton(
              child: Text("Set Location"),
              onPressed: () {
                viewModel.setMapViewPosition(activeMapInfo.lat, activeMapInfo.lon);
              },
            ),
            RaisedButton(
              child: Text("run around"),
              onPressed: () {
                if (timer != null) return;
                timer = Timer.periodic(Duration(seconds: 1), (timer) {
                  viewModel.mapViewPosition.calculateBoundingBox(viewModel.viewDimension);
                  viewModel.setLeftUpper(viewModel.mapViewPosition.leftUpper.x + 10, viewModel.mapViewPosition.leftUpper.y + 10);
                });
              },
            ),
            RaisedButton(
              child: Text("stop"),
              onPressed: () {
                timer.cancel();
                timer = null;
              },
            ),
            RaisedButton(
              child: Text("Zoom in"),
              onPressed: viewModel.mapViewPosition.zoomLevel == viewModel.displayModel.maxZoomLevel
                  ? null
                  : () {
                      viewModel.zoomIn();
                    },
            ),
            RaisedButton(
              child: Text("Zoom out"),
              onPressed: viewModel.mapViewPosition.zoomLevel == 0
                  ? null
                  : () {
                      //if (viewModel.mapViewPosition.zoomLevel == 0) return;
                      viewModel.zoomOut();
                    },
            ),
            StreamBuilder(
              stream: viewModel.observePosition,
              builder: (BuildContext context, AsyncSnapshot<MapViewPosition> snapshot) {
                if (!snapshot.hasData) return Container();
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text("Zoom ${snapshot.data?.zoomLevel ?? ""}"),
                );
              },
            ),
            StreamBuilder(
              stream: viewModel.observeTap,
              builder: (BuildContext context, AsyncSnapshot<TapEvent> snapshot) {
                if (!snapshot.hasData) return Container();
                TapEvent event = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text("Tapped ${event.latitude.toStringAsFixed(6)} / ${event.longitude.toStringAsFixed(6)}"),
                );
              },
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.green)),
              child: FlutterMapView(
                mapModel: mapModel,
                viewModel: viewModel,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
