// Flutter code sample for material.AppBar.1

// This sample shows an [AppBar] with two simple actions. The first action
// opens a [SnackBar], while the second action navigates to a new page.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';

import 'constants.dart';
import 'filehelper.dart';
import 'mapmodelhelper.dart';

void main() => runApp(MyApp());

/// This Widget is the main application widget.
class MyApp extends StatelessWidget {
  static const String _title = 'Mapsforge sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: MyStatelessWidget(),
    );
  }
}

final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
final SnackBar snackBar = const SnackBar(content: Text('Showing Snackbar'));

Timer timer;

void openPage(BuildContext context) {
  Navigator.push(context, MaterialPageRoute(
    builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Next page'),
        ),
        body: FutureBuilder<MapModel>(
          future: MapModelHelper.prepareMapModel(),
          builder: (BuildContext context, AsyncSnapshot<MapModel> snapshot) {
            if (snapshot.hasError) {
              Error e = snapshot.error;
              print(e.toString());
              print(e.stackTrace.toString());

              return Text("Error: ${snapshot.error.toString()}");
            }
            if (!snapshot.hasData)
              return Center(
                child: Column(
                  children: <Widget>[
                    Text("Preparing MapModel"),
                    CircularProgressIndicator(),
                  ],
                ),
              );
            MapModel mapModel = snapshot.data;

            return Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    RaisedButton(
                      child: Text("Set Location"),
                      onPressed: () {
                        mapModel.setMapViewPosition(48.0901926, 16.308939);
                      },
                    ),
                    RaisedButton(
                      child: Text("run around"),
                      onPressed: () {
                        if (timer != null) return;
                        timer = Timer.periodic(Duration(seconds: 1), (timer) {
                          mapModel.setMapViewPosition(
                              mapModel.mapViewPosition.latitude + 0.001, mapModel.mapViewPosition.longitude + 0.001);
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
                      onPressed: () {
                        mapModel.zoomIn();
                      },
                    ),
                    RaisedButton(
                      child: Text("Zoom out"),
                      onPressed: () {
                        mapModel.zoomOut();
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
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  ));
}

/// This is the stateless widget that the main application instantiates.
class MyStatelessWidget extends StatelessWidget {
  MyStatelessWidget({Key key}) : super(key: key) {
    initLogging();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text('Flutter Mapsforge'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_alert),
            tooltip: 'Show Snackbar',
            onPressed: () {
              scaffoldKey.currentState.showSnackBar(snackBar);
            },
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            tooltip: 'Next page',
            onPressed: () {
              openPage(context);
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          FutureBuilder<bool>(
            future: FileHelper.exists(Constants.mapfile),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData) return Text(snapshot.data ? "Mapfile is already downloaded" : "Mapfile missing");
              return Container();
            },
          ),
          RaisedButton(
            child: Text("Download Mapfile"),
            onPressed: () {
              FileHelper.downloadFile(Constants.mapfilesource, Constants.mapfile);
            },
          ),
        ],
      ),
    );
  }

  initLogging() {
    // Print output to console.
    Logger.root.onRecord.listen((LogRecord r) {
      print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
    });

    // Root logger level.
    Logger.root.level = Level.FINEST;
  }
}
