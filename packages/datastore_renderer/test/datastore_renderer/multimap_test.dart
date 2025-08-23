import 'package:dart_common/model.dart';
import 'package:dart_mapfile/src/multimapdatastore.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/src/cache/file_symbol_cache.dart';
import 'package:datastore_renderer/src/cache/image_bundle_loader.dart';
import 'package:datastore_renderer/src/datastore_renderer.dart';
import 'package:datastore_renderer/src/job/job_request.dart';
import 'package:datastore_renderer/src/job/job_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

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

  test("MultimapDatastore without maps", () async {
    _initLogging();

    MultiMapDataStore dataStore = MultiMapDataStore(DataPolicy.RETURN_ALL);

    Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/datastore_renderer/defaultrender.xml");

    DatastoreRenderer renderer = DatastoreRenderer(dataStore, renderTheme, true);

    int zoomlevel = 18; //zoomlevel
    int indoorLevel = 0; // indoor level

    Tile tile = new Tile(140486, 87975, zoomlevel, indoorLevel);

    JobRequest job = JobRequest(tile);
    JobResult result = await renderer.executeJob(job);
    expect(result.result, JOBRESULT.UNSUPPORTED);
    expect(result.picture, isNotNull);
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
