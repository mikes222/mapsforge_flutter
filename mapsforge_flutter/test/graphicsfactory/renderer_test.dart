import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/cache/filesymbolcache.dart';
import 'package:mapsforge_flutter/src/datastore/datastore.dart';
import 'package:mapsforge_flutter/src/datastore/datastorereadresult.dart';
import 'package:mapsforge_flutter/src/datastore/memorydatastore.dart';
import 'package:mapsforge_flutter/src/datastore/way.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

import '../testassetbundle.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _initLogging();
  });

  testWidgets('Creates a custom datastore and renders it', (WidgetTester tester) async {
    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );

    double tileSize = displayModel.tileSize;
    int l = 0;
    int z = 16;
    int x = MercatorProjectionImpl(tileSize, z).longitudeToTileX(18);
    int y = MercatorProjectionImpl(tileSize, z).latitudeToTileY(46);

    SymbolCache symbolCache = FileSymbolCache(TestAssetBundle());
    GraphicFactory graphicFactory = FlutterGraphicFactory(symbolCache);
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel);

    var img = await tester.runAsync(() async {
      String content = await TestAssetBundle().loadString("rendertheme.xml");
      renderThemeBuilder.parseXml(content);
      RenderTheme renderTheme = renderThemeBuilder.build();

      MemoryDatastore datastore = MemoryDatastore();
      datastore.addPoi(PointOfInterest(0, [Tag('natural', 'peak'), Tag('name', 'TestPOI')], LatLong(46, 18)));
      datastore.addPoi(PointOfInterest(0, [Tag('place', 'suburb'), Tag('name', 'TestSuburb')], LatLong(46, 17.998)));
      datastore.addPoi(PointOfInterest(0, [Tag('highway', 'turning_circle'), Tag('name', 'Test Circle')], LatLong(45.999, 17.996)));
      datastore.addWay(Way(
          0,
          [Tag('name', 'TestWay'), Tag('tunnel', 'yes'), Tag('railway', 'rail')],
          [
            [LatLong(45.95, 17.95), LatLong(46.05, 18.05)]
          ],
          null));
      datastore.addWay(Way(
          0,
          [
            Tag('highway', 'service'),
            Tag('access', 'private'),
          ],
          [
            [LatLong(45.998, 17.95), LatLong(45.998, 18.05)]
          ],
          null));
      await datastore.init();
      Tile tile = new Tile(x, y, z, l);
      assert(datastore.supportsTile(tile), true);
      DatastoreReadResult result = await datastore.readMapDataSingle(tile);
      print(result);
      assert(result.ways.length > 0);
      assert(result.pointOfInterests.length > 0);
      print("Calculating tile ${tile.toString()}");
      Job mapGeneratorJob = new Job(tile, false, displayModel.getUserScaleFactor(), displayModel.tileSize);
      MapDataStoreRenderer _dataStoreRenderer = MapDataStoreRenderer(datastore, renderTheme, graphicFactory, true);

      TileBitmap resultTile = await _dataStoreRenderer.executeJob(mapGeneratorJob);
      assert(resultTile != null);
      var img = (resultTile as FlutterTileBitmap).bitmap;
      return img;
    });

    assert(img != null);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: RawImage(
              image: img,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(find.byType(RawImage), matchesGoldenFile('renderer.png'));
  });
}

void _initLogging() {
// Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });

// Root logger level.
  Logger.root.level = Level.FINEST;
}
