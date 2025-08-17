import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';

import '../testassetbundle.dart';

///
/// ```
/// http://ftp-stud.hs-esslingen.de/pub/Mirrors/download.mapsforge.org/maps/v5/europe/austria.map
/// ```
///
main() async {
  test("MultimapDatastore without maps", () async {
    _initLogging();

    DisplayModel displayModel = DisplayModel();
    MultiMapDataStore dataStore = MultiMapDataStore(DataPolicy.RETURN_ALL);

    SymbolCache symbolCache = FileSymbolCache(
        imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();
    String content = await TestAssetBundle().loadString("rendertheme.xml");
    renderThemeBuilder.parseXml(displayModel, content);
    RenderTheme renderTheme = renderThemeBuilder.build();

    MapDataStoreRenderer renderer =
        MapDataStoreRenderer(dataStore, renderTheme, symbolCache, true);

    int zoomlevel = 18; //zoomlevel
    int indoorLevel = 0; // indoor level

    Tile tile = new Tile(140486, 87975, zoomlevel, indoorLevel);

    Job job = Job(tile, false);
    JobResult result = await renderer.executeJob(job);
    expect(result.result, JOBRESULT.UNSUPPORTED);
    expect(result.picture, isNotNull);
  });

  test("MapDatastore", () async {
    _initLogging();

    DisplayModel displayModel = DisplayModel();
    MapFile datastore = await MapFile.from(
        TestAssetBundle().correctFilename("campus_level.map"),
        null,
        null); //Map that contains part of the Canpus Reichehainer Straße

    SymbolCache symbolCache = FileSymbolCache(
        imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();
    String content = await TestAssetBundle().loadString("rendertheme.xml");
    renderThemeBuilder.parseXml(displayModel, content);
    RenderTheme renderTheme = renderThemeBuilder.build();

    MapDataStoreRenderer renderer =
        MapDataStoreRenderer(datastore, renderTheme, symbolCache, false);

    int zoomlevel = 18; //zoomlevel
    int indoorLevel = 0; // indoor level

    Tile tile = new Tile(140486, 87975, zoomlevel, indoorLevel);

    Job job = Job(tile, false);
    JobResult result = await renderer.executeJob(job);
    expect(result.renderInfos!.length, 2);
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
