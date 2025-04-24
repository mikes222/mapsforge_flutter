import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

///
/// flutter test --update-goldens
///
///
main() async {
  test("MultimapDatastore without maps", () async {
    MultiMapDataStore dataStore = MultiMapDataStore(DataPolicy.RETURN_ALL);

    int zoomlevel = 18; //zoomlevel
    int indoorLevel = 0; // indoor level

    Tile tile = new Tile(140486, 87975, zoomlevel, indoorLevel);

    expect(await dataStore.supportsTile(tile), false);
  });
}
