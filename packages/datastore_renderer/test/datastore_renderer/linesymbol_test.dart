import 'package:dart_common/datastore.dart';
import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/src/cache/file_symbol_cache.dart';
import 'package:datastore_renderer/src/cache/image_bundle_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

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

  testWidgets('Should draw linesymbol from left-bottom to right-top', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    var img = await (tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/datastore_renderer/defaultrender.xml");

      MemoryDatastore datastore = MemoryDatastore();
      // symbol in the center of the poi, name above, ele below
      datastore.addWay(
        const Way(
          0,
          [Tag('highway', 'motorway'), Tag('oneway', 'yes')],
          [
            [LatLong(45.96, 17.953), LatLong(46.0006, 18.0006)],
          ],
          null,
        ),
      );
      Tile tile = Tile(x, y, zoomlevel, l);
      expect(await datastore.supportsTile(tile), true);
      DatastoreBundle result = await datastore.readMapDataSingle(tile);
      expect(result.ways.length, equals(1));
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
    await expectLater(find.byType(RawImage), matchesGoldenFile('goldens/linesymbol_lb_rt.png'));
  });

  testWidgets('Should draw linesymbol from right-top to left-bottom ', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    var img = await (tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/datastore_renderer/defaultrender.xml");

      MemoryDatastore datastore = MemoryDatastore();
      // symbol in the center of the poi, name above, ele below
      datastore.addWay(
        const Way(
          0,
          [Tag('highway', 'motorway'), Tag('oneway', 'yes')],
          [
            [LatLong(46.0004, 18.0006), LatLong(45.95, 17.953)],
          ],
          null,
        ),
      );
      Tile tile = Tile(x, y, zoomlevel, l);
      expect(await datastore.supportsTile(tile), true);
      DatastoreBundle result = await datastore.readMapDataSingle(tile);
      expect(result.ways.length, equals(1));
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
    await expectLater(find.byType(RawImage), matchesGoldenFile('goldens/linesymbol_rt_lb.png'));
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
