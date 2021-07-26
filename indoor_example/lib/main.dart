import 'map-list.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'map-file-data.dart';

// ignore: non_constant_identifier_names
final List<MapFileData> MAP_FILE_DATA_LIST = [
  new MapFileData(
    "https://drive.google.com/uc?export=download&id=1dCEvkRQ2oiAaGGDQFyvFRZKlbtxbvV_X",
    "Chemnitz Uni Gebäude.map",
    "Chemnitz Uni Gebäude",
    50.81352,
    12.92952,
    18,
  ),
  new MapFileData(
    "https://drive.google.com/uc?export=download&id=1HknQgiXyQugU_9fbMn8vUmtzmfqWKohl",
    "Louvre.map",
    "Paris Gare de Lyon",
    48.84432,
    2.37472,
    18,
  ),
  new MapFileData(
    "https://drive.google.com/uc?export=download&id=1HknQgiXyQugU_9fbMn8vUmtzmfqWKohl",
    "Louvre.map",
    "Louvre",
    48.86059,
    2.33805,
    18,
  ),
  new MapFileData(
    "https://drive.google.com/uc?export=download&id=11qpUK-JjutVBwRS1cScS0FcBKK_JOVAy",
    "Meadowhall Shopping Center.map",
    "Meadowhall Shopping Center",
    53.41388,
    -1.41063,
    18,
  ),
  new MapFileData(
    "https://drive.google.com/uc?export=download&id=16yNZdYwS2QlnyrGJWW1fS7eElV_1bw9d",
    "Northglenn High School.map",
    "Northglenn High School",
    39.88039,
    -104.99388,
    18,
  ),
  new MapFileData(
    "https://drive.google.com/uc?export=download&id=1Wx_le6A8SSgh6tJJ_Yw09bF5gMbtnMEv",
    "Haus mit Etagenkürzeln.map",
    "Haus mit Etagenkürzeln",
    49.94771,
    11.57493,
    20,
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
