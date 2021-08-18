import 'map-list.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'map-file-data.dart';

// ignore: non_constant_identifier_names
final List<MapFileData> MAP_FILE_DATA_LIST = [
  new MapFileData(
    url: "https://drive.google.com/uc?export=download&id=1dCEvkRQ2oiAaGGDQFyvFRZKlbtxbvV_X",
    fileName: "Chemnitz Uni Gebäude.map",
    displayedName: "Chemnitz Uni Gebäude",
    initialPositionLat: 50.81352,
    initialPositionLong: 12.92952,
  ),
  new MapFileData(
    url: "https://drive.google.com/uc?export=download&id=1HknQgiXyQugU_9fbMn8vUmtzmfqWKohl",
    fileName: "Louvre.map",
    displayedName: "Paris Gare de Lyon",
    initialPositionLat: 48.84432,
    initialPositionLong: 2.37472,
  ),
  new MapFileData(
    url: "https://drive.google.com/uc?export=download&id=1HknQgiXyQugU_9fbMn8vUmtzmfqWKohl",
    fileName: "Louvre.map",
    displayedName: "Louvre",
    initialPositionLat: 48.86059,
    initialPositionLong: 2.33805,
  ),
  new MapFileData(
    url: "https://drive.google.com/uc?export=download&id=11qpUK-JjutVBwRS1cScS0FcBKK_JOVAy",
    fileName: "Meadowhall Shopping Center.map",
    displayedName: "Meadowhall Shopping Center",
    initialPositionLat: 53.41388,
    initialPositionLong: -1.41063,
  ),
  new MapFileData(
    url: "https://drive.google.com/uc?export=download&id=16yNZdYwS2QlnyrGJWW1fS7eElV_1bw9d",
    fileName: "Northglenn High School.map",
    displayedName: "Northglenn High School",
    initialPositionLat: 39.88039,
    initialPositionLong: -104.99388,
  ),
  new MapFileData(
    url: "https://drive.google.com/uc?export=download&id=1Wx_le6A8SSgh6tJJ_Yw09bF5gMbtnMEv",
    fileName: "Haus mit Etagenkürzeln.map",
    displayedName: "Haus mit Etagenkürzeln",
    initialPositionLat: 49.94771,
    initialPositionLong: 11.57493,
    initialZoomLevel: 20,
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
      home: MapList(MAP_FILE_DATA_LIST),
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
