import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/datastorereadresult.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

import '../testassetbundle.dart';

///
/// ```
/// http://ftp-stud.hs-esslingen.de/pub/Mirrors/download.mapsforge.org/maps/v5/europe/austria.map
/// ```
///
main() async {
  Future<void> runOnce(int dx, int dy) async {
    MapFile mapFile = await MapFile.from(
        TestAssetBundle().correctFilename("austria.map"),
        null,
        null); //Map that contains part of the Canpus Reichehainer Straße

    int zoomlevel = 8;
    int x = MercatorProjection.fromZoomlevel(zoomlevel)
        .longitudeToTileX(14.545150); // lat/lon: 43.7399/7.4262;
    int y =
        MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(48.469632);
    int indoorLevel = 0;

    //initialize 2 Tiles with the coordinates, zoomlevel and tilesize
    Tile upperLeft = new Tile(x + dx, y + dy, zoomlevel, indoorLevel);
    Tile lowerRight = new Tile(x + dx + 1, y + dy + 1, zoomlevel, indoorLevel);

    DatastoreReadResult mapReadResult =
        await mapFile.readMapData(upperLeft, lowerRight);
    //expect(mapReadResult.ways.length, equals(152721));
    //expect(mapReadResult.pointOfInterests.length, equals(3));
    print(mapFile.toString());
    mapFile.dispose();
  }

  Future<void> runOnceSingle(int dx, int dy) async {
    MapFile mapFile = await MapFile.from(
        TestAssetBundle().correctFilename("austria.map"),
        null,
        null); //Map that contains part of the Canpus Reichehainer Straße

    int zoomlevel = 8;
    int x = MercatorProjection.fromZoomlevel(zoomlevel)
        .longitudeToTileX(14.545150); // lat/lon: 43.7399/7.4262;
    int y =
        MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(48.469632);
    int indoorLevel = 0;

    //initialize 2 Tiles with the coordinates, zoomlevel and tilesize
    Tile upperLeft = new Tile(x + dx, y + dy, zoomlevel, indoorLevel);

    DatastoreReadResult mapReadResult =
        await mapFile.readMapDataSingle(upperLeft);
    expect(mapReadResult.ways.length, equals(44956));
    expect(mapReadResult.pointOfInterests.length, equals(1));
    print(mapFile.toString());
    mapFile.dispose();
  }

  test("SingleCallMapSinglePerformance", () async {
    _initLogging();

    int mn = 100000;
    int mx = 0;
    for (int i = 0; i < 10; ++i) {
      int time = DateTime.now().millisecondsSinceEpoch;
      await runOnceSingle(0, 0);
      int diff = DateTime.now().millisecondsSinceEpoch - time;
      mn = min(mn, diff);
      mx = max(mx, diff);
    }
    print("Diff for Single: $mn - $mx   -> 80 - 220 ms on my machine");
  });

  test("SingleCallMapPerformance", () async {
    _initLogging();

    int mn = 100000;
    int mx = 0;
    for (int i = 0; i < 10; ++i) {
      int time = DateTime.now().millisecondsSinceEpoch;
      await runOnce(0, 0);
      int diff = DateTime.now().millisecondsSinceEpoch - time;
      mn = min(mn, diff);
      mx = max(mx, diff);
    }
    print("Diff: $mn - $mx   -> 350 - 500 ms on my machine");
  });

  test("MultipleCallMapPerformance", () async {
    _initLogging();

    int mn = 100000;
    int mx = 0;
    for (int dx = 0; dx < 6; dx += 2) {
      for (int dy = 0; dy < 4; dy += 2) {
        //print("now $dx, $dy");
        int time = DateTime.now().millisecondsSinceEpoch;
        await runOnce(dx - 4, dy - 1);
        int diff = DateTime.now().millisecondsSinceEpoch - time;
        mn = min(mn, diff);
        mx = max(mx, diff);
      }
    }
    print("Diff: $mn - $mx   -> 50 - 250 ms on my machine");
  });
}

/////////////////////////////////////////////////////////////////////////////

void _initLogging() {
// Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  Logger.root.level = Level.FINEST;
}
