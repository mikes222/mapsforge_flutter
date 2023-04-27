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
import '../testhelper.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  testWidgets("Split label between two tiles", (WidgetTester tester) async {
    final DisplayModel displayModel = DisplayModel();

    int l = 0;
    int zoomlevel = 21;
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);
    int x = MercatorProjection.fromZoomlevel(zoomlevel)
        .longitudeToTileX(18); // lat/lon: 43.7399/7.4262;

    SymbolCache symbolCache = FileSymbolCache(
        imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();

    List<dynamic>? imgs = await (tester.runAsync(() async {
      String content = await TestAssetBundle().loadString("rendertheme.xml");
      renderThemeBuilder.parseXml(displayModel, content);
      RenderTheme renderTheme = renderThemeBuilder.build();

      MemoryDatastore datastore = MemoryDatastore();
      // to check if the position of the symbol is correct. One cirlce above, one below, one to the right
      datastore.addPoi(const PointOfInterest(
          0,
          [const Tag('highway', 'turning_circle')],
          LatLong(45.99998, 18.00005)));
      datastore.addPoi(const PointOfInterest(
          0,
          [const Tag('highway', 'turning_circle')],
          LatLong(46.00006, 18.00005)));
      datastore.addPoi(const PointOfInterest(
          0,
          [const Tag('highway', 'turning_circle')],
          LatLong(46.00002, 18.00009)));
      datastore.addPoi(const PointOfInterest(
          0,
          [
            const Tag('natural', 'peak'),
            Tag('name', 'atLeftTile'),
            Tag('ele', '5645')
          ],
          LatLong(46.00002, 18.00005)));

      //datastore.addPoi(PointOfInterest(0, [Tag('highway', 'turning_circle')], LatLong(46.00000, 18.00007)));
      datastore.addPoi(const PointOfInterest(
          0,
          [Tag('place', 'suburb'), Tag('name', 'atRightTile')],
          LatLong(45.99997, 18.00007)));

      Tile tile0 = new Tile(x, y, zoomlevel, l);
      Projection projection = MercatorProjection.fromZoomlevel(tile0.zoomLevel);
      expect(datastore.supportsTile(tile0, projection), true);
      DatastoreReadResult result = await datastore.readMapDataSingle(tile0);
      print(result);
      expect(result.pointOfInterests.length, greaterThan(0));
      print("Calculating tile0 ${tile0.toString()}");
      Job mapGeneratorJob0 = new Job(tile0, false, displayModel.tileSize);
      MapDataStoreRenderer _dataStoreRenderer =
          MapDataStoreRenderer(datastore, renderTheme, symbolCache, true);

      JobResult jobResult0 =
          (await (_dataStoreRenderer.executeJob(mapGeneratorJob0)));
      var img0 = (jobResult0.bitmap as FlutterTileBitmap).getClonedImage();

      _dataStoreRenderer.tileDependencies!.debug();
      //expect(_dataStoreRenderer.tileDependencies!.overlapData[tile0]!.length, greaterThan(0));

      Tile tile1 = new Tile(x + 1, y, zoomlevel, l);
      Job mapGeneratorJob1 = new Job(tile1, false, displayModel.tileSize);
      JobResult jobResult1 =
          (await (_dataStoreRenderer.executeJob(mapGeneratorJob1)));
      var img1 = (jobResult1.bitmap as FlutterTileBitmap).getClonedImage();

      //_dataStoreRenderer.labelStore.debug();
      //_dataStoreRenderer.tileDependencies!.debug();
      //expect(_dataStoreRenderer.tileDependencies!.overlapData[tile1]!.length, greaterThan(0));

      return [img0, img1];
    }));

    assert(imgs != null);

    await TestHelper.pumpWidget(
        tester: tester,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RawImage(image: imgs![0]),
            RawImage(image: imgs[1]),
          ],
        ),
        goldenfile: 'splittedlabel.png');
  });
}
