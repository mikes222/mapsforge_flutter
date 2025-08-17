import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';

import '../testassetbundle.dart';
import '../testhelper.dart';

main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _initLogging();
  });

  testWidgets('Create one single tile and compare it with golden',
      (WidgetTester tester) async {
    //create a mapfile from .map

    var img = await (tester.runAsync(() async {
      MapFile mapFile = await MapFile.from(
          TestAssetBundle().correctFilename("monaco.map"),
          null,
          null); //Map that contains part of the Canpus Reichehainer Straße

      Tile tile = new Tile(17059, 11948, 15, 0);

      DatastoreReadResult mapReadResult = await mapFile.readMapDataSingle(tile);
      assert(mapReadResult.pointOfInterests.length == 8);
      assert(mapReadResult.ways.length == 1273);

      final DisplayModel displayModel = DisplayModel();
      RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();

      String content = await TestAssetBundle().loadString("rendertheme.xml");
      renderThemeBuilder.parseXml(displayModel, content);
      RenderTheme renderTheme = renderThemeBuilder.build();

      Datastore mapDataStore = await MapFile.from(
          TestAssetBundle().correctFilename("monaco.map"), 0, "en");
      Job mapGeneratorJob = new Job(tile, false);
      SymbolCache symbolCache = FileSymbolCache(
          imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));
      MapDataStoreRenderer _dataStoreRenderer =
          MapDataStoreRenderer(mapDataStore, renderTheme, symbolCache, false);

      JobResult jobResult =
          (await (_dataStoreRenderer.executeJob(mapGeneratorJob)));
      return await jobResult.picture!.convertToImage();
    }));

    assert(img != null);

    await TestHelper.pumpWidget(
        tester: tester,
        child: RawImage(
          image: img,
        ),
        goldenfile: "mapdatastore_largetile.png");
  });
}

/////////////////////////////////////////////////////////////////////////////

void _initLogging() {
// Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  Logger.root.level = Level.FINEST;
}
