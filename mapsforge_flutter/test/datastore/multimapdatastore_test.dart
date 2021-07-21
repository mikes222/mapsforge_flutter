import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/datastorereadresult.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfile.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

import '../testassetbundle.dart';

main() async {
  test("MultimapDatastore without maps", () {
    MultiMapDataStore dataStore = MultiMapDataStore(DataPolicy.RETURN_ALL);

    int zoomlevel = 18; //zoomlevel
    int indoorLevel = 0; // indoor level

    Tile tile = new Tile(140486, 87975, zoomlevel, indoorLevel);
    Projection projection = MercatorProjection.fromZoomlevel(zoomlevel);

    expect(dataStore.supportsTile(tile, projection), false);
  });
}
