import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

import '../testassetbundle.dart';

///
/// ```
/// http://ftp-stud.hs-esslingen.de/pub/Mirrors/download.mapsforge.org/maps/v5/europe/austria.map
/// ```
///
main() async {
  late MapFile mapFile;

  late RenderTheme renderTheme;

  late GraphicFactory graphicFactory;

  late DisplayModel displayModel;

  MapDataStoreRenderer? renderer;

  Future<void> init() async {
    mapFile = await MapFile.from(
        TestAssetBundle().correctFilename("austria.map"),
        null,
        null); //Map that contains part of the Canpus Reichehainer Straße

    displayModel = DisplayModel();
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();
    String content = await TestAssetBundle().loadString("rendertheme.xml");
    renderThemeBuilder.parseXml(displayModel, content);
    renderTheme = renderThemeBuilder.build();
  }

  Future<void> runOnce(int dx, int dy) async {
    SymbolCache symbolCache = FileSymbolCache(
        imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));
    renderer ??= MapDataStoreRenderer(mapFile, renderTheme, symbolCache, true);

    int zoomlevel = 8;
    int x =
        MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(14.545150);
    int y =
        MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(48.469632);
    int indoorLevel = 0;

    //initialize 2 Tiles with the coordinates, zoomlevel and tilesize
    Tile upperLeft = new Tile(x + dx, y + dy, zoomlevel, indoorLevel);
    Job job = Job(upperLeft, false, displayModel.tileSize);
    JobResult result = await renderer!.executeJob(job);
    expect(result.bitmap, isNotNull);
    //print(mapFile.toString());
    //mapFile.dispose();
  }

  test("SingleCallRendererPerformance", () async {
    _initLogging();
    await init();

    int mn = 100000;
    int mx = 0;
    for (int i = 0; i < 10; ++i) {
      int time = DateTime.now().millisecondsSinceEpoch;
      await runOnce(0, 0);
      int diff = DateTime.now().millisecondsSinceEpoch - time;
      mn = min(mn, diff);
      mx = max(mx, diff);
    }
    print("Diff: $mn - $mx   -> 210 - 500 ms on my machine");
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
