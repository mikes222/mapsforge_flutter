import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/layer/job/view_job_request.dart';
import 'package:mapsforge_flutter/src/layer/job/view_job_result.dart';

import '../testassetbundle.dart';

///
/// ```
/// http://ftp-stud.hs-esslingen.de/pub/Mirrors/download.mapsforge.org/maps/v5/europe/austria.map
/// ```
///
main() async {
  test("ViewMapDatastore", () async {
    _initLogging();

    DisplayModel displayModel = DisplayModel();
    MapFile datastore =
        await MapFile.from(TestAssetBundle().correctFilename("campus_level.map"), null, null); //Map that contains part of the Canpus Reichehainer Straße

    SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();
    String content = await TestAssetBundle().loadString("rendertheme.xml");
    renderThemeBuilder.parseXml(displayModel, content);
    RenderTheme renderTheme = renderThemeBuilder.build();

    DatastoreViewRenderer renderer = DatastoreViewRenderer(datastore: datastore, renderTheme: renderTheme, symbolCache: symbolCache);

    int zoomlevel = 18; //zoomlevel
    int indoorLevel = 0; // indoor level

    Tile tile = new Tile(140486, 87975, zoomlevel, indoorLevel);

    ViewJobResult result = await renderer.executeViewJob(ViewJobRequest(upperLeft: tile, lowerRight: tile));
    expect(result.renderContext.labels.length, 2);
    expect(result.renderContext.drawingLayers.length, 11);
    expect(result.renderContext.drawingLayers[0].ways.length, 92);
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
