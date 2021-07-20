import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_example/map-page-view.dart';
import 'package:path_provider/path_provider.dart';

import 'map-file-data.dart';

final List<MapFileData> MAP_FILE_DATA_LIST = [
  new MapFileData.online(
      "Online Austria (Supports web)", 48.089415, 16.311374, 12),
  new MapFileData(
      "https://drive.google.com/uc?export=download&id=1rP5-eKdw-roZJsvCC3dsaCGtKGmprYET",
      "Chemnitz Uni.map",
      "Indoor Chemnitz - University",
      "assets/custom.xml",
      null,
      50.81348,
      12.92936,
      18),
  new MapFileData(
      "https://drive.google.com/uc?export=download&id=1_uyBcfs8ZRcAKlJA-tEmkzilF_ngkRfS",
      "Louvre.map",
      "Indoor Paris - Louvre",
      "assets/custom.xml",
      null,
      48.86085,
      2.33665,
      17),
  new MapFileData(
      "https://ftp-stud.hs-esslingen.de/pub/Mirrors/download.mapsforge.org/maps/v5/europe/france/ile-de-france.map",
      "ile-de-france.map",
      "Indoor ile-de-france",
      "assets/custom.xml",
      null,
      48.86085,
      2.33665,
      17),
  new MapFileData(
      "https://download.mapsforge.org/maps/v5/europe/germany/sachsen.map",
      "sachsen.map",
      "Offline Saxony",
      "assets/defaultrender.xml",
      null,
      50.81287701030895,
      12.94189453125,
      12),
  new MapFileData(
      "https://download.mapsforge.org/maps/v5/europe/austria.map",
      "austria.map",
      "Offline Austria",
      "assets/defaultrender.xml",
      null,
      48.089415,
      16.311374,
      12),
  new MapFileData(
      "https://www.dailyflightbuddy.com/monaco.map",
      "monaco.map",
      "Offline Monaco (Supports web)",
      "assets/defaultrender.xml",
      null,
      43.7399,
      7.4262,
      15),
  new MapFileData(
      "https://www.dailyflightbuddy.com/sicilia_oam.zip",
      "sicilia_oam.zip",
      "Contour Sizilia",
      "assets/sicilia_oam.xml",
      "sicilia_oam/",
      37.5,
      14.3,
      15),
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
      title: 'Mapsforge Example App',
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

/////////////////////////////////////////////////////////////////////////////

/// This is the stateless widget that the main application instantiates.
class MyStatelessWidget extends StatelessWidget {
  MyStatelessWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHead(context) as PreferredSizeWidget?,
      body: _buildBody(context),
    );
  }

  Widget _buildHead(BuildContext context) {
    return AppBar(
      title: const Text('Rendering Examples'),
      actions: <Widget>[
        PopupMenuButton<String>(
          offset: Offset(0, 50),
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
    return SingleChildScrollView(
      child: Column(
        children: MAP_FILE_DATA_LIST.map((element) {
          return _buildCard(context, element.name, () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext context) =>
                    MapPageView(mapFileData: element)));
          });
        }).toList(),
      ),
    );
  }

  Card _buildCard(BuildContext context, String caption, action,
      [bool enabled = true]) {
    return Card(
      margin: EdgeInsets.only(top: 7, bottom: 7),
      elevation: 4,
      child: ListTile(
          title: Text(
            caption,
            style: TextStyle(color: enabled ? Colors.black : Colors.grey),
          ),
          contentPadding: EdgeInsets.fromLTRB(17, 5, 17, 5),
          onTap: enabled ? action : null,
          trailing: Icon(Icons.arrow_forward_rounded)),
    );
  }

  Future<void> _handleMenuItemSelect(String value) async {
    switch (value) {
      case 'clear_tile_cache':
        String fileCachePath =
            (await getTemporaryDirectory()).path + "/mapsforgetiles";
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

// RaisedButton(
// child: Text("Analyze mapfile"),
// onPressed: () {
// Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => MapHeaderPage(activeMapInfo.mapfile)));
// ),

//     RaisedButton(
//     child: Text("Purge offline cache"),
//     onPressed: () {
//     MapModelHelper.prepareOfflineMapModel().then((mapModel) {
//     Timer(Duration(milliseconds: 1000), () async {
//     await mapModel.tileBitmapCache.purgeAll();
//     print("cache purged");
// //              Scaffold.of(context).showSnackBar(new SnackBar(
// //                content: new Text("cache purged"),
// //              ));
//     });
//     });
//     },
//     ),
//     RaisedButton(
//     child: Text("Purge online cache"),
//     onPressed: () {
//     MapModelHelper.prepareOnlineMapModel().then((mapModel) {
//     Timer(Duration(milliseconds: 1000), () async {
//     await mapModel.tileBitmapCache.purgeAll();
//     print("cache purged");
// //              Scaffold.of(context).showSnackBar(new SnackBar(
// //                content: new Text("cache purged"),
// //              ));
//     });
//     });
//     },
//     ),

}

/////////////////////////////////////////////////////////////////////////////

class MapInfo {
  final String? mapfilesource;
  final String? mapfile;

  final double? lat;

  final double? lon;

  MapInfo({this.mapfilesource, this.mapfile, this.lat, this.lon});
}
