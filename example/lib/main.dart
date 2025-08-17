import 'package:flutter/material.dart';
//import 'package:leak_tracker/leak_tracker.dart';
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
  ),
  new MapFileData.onlineSatellite(
    displayedName: "Online Austria Satellite (Supports web)",
    initialPositionLat: 48.089415,
    initialPositionLong: 16.311374,
    initialZoomLevel: 12,
  ),
  const MapFileData(
    url: "https://dailyflightbuddy.com/mapsforge_examples/Chemnitz Uni.map",
    fileName: "Chemnitz Uni.map",
    displayedName: "Chemnitz - University (Indoor)",
    initialPositionLat: 50.81348,
    initialPositionLong: 12.92936,
    initialZoomLevel: 18,
    indoorZoomOverlay: true,
    indoorLevels: {1: 'OG', 0: 'EG', -1: 'UG'},
  ),
  const MapFileData(
    url: "https://dailyflightbuddy.com/mapsforge_examples/Louvre.map",
    fileName: "Louvre.map",
    displayedName: "Paris - Louvre (Indoor)",
    initialPositionLat: 48.86085,
    initialPositionLong: 2.33665,
    indoorZoomOverlay: true,
    indoorLevels: {2: '2', 1: '1', 0: '0', -1: '-1', -2: '-2', -3: '-3'},
  ),
  const MapFileData(
    url: "https://dailyflightbuddy.com/mapsforge_examples/ile-de-france.map",
    fileName: "ile-de-france.map",
    displayedName: "ile-de-france",
    initialPositionLat: 48.86085,
    initialPositionLong: 2.33665,
  ),
  // const MapFileData(
  //   url:
  //       "https://dailyflightbuddy.com/mapsforge_examples/Meadowhall Shopping Center.map",
  //   fileName: "Meadowhall Shopping Center.map",
  //   displayedName: "Meadowhall Shopping Center (Indoor)",
  //   initialPositionLat: 53.41388,
  //   initialPositionLong: -1.41063,
  //   indoorZoomOverlay: true,
  //   indoorLevels: {1: 'OG', 0: 'EG'},
  // ),
  // const MapFileData(
  //   url:
  //       "https://dailyflightbuddy.com/mapsforge_examples/Northglenn High School.map",
  //   fileName: "Northglenn High School.map",
  //   displayedName: "Northglenn High School (Indoor)",
  //   initialPositionLat: 39.88039,
  //   initialPositionLong: -104.99388,
  //   indoorZoomOverlay: true,
  //   indoorLevels: {1: 'OG', 0: 'EG'},
  // ),
  const MapFileData(
    url: "https://dailyflightbuddy.com/mapsforge_examples/sachsen.map",
    fileName: "sachsen.map",
    displayedName: "Offline Saxony",
    theme: "assets/render_themes/defaultrender.xml",
    initialPositionLat: 50.81287701030895,
    initialPositionLong: 12.94189453125,
    initialZoomLevel: 12,
  ),
  const MapFileData(
    url: "https://dailyflightbuddy.com/mapsforge_examples/austria.map",
    fileName: "austria.map",
    displayedName: "Offline Austria",
    theme: "assets/render_themes/defaultrender.xml",
    initialPositionLat: 48.089415,
    initialPositionLong: 16.311374,
    initialZoomLevel: 12,
  ),
  const MapFileData(
    url: "https://dailyflightbuddy.com/mapsforge_examples/austria.map",
    fileName: "austria.map",
    displayedName: "Offline Austria Dark mode",
    theme: "assets/render_themes/darkrender.xml",
    initialPositionLat: 48.089415,
    initialPositionLong: 16.311374,
    initialZoomLevel: 12,
  ),
  const MapFileData(
    url: "https://dailyflightbuddy.com/mapsforge_examples/monaco.map",
    fileName: "monaco.map",
    displayedName: "Offline Monaco (Supports web)",
    theme: "assets/render_themes/defaultrender.xml",
    initialPositionLat: 43.7399,
    initialPositionLong: 7.4262,
    initialZoomLevel: 15,
  ),
  const MapFileData(
    url: "https://dailyflightbuddy.com/mapsforge_examples/sicilia_oam.zip",
    fileName:
        "sicilia_oam.map", // will automatically unzipped if the extension of the destination is not .zip
    displayedName: "Contour Sizilia",
    theme: "assets/render_themes/sicilia_oam.xml",
    relativePathPrefix: "sicilia_oam/",
    initialPositionLat: 37.5,
    initialPositionLong: 14.3,
    initialZoomLevel: 15,
  ),
  const MapFileData(
    url: "https://dailyflightbuddy.com/mapsforge_examples/world.map",
    fileName: "world.map",
    displayedName: "Worldmap",
    theme: "assets/render_themes/defaultrender.xml",
    initialPositionLat: 43.7399,
    initialPositionLong: 7.4262,
    initialZoomLevel: 5,
  ),
  // const MapFileData(
  //   url: "https://dailyflightbuddy.com/mapsforge_examples/world.map",
  //   fileName: "world.map",
  //   displayedName: "Worldmap Dark mode",
  //   theme: "assets/render_themes/darkrender.xml",
  //   initialPositionLat: 43.7399,
  //   initialPositionLong: 7.4262,
  //   initialZoomLevel: 5,
  // ),
  const MapFileData(
    url: "https://dailyflightbuddy.com/mapsforge_examples/berlin.map",
    fileName: "berlin.map",
    displayedName: "Berlin with original mapsforge theme",
    theme: "assets/render_themes/mapsforge_default.xml",
    initialPositionLat: 52.52278,
    initialPositionLong: 13.38982,
    initialZoomLevel: 17,
  ),
  // const MapFileData(
  //   url: "assets/test.map",
  //   fileName: "test.map",
  //   displayedName: "Test map",
  //   theme: "assets/render_themes/mapsforge_default.xml",
  //   initialPositionLat: 43.7399,
  //   initialPositionLong: 7.4262,
  //   initialZoomLevel: 15,
  // ),
];

void main() {
  // enableLeakTracking();
  // MemoryAllocations.instance
  //     .addListener((ObjectEvent event) => dispatchObjectEvent(event.toMap()));
  runApp(MyApp());
}

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
