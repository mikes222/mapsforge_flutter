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

  testWidgets('Creates a custom datastore and renders it', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    var img = await (tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/datastore_renderer/defaultrender.xml");

      MemoryDatastore datastore = MemoryDatastore();
      datastore.addPoi(const PointOfInterest(0, [const Tag('place', 'suburb'), Tag('name', 'TestSuburb')], LatLong(46, 17.998)));
      datastore.addPoi(const PointOfInterest(0, [const Tag('highway', 'turning_circle'), Tag('name', 'Test Circle')], LatLong(45.999, 17.996)));
      datastore.addWay(
        const Way(
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
