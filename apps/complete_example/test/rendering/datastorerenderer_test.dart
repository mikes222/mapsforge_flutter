import 'package:dart_common/datastore.dart';
import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_mapfile/mapfile.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _initLogging();
    //MapsforgeSettingsMgr().strokeIncreaseFactor = 1.5;
  });

  testWidgets('Create one single tile and compare it with golden', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(7.4262); // lat/lon: 43.7399/7.4262;
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(43.7399);

    var img = await (tester.runAsync(() async {
      String renderthemeString = await rootBundle.loadString("assets/render_theme/defaultrender.xml");
      Rendertheme renderTheme = RenderThemeBuilder.createFromString(renderthemeString.toString());

      Datastore mapFile = await MapFile.createFromFile(filename: 'test/rendering/monaco.map', preferredLanguage: null);

      Tile tile = Tile(x, y, zoomlevel, l);
      JobRequest mapGeneratorJob = new JobRequest(tile);
      DatastoreRenderer dataStoreRenderer = DatastoreRenderer(mapFile, renderTheme, true);

      JobResult jobResult = (await (dataStoreRenderer.executeJob(mapGeneratorJob)));
      return await jobResult.picture!.convertPictureToImage();
    }));

    assert(img != null);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(child: RawImage(image: img)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(RawImage), matchesGoldenFile('goldens/datastorerenderer_single.png'));
  });

  testWidgets('Create 9 tiles, assemble them to one image and compare it with golden', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 15;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(7.4262); // lat/lon: 43.7399/7.4262;
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(43.7399);

    tester.binding.window.physicalSizeTestValue = Size(MapsforgeSettingsMgr().tileSize * 9, MapsforgeSettingsMgr().tileSize * 9);
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

    List<dynamic>? imgs = await (tester.runAsync(() async {
      String renderthemeString = await rootBundle.loadString("assets/render_theme/defaultrender.xml");
      Rendertheme renderTheme = RenderThemeBuilder.createFromString(renderthemeString.toString());

      Datastore mapFile = await MapFile.createFromFile(filename: 'test/rendering/monaco.map', preferredLanguage: null);

      Renderer dataStoreRenderer = DatastoreRenderer(mapFile, renderTheme, true);
      List imgs = [];
      for (Tile tile in tilesToLoad) {
        print("Calculating tile ${tile.toString()}");
        JobRequest mapGeneratorJob = JobRequest(tile);
        JobResult jobResult = await (dataStoreRenderer.executeJob(mapGeneratorJob));
        expect(jobResult.picture, isNotNull);
        imgs.add(await jobResult.picture!.convertPictureToImage());
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
            width: MapsforgeSettingsMgr().tileSize * 3,
            height: MapsforgeSettingsMgr().tileSize * 3,
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
    await expectLater(find.byType(SizedBox), matchesGoldenFile('goldens/datastorerenderer_multi.png'));
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
