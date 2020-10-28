import 'package:example/constants.dart';
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FutureBuilder<bool>(
            future: FileHelper.exists(Constants.MAPFILE_NAME),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData)
                return Text(
                  snapshot.data ? "Mapfile is already downloaded" : "Mapfile missing",
                  style: TextStyle(color: snapshot.data ? Colors.green : Colors.red),
                );
              return Container();
            },
          ),
          RaisedButton(
            child: Text("Download Mapfile"),
            onPressed: () {
              FileHelper.delete(Constants.MAPFILE_NAME);
              FileHelper.downloadFile(Constants.MAPFILE_SOURCE, Constants.MAPFILE_NAME);
            },
          ),
          RaisedButton(
            child: Text("Show offline map"),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => Showmap()));
            },
          ),
          RaisedButton(
            child: Text("Purge offline cache"),
            onPressed: () {
              MapModelHelper.prepareMapModel().then((mapModel) {
                Timer(Duration(milliseconds: 1000), () async {
                  await mapModel.tileBitmapCache.purgeAll();
                  print("cache purged");
                });
              });
            },
          ),
        ],
      ),
    );
  }
}