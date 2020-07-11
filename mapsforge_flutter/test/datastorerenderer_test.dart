import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

///
/// flutter test --update-goldens
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MapDataStoreRenderer', (WidgetTester tester) async {
    _initLogging();
    String prefix = ""; // "../";
    double tileSize = 256;
    int z = 2;
    int x = MercatorProjectionImpl(tileSize, z).longitudeToTileX(43.7399); // lat/lon: 7.42/43.74;
    int y = MercatorProjectionImpl(tileSize, z).latitudeToTileY(7.4262);
    double userScaleFactor = 1;

    print("Creating tile $x/$y");

    GraphicFactory graphicFactory = FlutterGraphicFactory();
    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 9,
    );
    SymbolCache symbolCache = SymbolCache(displayModel);
    RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel, symbolCache);
    final file = new File(prefix + 'test_resources/rendertheme.xml');
    String content = file.readAsStringSync();
    //String content = await rootBundle.loadString("assets/simplerender.xml");
    renderThemeBuilder.parseXml(content);
    RenderTheme renderTheme = renderThemeBuilder.build();

    ByteData bytes = await tester.runAsync(() async {
      MapFile mapDataStore = MapFile(prefix + "test_resources/monaco.map", 0, "en");
      await mapDataStore.init();
      Tile tile = new Tile(x, y, z, tileSize);
      Job mapGeneratorJob = new Job(tile, false, userScaleFactor);
      MapDataStoreRenderer _dataStoreRenderer = MapDataStoreRenderer(mapDataStore, renderTheme, graphicFactory, false);

      TileBitmap resultTile = await _dataStoreRenderer.executeJob(mapGeneratorJob);
      assert(resultTile != null);
      var img = (resultTile as FlutterTileBitmap).bitmap;
      ByteData bytes = await img.toByteData(format: ImageByteFormat.png);
      return bytes;
    });

    assert(bytes != null);
//    print("Resulting tile has ${bytes.buffer.lengthInBytes} byte");
//    File resFile = File("store.png");
//    IOSink sink = resFile.openWrite();
//    resFile.writeAsBytes(bytes.buffer.asUint8List());
//    sink.close();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: Image.memory(bytes.buffer.asUint8List()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(find.byType(Image), matchesGoldenFile('datastorerender.png'));
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
