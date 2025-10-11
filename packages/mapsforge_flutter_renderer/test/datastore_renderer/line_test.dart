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
    SymbolCacheMgr().symbolCache = FileSymbolCache();
    SymbolCacheMgr().symbolCache.addLoader("jar:", ImageBundleLoader(bundle: TestAssetBundle("test/assets")));
  });

  testWidgets('Dashed lines', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    var img = await (tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/datastore_renderer/defaultrender.xml");

      MemoryDatastore datastore = MemoryDatastore();
      // <line stroke="#66320D" stroke-dasharray="20,5,8,5" stroke-linecap="butt" stroke-width="1.2" />
      datastore.addWay(
        Way(
          0,
          [const Tag('highway', 'track'), const Tag('tracktype', 'grade4')],
          [
            [const LatLong(45.96, 17.953), const LatLong(46.0006, 18.0006)],
          ],
          null,
        ),
      );
      //                     <line stroke="#66320D" stroke-dasharray="20,5,8,5" stroke-linecap="butt"
      //                         stroke-width="1.2" />
      //                     <line stroke="#D9D0C7" stroke-dasharray="20,5,8,5" stroke-linecap="butt"
      //                         stroke-width="0.8" />

      Tile tile = Tile(x, y, zoomlevel, l);
      JobRequest mapGeneratorJob = JobRequest(tile);
      DatastoreRenderer dataStoreRenderer = DatastoreRenderer(datastore, renderTheme, useSeparateLabelLayer: false);

      JobResult jobResult = (await (dataStoreRenderer.executeJob(mapGeneratorJob)));
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
    await expectLater(find.byType(RawImage), matchesGoldenFile('goldens/line_dashed.png'));
  });

  testWidgets('Tunnel lines (tunnel)', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    var img = await (tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/datastore_renderer/defaultrender.xml");

      MemoryDatastore datastore = MemoryDatastore();
      // <line stroke="#66320D" stroke-dasharray="20,5,8,5" stroke-linecap="butt" stroke-width="1.2" />
      datastore.addWay(
        Way(
          0,
          [const Tag('highway', 'primary'), const Tag('tunnel', 'yes'), const Tag('oneway', 'yes')],
          [
            [const LatLong(45.96, 17.953), const LatLong(46.0006, 18.0006), const LatLong(45.991, 17.958)],
          ],
          null,
        ),
      );

      //             <line stroke="#80CCCCCC" stroke-dasharray="0,16,6,0" stroke-linecap="butt"
      //                 stroke-width="1.5" />
      //             <line stroke="#60999999" stroke-dasharray="16,6" stroke-linecap="butt"
      //                 stroke-width="1.5" />

      Tile tile = Tile(x, y, zoomlevel, l);
      JobRequest mapGeneratorJob = JobRequest(tile);
      DatastoreRenderer dataStoreRenderer = DatastoreRenderer(datastore, renderTheme, useSeparateLabelLayer: false);

      JobResult jobResult = (await (dataStoreRenderer.executeJob(mapGeneratorJob)));
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
    await expectLater(find.byType(RawImage), matchesGoldenFile('goldens/line_dashed_tunnel.png'));
  });

  testWidgets('Line with pattern', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    var img = await (tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/datastore_renderer/defaultrender.xml");

      MemoryDatastore datastore = MemoryDatastore();
      datastore.addWay(
        Way(
          0,
          [
            const Tag('highway', 'service'),
            const Tag('access', 'private'),
            //Tag('name', 'highwayService'),
          ],
          [
            [const LatLong(45.998, 17.95), const LatLong(45.998, 18.05)],
          ],
          null,
        ),
      );
      Tile tile = Tile(x, y, zoomlevel, l);
      JobRequest mapGeneratorJob = JobRequest(tile);
      DatastoreRenderer dataStoreRenderer = DatastoreRenderer(datastore, renderTheme, useSeparateLabelLayer: false);

      JobResult jobResult = (await (dataStoreRenderer.executeJob(mapGeneratorJob)));
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
    await expectLater(find.byType(RawImage), matchesGoldenFile('goldens/line_pattern.png'));
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
