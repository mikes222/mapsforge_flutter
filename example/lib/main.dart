import 'dart:async';
import 'dart:io';
import 'package:example/map-page-view.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'map-file-data.dart';
import 'package:path_provider/path_provider.dart';

final List<MapFileData> MAP_FILE_DATA_LIST = [
  new MapFileData(
    "https://drive.google.com/uc?export=download&id=1rP5-eKdw-roZJsvCC3dsaCGtKGmprYET",
    "Chemnitz Uni.map",
    "Chemnitz - University",
    50.81348, 12.92936,
    18
  ),
  new MapFileData(
    "https://drive.google.com/uc?export=download&id=1_uyBcfs8ZRcAKlJA-tEmkzilF_ngkRfS",
    "Louvre.map",
    "Paris - Louvre",
    48.86085, 2.33665,
    17
  ),
  new MapFileData(
      "https://ftp-stud.hs-esslingen.de/pub/Mirrors/download.mapsforge.org/maps/v5/europe/france/ile-de-france.map",
      "ile-de-france.map",
      "ile-de-france",
      48.86085, 2.33665,
      17
  ),
];



void main() => runApp(MyApp());

/// This Widget is the main application widget.
class MyApp extends StatelessWidget {
  MyApp() {
    _initLogging();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapsforge Indoor App',
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
  MyStatelessWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHead(context),
      body: _buildBody(context),
    );
  }

  Widget _buildHead(BuildContext context) {
    return AppBar(
      title: const Text('Indoor Rendering Examples'),
      actions: <Widget>[
        PopupMenuButton<String>(
          offset: Offset(0,50),
          onSelected: (choice) => _handleMenuItemSelect(choice),
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: "clear_tile_cache",
              child: Text("Delete Tile Cache"),
            ),
            PopupMenuItem<String>(
              value: "delete_map_files",
              child: Text("Delete Map Files"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      scrollDirection: Axis.vertical,
      itemCount: MAP_FILE_DATA_LIST.length,
      itemBuilder: (context, i) {
        MapFileData mapFileData = MAP_FILE_DATA_LIST[i];
        return Card(
          margin: EdgeInsets.only(top: 7, bottom: 7),
          elevation: 4,
          child: ListTile(
            title: Text(mapFileData.name),
            contentPadding: EdgeInsets.fromLTRB(17, 5, 17, 5),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => MapPageView(mapFileData: mapFileData)));
            },
            trailing: Icon(Icons.arrow_forward_rounded)
          ),
        );
      },
    );
  }

  Future<void> _handleMenuItemSelect (String value) async {
    switch (value) {
      case 'clear_tile_cache':
        String fileCachePath = (await getTemporaryDirectory()).path + "/mapsforgetiles";
        var fileCacheDir = Directory(fileCachePath);
        if (await fileCacheDir.exists()) {
          fileCacheDir.list(recursive: false).forEach((f) async {
            f.delete(recursive: true);
          });
        }
        break;
      case 'delete_map_files':
        Directory dir = await getApplicationDocumentsDirectory();
        dir.list(recursive: false).forEach((f) async {
          if (await FileSystemEntity.isFile(f.path)) {
            f.delete();
          }
        });
        break;
    }
  }
}





