import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttertilebitmap.dart';
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

  testWidgets('Create one single tile and compare it with golden',
      (WidgetTester tester) async {
    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );

    int tileSize = displayModel.tileSize;
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel)
        .longitudeToTileX(7.4262); // lat/lon: 43.7399/7.4262;
    int y =
        MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(43.7399);

    SymbolCache symbolCache = FileSymbolCache(
        imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();

    var img = await (tester.runAsync(() async {
      String content = await TestAssetBundle().loadString("rendertheme.xml");
      renderThemeBuilder.parseXml(displayModel, content);
      RenderTheme renderTheme = renderThemeBuilder.build();

      Datastore mapDataStore = await MapFile.from(
          TestAssetBundle().correctFilename("monaco.map"), 0, "en");
      Tile tile = new Tile(x, y, zoomlevel, l);
      print("Calculating tile ${tile.toString()}");
      Job mapGeneratorJob = new Job(tile, false, displayModel.tileSize);
      MapDataStoreRenderer _dataStoreRenderer =
          MapDataStoreRenderer(mapDataStore, renderTheme, symbolCache, false);

      JobResult jobResult =
          (await (_dataStoreRenderer.executeJob(mapGeneratorJob)));
      var img = (jobResult.bitmap as FlutterTileBitmap).getClonedImage();
      return img;
    }));

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
    await expectLater(
        find.byType(RawImage), matchesGoldenFile('datastorerenderer.png'));
  });

  testWidgets(
      'Create 9 tiles, assemble them to one image and compare it with golden',
      (WidgetTester tester) async {
    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 15,
    );

    int tileSize = displayModel.tileSize;
    int l = 0;
    int zoomlevel = 15;
    int x = MercatorProjection.fromZoomlevel(zoomlevel)
        .longitudeToTileX(7.4262); // lat/lon: 43.7399/7.4262;
    int y =
        MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(43.7399);

    tester.binding.window.physicalSizeTestValue =
        Size(tileSize * 9, tileSize * 9);
// resets the screen to its orinal size after the test end
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    List<Tile> tilesToLoad = [
      Tile(x - 1, y - 1, zoomlevel, l),
      Tile(x, y - 1, zoomlevel, l),
      Tile(x + 1, y - 1, zoomlevel, l),
      Tile(x - 1, y, zoomlevel, l),
      Tile(x, y, zoomlevel, l),
      Tile(x + 1, y, zoomlevel, l),
      Tile(x - 1, y + 1, zoomlevel, l),
      Tile(x, y + 1, zoomlevel, l),
      Tile(x + 1, y + 1, zoomlevel, l),
    ];

    SymbolCache symbolCache = FileSymbolCache(
        imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();

    List<dynamic>? imgs = await (tester.runAsync(() async {
      String content = await TestAssetBundle().loadString("rendertheme.xml");
      renderThemeBuilder.parseXml(displayModel, content);
      RenderTheme renderTheme = renderThemeBuilder.build();

      Datastore mapDataStore = await MapFile.from(
          TestAssetBundle().correctFilename("monaco.map"), 0, "en");

      MapDataStoreRenderer _dataStoreRenderer =
          MapDataStoreRenderer(mapDataStore, renderTheme, symbolCache, false);
      List imgs = [];
      for (Tile tile in tilesToLoad) {
        print("Calculating tile ${tile.toString()}");
        Job mapGeneratorJob = new Job(tile, false, displayModel.tileSize);
        JobResult jobResult =
            (await (_dataStoreRenderer.executeJob(mapGeneratorJob)));
        expect(jobResult.bitmap, isNotNull);
        var img = (jobResult.bitmap as FlutterTileBitmap).getClonedImage();
        imgs.add(img);
      }

//      ByteData bytes = await img.toByteData(format: ImageByteFormat.png);
//      assert(bytes != null);
      return imgs;
    }));

    assert(imgs != null && imgs.length == tilesToLoad.length);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: SizedBox(
            width: tileSize * 3,
            height: tileSize * 3,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    RawImage(image: imgs![0]),
                    RawImage(image: imgs[1]),
                    RawImage(image: imgs[2]),
                  ],
                ),
                Row(
                  children: <Widget>[
                    RawImage(image: imgs[3]),
                    RawImage(image: imgs[4]),
                    RawImage(image: imgs[5]),
                  ],
                ),
                Row(
                  children: <Widget>[
                    RawImage(image: imgs[6]),
                    RawImage(image: imgs[7]),
                    RawImage(image: imgs[8]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(
        find.byType(SizedBox), matchesGoldenFile('datastorerenderermulti.png'));
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
