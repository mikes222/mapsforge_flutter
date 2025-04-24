import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';

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

  testWidgets('Dashed lines', (WidgetTester tester) async {
    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 16,
    );

    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();

    var img = await (tester.runAsync(() async {
      String content = await TestAssetBundle().loadString("rendertheme.xml");
      renderThemeBuilder.parseXml(displayModel, content);
      RenderTheme renderTheme = renderThemeBuilder.build();

      MemoryDatastore datastore = MemoryDatastore();
      // <line stroke="#66320D" stroke-dasharray="20,5,8,5" stroke-linecap="butt" stroke-width="1.2" />
      datastore.addWay(const Way(
          0,
          [Tag('highway', 'track'), Tag('tracktype', 'grade4')],
          [
            [LatLong(45.96, 17.953), LatLong(46.0006, 18.0006)]
          ],
          null));
      //                     <line stroke="#66320D" stroke-dasharray="20,5,8,5" stroke-linecap="butt"
      //                         stroke-width="1.2" />
      //                     <line stroke="#D9D0C7" stroke-dasharray="20,5,8,5" stroke-linecap="butt"
      //                         stroke-width="0.8" />

      Tile tile = new Tile(x, y, zoomlevel, l);
      expect(await datastore.supportsTile(tile), true);
      DatastoreReadResult result = await datastore.readMapDataSingle(tile);
      expect(result.ways.length, equals(1));
      Job mapGeneratorJob = new Job(tile, false);
      MapDataStoreRenderer _dataStoreRenderer = MapDataStoreRenderer(datastore, renderTheme, symbolCache, true);

      JobResult jobResult = (await (_dataStoreRenderer.executeJob(mapGeneratorJob)));
      expect(jobResult.picture, isNotNull);
      return await jobResult.picture!.convertToImage();
    }));

    expect(img, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: RawImage(
                image: img,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(find.byType(RawImage), matchesGoldenFile('dashedline.png'));
  });

  testWidgets('Tunnel lines (tunnel)', (WidgetTester tester) async {
    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 16,
    );

    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();

    var img = await (tester.runAsync(() async {
      String content = await TestAssetBundle().loadString("rendertheme.xml");
      renderThemeBuilder.parseXml(displayModel, content);
      RenderTheme renderTheme = renderThemeBuilder.build();

      MemoryDatastore datastore = MemoryDatastore();
      // <line stroke="#66320D" stroke-dasharray="20,5,8,5" stroke-linecap="butt" stroke-width="1.2" />
      datastore.addWay(const Way(
          0,
          [Tag('highway', 'primary'), Tag('tunnel', 'yes'), Tag('oneway', 'yes')],
          [
            [LatLong(45.96, 17.953), LatLong(46.0006, 18.0006), LatLong(45.991, 17.958)]
          ],
          null));

      //             <line stroke="#80CCCCCC" stroke-dasharray="0,16,6,0" stroke-linecap="butt"
      //                 stroke-width="1.5" />
      //             <line stroke="#60999999" stroke-dasharray="16,6" stroke-linecap="butt"
      //                 stroke-width="1.5" />

      Tile tile = new Tile(x, y, zoomlevel, l);
      expect(await datastore.supportsTile(tile), true);
      DatastoreReadResult result = await datastore.readMapDataSingle(tile);
      expect(result.ways.length, equals(1));
      Job mapGeneratorJob = new Job(tile, false);
      MapDataStoreRenderer _dataStoreRenderer = MapDataStoreRenderer(datastore, renderTheme, symbolCache, true);

      JobResult jobResult = (await (_dataStoreRenderer.executeJob(mapGeneratorJob)));
      expect(jobResult.picture, isNotNull);
      return await jobResult.picture!.convertToImage();
    }));

    expect(img, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: RawImage(
                image: img,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(find.byType(RawImage), matchesGoldenFile('tunnelline.png'));
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
