// Flutter code sample for material.AppBar.1

// This sample shows an [AppBar] with two simple actions. The first action
// opens a [SnackBar], while the second action navigates to a new page.

import 'dart:async';

import 'package:example/showmap.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'constants.dart';
import 'filehelper.dart';
import 'mapmodelhelper.dart';

void main() => runApp(MyApp());

MapInfo sachsenMap = MapInfo(
  mapfilesource: "https://download.mapsforge.org/maps/v5/europe/germany/sachsen.map",
  mapfile: "sachsen.map",
  lat: 50.81287701030895,
  lon: 12.94189453125,
);

MapInfo monacoMap = MapInfo(
  mapfilesource: "http://ftp-stud.hs-esslingen.de/pub/Mirrors/download.mapsforge.org/maps/v5/europe/monaco.map",
  mapfile: "monaco.map",
  lat: 43.7399,
  lon: 7.4262,
);

// TODO create a drop-down in UI to let the user choose from different maps
MapInfo activeMapInfo = sachsenMap;

/// This Widget is the main application widget.
class MyApp extends StatelessWidget {
  static const String _title = 'Mapsforge sample';

  MyApp() {
    _initLogging();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: MyStatelessWidget(),
    );
  }

  void _initLogging() {
    // Print output to console.
    Logger.root.onRecord.listen((LogRecord r) {
      print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
    });

    // Root logger level.
    Logger.root.level = Level.FINEST;
  }
}

////////////////////////////////////////////////////////////////////////////////////////////

/// This is the stateless widget that the main application instantiates.
class MyStatelessWidget extends StatelessWidget {
  MyStatelessWidget({Key key}) : super(key: key) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Mapsforge'),
      ),
      body: Column(
        children: <Widget>[
          FutureBuilder<bool>(
            future: FileHelper.exists(activeMapInfo.mapfile),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData) return Text(snapshot.data ? "Mapfile is already downloaded" : "Mapfile missing");
              return Container();
            },
          ),
          RaisedButton(
            child: Text("Download Mapfile"),
            onPressed: () {
              FileHelper.downloadFile(activeMapInfo.mapfilesource, activeMapInfo.mapfile);
            },
          ),
          FutureBuilder<bool>(
            future: FileHelper.exists(Constants.worldmap),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData) return Text(snapshot.data ? "Worldmap is already downloaded" : "Worldmap missing");
              return Container();
            },
          ),
          RaisedButton(
            child: Text("Download Worldmap (zoom out several times)"),
            onPressed: () {
              FileHelper.downloadFile(Constants.worldmapsource, Constants.worldmap);
            },
          ),
          RaisedButton(
            child: Text("Show offline map"),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => Showmap()));
            },
          ),
          RaisedButton(
            child: Text("Show online map"),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (BuildContext context) => Showmap(
                        mode: 1,
                      )));
            },
          ),
          RaisedButton(
            child: Text("Purge offline cache"),
            onPressed: () {
              MapModelHelper.prepareOfflineMapModel().then((mapModel) {
                Timer(Duration(milliseconds: 1000), () async {
                  await mapModel.tileBitmapCache.purgeAll();
                  print("cache purged");
//              Scaffold.of(context).showSnackBar(new SnackBar(
//                content: new Text("cache purged"),
//              ));
                });
              });
            },
          ),
          RaisedButton(
            child: Text("Purge online cache"),
            onPressed: () {
              MapModelHelper.prepareOnlineMapModel().then((mapModel) {
                Timer(Duration(milliseconds: 1000), () async {
                  await mapModel.tileBitmapCache.purgeAll();
                  print("cache purged");
//              Scaffold.of(context).showSnackBar(new SnackBar(
//                content: new Text("cache purged"),
//              ));
                });
              });
            },
          ),
        ],
      ),
    );
  }
}

/////////////////////////////////////////////////////////////////////////////

class MapInfo {
  final String mapfilesource;
  final String mapfile;

  final double lat;

  final double lon;

  MapInfo({this.mapfilesource, this.mapfile, this.lat, this.lon});
}
