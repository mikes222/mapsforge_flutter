import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

///
/// flutter test --update-goldens
///
///

import '../test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _initLogging();
    SymbolCacheMgr().symbolCache = FileSymbolCache();
    SymbolCacheMgr().symbolCache.addLoader("jar:", ImageBundleLoader(bundle: TestAssetBundle("test/cache")));
  });

  testWidgets('Creates a custom datastore and renders it', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    var img = await (tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/datastore_renderer/defaultrender.xml");

      MemoryDatastore datastore = MemoryDatastore();
      datastore.addPoi(PointOfInterest(0, [Tag('place', 'suburb'), Tag('name', 'TestSuburb')], LatLong(46, 17.998)));
      datastore.addPoi(PointOfInterest(0, [Tag('highway', 'turning_circle'), Tag('name', 'Test Circle')], LatLong(45.999, 17.996)));
      datastore.addWay(
        Way(
          0,
          [Tag('name', 'TestWay'), Tag('tunnel', 'yes'), Tag('railway', 'rail')],
          [
            [LatLong(45.95, 17.95), LatLong(46.05, 18.05)],
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
    await expectLater(find.byType(RawImage), matchesGoldenFile('goldens/renderer.png'));
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
