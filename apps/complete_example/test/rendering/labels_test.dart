import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check labels test', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 20;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(7.42238); // lat/lon: 43.73954/7.42238;
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(43.73954);

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

      Datastore mapFile = await Mapfile.createFromFile(filename: 'test/rendering/monaco.map', preferredLanguage: null);

      Renderer dataStoreRenderer = DatastoreRenderer(mapFile, renderTheme, useSeparateLabelLayer: false);
      List imgs = [];
      for (Tile tile in tilesToLoad) {
        print("Calculating tile ${tile.toString()}");
        JobRequest mapGeneratorJob = JobRequest(tile);
        JobResult jobResult = await (dataStoreRenderer.executeJob(mapGeneratorJob));
        expect(jobResult.picture, isNotNull);
        imgs.add(await jobResult.picture!.convertPictureToImage());
      }

      return imgs;
    }));

    assert(imgs != null && imgs.length == tilesToLoad.length);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: Column(
              children: [
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
    await expectLater(find.byType(Center), matchesGoldenFile('goldens/labels.png'));
  });
}
