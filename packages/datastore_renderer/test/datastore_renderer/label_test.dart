import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/cache.dart';
import 'package:datastore_renderer/renderer.dart';
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

  testWidgets("Split label between two tiles", (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 21;
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18); // lat/lon: 43.7399/7.4262;

    List<dynamic>? imgs = await (tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/datastore_renderer/defaultrender.xml");

      MemoryDatastore datastore = MemoryDatastore();
      // to check if the position of the symbol is correct. One cirlce above, one below, one to the right
      datastore.addPoi(const PointOfInterest(0, [Tag('highway', 'turning_circle')], LatLong(45.99998, 18.00005)));
      datastore.addPoi(const PointOfInterest(0, [Tag('highway', 'turning_circle')], LatLong(46.00006, 18.00005)));
      datastore.addPoi(const PointOfInterest(0, [Tag('highway', 'turning_circle')], LatLong(46.00002, 18.00009)));
      datastore.addPoi(const PointOfInterest(0, [Tag('natural', 'peak'), Tag('name', 'atLeftTile'), Tag('ele', '5645')], LatLong(46.00002, 18.00005)));

      //datastore.addPoi(PointOfInterest(0, [Tag('highway', 'turning_circle')], LatLong(46.00000, 18.00007)));
      datastore.addPoi(const PointOfInterest(0, [Tag('place', 'suburb'), Tag('name', 'atRightTile')], LatLong(45.99997, 18.00007)));

      Tile tile0 = Tile(x, y, zoomlevel, l);
      JobRequest mapGeneratorJob0 = JobRequest(tile0);
      DatastoreRenderer dataStoreRenderer = DatastoreRenderer(datastore, renderTheme, true);

      JobResult jobResult0 = (await (dataStoreRenderer.executeJob(mapGeneratorJob0)));
      var img0 = await jobResult0.picture!.convertPictureToImage();

      dataStoreRenderer.tileDependencies!.debug();

      Tile tile1 = Tile(x + 1, y, zoomlevel, l);
      JobRequest mapGeneratorJob1 = JobRequest(tile1);
      JobResult jobResult1 = (await (dataStoreRenderer.executeJob(mapGeneratorJob1)));
      var img1 = await jobResult1.picture!.convertPictureToImage();

      //_dataStoreRenderer.labelStore.debug();
      //_dataStoreRenderer.tileDependencies!.debug();
      //expect(_dataStoreRenderer.tileDependencies!.overlapData[tile1]!.length, greaterThan(0));

      return [img0, img1];
    }));

    assert(imgs != null);

    Key key = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 1)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                key: key,
                children: [
                  RawImage(image: imgs![0]),
                  RawImage(image: imgs[1]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/label_splitted.png'));
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
