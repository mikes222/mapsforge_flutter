import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_example/map-page-view.dart';
import 'package:path_provider/path_provider.dart';

import 'map-file-data.dart';

// ignore: non_constant_identifier_names
final List<MapFileData> MAP_FILE_DATA_LIST = [
  new MapFileData.online(
    displayedName: "Online Austria (Supports web)",
    initialPositionLat: 48.089415,
    initialPositionLong: 16.311374,
    initialZoomLevel: 12,
    indoorZoomOverlay: false,
  ),
  new MapFileData(
    url: "https://drive.google.com/uc?export=download&id=1rP5-eKdw-roZJsvCC3dsaCGtKGmprYET",
    fileName: "Chemnitz Uni.map",
    displayedName: "Indoor Chemnitz - University",
    initialPositionLat: 50.81348,
    initialPositionLong: 12.92936,
    initialZoomLevel: 18,
  ),
  new MapFileData(
    url: "https://tuc.cloud/index.php/s/3mLSrDfeH3WHKQE/download",
    fileName: "indoorUB-ext.map",
    displayedName: "Indoor Chemnitz - Library",
    initialPositionLat: 50.84160,
    initialPositionLong: 12.92700,
    initialZoomLevel: 18,
  ),
  new MapFileData(
    url: "https://drive.google.com/uc?export=download&id=1_uyBcfs8ZRcAKlJA-tEmkzilF_ngkRfS",
    fileName: "Louvre.map",
    displayedName: "Indoor Paris - Louvre",
    initialPositionLat: 48.86085,
    initialPositionLong: 2.33665,
  ),
  new MapFileData(
    url: "https://ftp-stud.hs-esslingen.de/pub/Mirrors/download.mapsforge.org/maps/v5/europe/france/ile-de-france.map",
    fileName: "ile-de-france.map",
    displayedName: "Indoor ile-de-france",
    initialPositionLat: 48.86085,
    initialPositionLong: 2.33665,
  ),
  new MapFileData(
    url: "https://download.mapsforge.org/maps/v5/europe/germany/sachsen.map",
    fileName: "sachsen.map",
    displayedName: "Offline Saxony",
    theme: "assets/defaultrender.xml",
    initialPositionLat: 50.81287701030895,
    initialPositionLong: 12.94189453125,
    initialZoomLevel: 12,
    indoorZoomOverlay: false,
  ),
  new MapFileData(
    url: "https://download.mapsforge.org/maps/v5/europe/austria.map",
    fileName: "austria.map",
    displayedName: "Offline Austria",
    theme: "assets/defaultrender.xml",
    initialPositionLat: 48.089415,
    initialPositionLong: 16.311374,
    initialZoomLevel: 12,
    indoorZoomOverlay: false,
  ),
  new MapFileData(
    url: "https://www.dailyflightbuddy.com/monaco.map",
    fileName: "monaco.map",
    displayedName: "Offline Monaco (Supports web)",
    theme: "assets/defaultrender.xml",
    initialPositionLat: 43.7399,
    initialPositionLong: 7.4262,
    initialZoomLevel: 15,
    indoorZoomOverlay: false,
  ),
  new MapFileData(
    url: "https://www.dailyflightbuddy.com/sicilia_oam.zip",
    fileName: "sicilia_oam.zip",
    displayedName: "Contour Sizilia",
    theme: "assets/sicilia_oam.xml",
    relativePathPrefix: "sicilia_oam/",
    initialPositionLat: 37.5,
    initialPositionLong: 14.3,
    initialZoomLevel: 15,
    indoorZoomOverlay: false,
  ),
  new MapFileData(
    url: "http://ftp-stud.hs-esslingen.de/pub/Mirrors/download.mapsforge.org/maps/world/world.map",
    fileName: "world.map",
    displayedName: "Worldmap (big download size)",
    theme: "assets/defaultrender.xml",
    initialPositionLat: 43.7399,
    initialPositionLong: 7.4262,
    initialZoomLevel: 5,
    indoorZoomOverlay: false,
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
          return _buildCard(context, element.displayedName, () {
            Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => MapPageView(mapFileData: element)));
          });
        }).toList(),
      ),
    );
  }

  Card _buildCard(BuildContext context, String caption, action, [bool enabled = true]) {
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
        trailing: Icon(Icons.arrow_forward_rounded),
      ),
    );
  }

  Future<void> _handleMenuItemSelect(String value) async {
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
  final String? mapFileSource;
  final String? mapFile;
  final double? lat;
  final double? lon;

  MapInfo({this.mapFileSource, this.mapFile, this.lat, this.lon});
}
