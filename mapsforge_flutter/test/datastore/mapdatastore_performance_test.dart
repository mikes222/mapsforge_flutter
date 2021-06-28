import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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
  Future<void> runOnce() async {
    MapFile mapFile = await MapFile.from(
        TestAssetBundle().correctFilename("austria.map"), null, null); //Map that contains part of the Canpus Reichehainer Straße

    int zoomlevel = 8;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(14.545150); // lat/lon: 43.7399/7.4262;
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(48.469632);
    int indoorLevel = 0;

    //initialize 2 Tiles with the coordinates, zoomlevel and tilesize
    Tile upperLeft = new Tile(x, y, zoomlevel, indoorLevel);
    Tile lowerRight = new Tile(x + 1, y + 1, zoomlevel, indoorLevel);

    DatastoreReadResult mapReadResult = await mapFile.readMapData(upperLeft, lowerRight);
    expect(mapReadResult.ways.length, equals(152721));
    expect(mapReadResult.pointOfInterests.length, equals(3));
    print(mapFile.toString());
    mapFile.dispose();
  }

  test("Performance", () async {
    int mn = 100000;
    int mx = 0;
    for (int i = 0; i < 10; ++i) {
      int time = DateTime.now().millisecondsSinceEpoch;
      await runOnce();
      int diff = DateTime.now().millisecondsSinceEpoch - time;
      mn = min(mn, diff);
      mx = max(mx, diff);
    }
    print("Diff: $mn - $mx   -> 396 - 604 ms on my machine");
  });
}
