import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';

import '../testassetbundle.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  testWidgets('Symbol with caption', (WidgetTester tester) async {
    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );

    int tileSize = displayModel.tileSize;
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    SymbolCache symbolCache = FileSymbolCache(
        imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();

    var img = await (tester.runAsync(() async {
      String content = await TestAssetBundle().loadString("rendertheme.xml");
      renderThemeBuilder.parseXml(displayModel, content);
      RenderTheme renderTheme = renderThemeBuilder.build();

      MemoryDatastore datastore = MemoryDatastore();
      // symbol in the center of the poi, name above, ele below
      datastore.addPoi(const PointOfInterest(
          0,
          [
            const Tag('natural', 'peak'),
            Tag('name', 'TestPOI'),
            Tag('ele', '500m')
          ],
          LatLong(46, 18)));
      Tile tile = new Tile(x, y, zoomlevel, l);
      Projection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
      expect(datastore.supportsTile(tile, projection), true);
      DatastoreReadResult result = await datastore.readMapDataSingle(tile);
      //print(result);
      expect(result.ways.length, equals(0));
      expect(result.pointOfInterests.length, greaterThan(0));
      //print("Calculating tile ${tile.toString()}");
      Job mapGeneratorJob = new Job(tile, false, displayModel.tileSize);
      MapDataStoreRenderer _dataStoreRenderer =
          MapDataStoreRenderer(datastore, renderTheme, symbolCache, true);

      JobResult jobResult =
          (await (_dataStoreRenderer.executeJob(mapGeneratorJob)));
      expect(jobResult.bitmap, isNotNull);
      var img = (jobResult.bitmap as FlutterTileBitmap).getClonedImage();
      return img;
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
    await expectLater(
        find.byType(RawImage), matchesGoldenFile('symbol_caption.png'));
  });
}
