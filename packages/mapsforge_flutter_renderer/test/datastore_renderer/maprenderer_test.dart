import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

import '../test_asset_bundle.dart';

///
/// ```
/// http://ftp-stud.hs-esslingen.de/pub/Mirrors/download.mapsforge.org/maps/v5/europe/austria.map
/// ```
///
main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _initLogging();
    SymbolCacheMgr().symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle("test/assets")));
  });

  test("MapDatastore", () async {
    _initLogging();

    Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/mapsforge_flutter_renderer/defaultrender.xml");

    // todo move to a package where this package and mapfile package is available
    // Datastore datastore = await MapFile.from("campus_level.map");
    // DatastoreRenderer renderer = DatastoreRenderer(datastore, renderTheme, true);
    //
    // int zoomlevel = 18; //zoomlevel
    // int indoorLevel = 0; // indoor level
    //
    // Tile tile = Tile(140486, 87975, zoomlevel, indoorLevel);
    //
    // JobRequest job = JobRequest(tile);
    // JobResult result = await renderer.executeJob(job);
    // expect(result.renderInfo!.length, 2);
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
