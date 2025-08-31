import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

import '../test_asset_bundle.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _initLogging();
    SymbolCacheMgr().symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle("test/assets")));
  });

  testWidgets('Should draw pathtext from left-bottom to right-top', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    var img = await (tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/mapsforge_flutter_renderer/defaultrender.xml");

      MemoryDatastore datastore = MemoryDatastore();
      // symbol in the center of the poi, name above, ele below
      datastore.addWay(
        const Way(
          0,
          [Tag('highway', 'motorway'), Tag('ref', 'A234')],
          [
            [LatLong(45.998, 17.996), LatLong(46.0006, 18.0006)],
          ],
          null,
        ),
      );
      Tile tile = Tile(x, y, zoomlevel, l);
      JobRequest mapGeneratorJob = JobRequest(tile);
      DatastoreRenderer _dataStoreRenderer = DatastoreRenderer(datastore, renderTheme, true);

      JobResult jobResult = (await (_dataStoreRenderer.executeJob(mapGeneratorJob)));
      expect(jobResult.picture, isNotNull);
      return await jobResult.picture!.convertPictureToImage();
    }));

    expect(img, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 1)),
              child: RawImage(image: img),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(find.byType(RawImage), matchesGoldenFile('goldens/pathtext_lb_rt.png'));
  });

  testWidgets('Should draw pathtext from right-top to left-bottom ', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    var img = await (tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/mapsforge_flutter_renderer/defaultrender.xml");

      MemoryDatastore datastore = MemoryDatastore();
      // symbol in the center of the poi, name above, ele below
      datastore.addWay(
        const Way(
          0,
          [Tag('highway', 'motorway'), Tag('ref', 'A246589')],
          [
            [LatLong(46.0006, 18.0006), LatLong(45.998, 17.996)],
          ],
          null,
        ),
      );
      Tile tile = Tile(x, y, zoomlevel, l);
      JobRequest mapGeneratorJob = JobRequest(tile);
      DatastoreRenderer _dataStoreRenderer = DatastoreRenderer(datastore, renderTheme, true);

      JobResult jobResult = (await (_dataStoreRenderer.executeJob(mapGeneratorJob)));
      expect(jobResult.picture, isNotNull);
      return await jobResult.picture!.convertPictureToImage();
    }));

    expect(img, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 1)),
              child: RawImage(image: img),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(find.byType(RawImage), matchesGoldenFile('goldens/pathtext_rt_lb.png'));
  });

  testWidgets('Should draw pathtext AND linesymbol from right-top to left-bottom ', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    var img = await (tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/mapsforge_flutter_renderer/defaultrender.xml");

      MemoryDatastore datastore = MemoryDatastore();
      // symbol in the center of the poi, name above, ele below
      datastore.addWay(
        const Way(
          0,
          [Tag('highway', 'motorway'), Tag('ref', 'A246589'), Tag('oneway', 'yes')],
          [
            [LatLong(46.0006, 18.0006), LatLong(45.998, 17.996)],
          ],
          null,
        ),
      );
      Tile tile = Tile(x, y, zoomlevel, l);
      JobRequest mapGeneratorJob = JobRequest(tile);
      DatastoreRenderer _dataStoreRenderer = DatastoreRenderer(datastore, renderTheme, true);

      JobResult jobResult = (await (_dataStoreRenderer.executeJob(mapGeneratorJob)));
      expect(jobResult.picture, isNotNull);
      return await jobResult.picture!.convertPictureToImage();
    }));

    expect(img, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 1)),
              child: RawImage(image: img),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(find.byType(RawImage), matchesGoldenFile('goldens/pathtext_symbol_rt_lb.png'));
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
