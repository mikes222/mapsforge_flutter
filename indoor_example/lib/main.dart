import 'dart:async';
import 'dart:io';
import 'map-page-view.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'map-file-data.dart';
import 'package:path_provider/path_provider.dart';

final List<MapFileData> MAP_FILE_DATA_LIST = [
  new MapFileData(
      "https://drive.google.com/uc?export=download&id=1dCEvkRQ2oiAaGGDQFyvFRZKlbtxbvV_X",
      "Chemnitz Uni Gebäude.map",
      "Chemnitz Uni Gebäude",
      50.81352, 12.92952,
      18
  ),
  new MapFileData(
      "https://drive.google.com/uc?export=download&id=1HknQgiXyQugU_9fbMn8vUmtzmfqWKohl",
      "Louvre.map",
      "Paris Gare de Lyon",
      48.84432, 2.37472,
      18
  ),
  new MapFileData(
      "https://drive.google.com/uc?export=download&id=1HknQgiXyQugU_9fbMn8vUmtzmfqWKohl",
      "Louvre.map",
      "Louvre",
      48.86059, 2.33805,
      18
  ),
  new MapFileData(
      "https://drive.google.com/uc?export=download&id=11qpUK-JjutVBwRS1cScS0FcBKK_JOVAy",
      "Meadowhall Shopping Center.map",
      "Meadowhall Shopping Center",
      53.41388, -1.41063,
      18
  ),
  new MapFileData(
      "https://drive.google.com/uc?export=download&id=16yNZdYwS2QlnyrGJWW1fS7eElV_1bw9d",
      "Northglenn High School.map",
      "Northglenn High School",
      39.88039, -104.99388,
      18
  ),
  new MapFileData(
      "https://drive.google.com/uc?export=download&id=1Wx_le6A8SSgh6tJJ_Yw09bF5gMbtnMEv",
      "Haus mit Etagenkürzeln.map",
      "Haus mit Etagenkürzeln",
      49.94771,11.57493,
      20
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





