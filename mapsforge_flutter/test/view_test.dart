import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';

///
/// flutter test --update-goldens
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // I am unable to let the system wait until the tiles have been created so this test is not working.
  // The mapdatastorerenderer is called but the reading of the MapReadResult never succeeds.
  testWidgets('ViewTest', (WidgetTester tester) async {
    _initLogging();
    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );

    String prefix = "../"; // "../";

    MapModel mapModel = await tester.runAsync(() async {
      //String _localPath = await FileHelper.findLocalPath();

      MapFile mapDataStore = MapFile(prefix + "test_resources/monaco.map", null, null);
      await mapDataStore.init();

      GraphicFactory graphicFactory = FlutterGraphicFactory();
      final DisplayModel displayModel = DisplayModel();
      SymbolCache symbolCache = SymbolCache(displayModel);

      RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder(graphicFactory, displayModel, symbolCache);
      final file = new File(prefix + 'test_resources/rendertheme.xml');
      String content = file.readAsStringSync();
      renderThemeBuilder.parseXml(content);
      RenderTheme renderTheme = renderThemeBuilder.build();

      MapDataStoreRenderer _dataStoreRenderer = MapDataStoreRenderer(mapDataStore, renderTheme, graphicFactory, false);

      MemoryTileBitmapCache bitmapCache = MemoryTileBitmapCache();

      MapModel mapModel = MapModel(
        displayModel: displayModel,
        graphicsFactory: graphicFactory,
        renderer: _dataStoreRenderer,
        symbolCache: symbolCache,
        tileBitmapCache: bitmapCache,
      );

      return mapModel;
    });

    mapModel.setMapViewPosition(43.7399, 7.4262);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: FlutterMapView(
              mapModel: mapModel,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    print("Now waiting a while");
    await tester.runAsync(() async {
      sleep(const Duration(seconds: 1));
    });
    await tester.pump();
    print("Wait is over");
    await tester.pump();
    await expectLater(find.byType(FlutterMapView), matchesGoldenFile('view.png'));
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
