import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_example/map-list.dart';

import 'map-file-data.dart';

/// The global variable that holds a list of map files.
///
/// Data can be files with distinct places as [MapFileData]
/// or parts of a huge and extensible area as [MapFileData.online].
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

/// This is the entry point, the main application widget.
class MyApp extends StatelessWidget {
  MyApp() {
    _initLogging();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mapsforge Example App',
      home: MapList(MAP_FILE_DATA_LIST),
    );
  }

  /// Sets a [Logger] to log debug messages.
  void _initLogging() {
    // Print output to console.
    Logger.root.onRecord.listen((LogRecord r) {
      print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
    });

    // Root logger level.
    Logger.root.level = Level.FINEST;
  }
}
