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
                  await mapModel.bitmapCache.purge();
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
                  await mapModel.bitmapCache.purge();
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

  initLogging() {
    // Print output to console.
    Logger.root.onRecord.listen((LogRecord r) {
      print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
    });

    // Root logger level.
    Logger.root.level = Level.FINEST;
  }
}
