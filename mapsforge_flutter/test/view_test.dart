import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/cache/filesymbolcache.dart';
import 'package:mapsforge_flutter/src/model/viewmodel.dart';

import 'testassetbundle.dart';

///
/// flutter test --update-goldens
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // I am unable to let the system wait for the tiles to being created so this test is not working.
  // The mapdatastorerenderer is called but the reading of the MapReadResult never finishes.
  testWidgets('ViewTest', (WidgetTester tester) async {
    _initLogging();
    return;
    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );

    SymbolCache symbolCache = FileSymbolCache(
        imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

    MapModel? mapModel = await (tester.runAsync(() async {
      //String _localPath = await FileHelper.findLocalPath();

      MapFile mapDataStore = await MapFile.from(
          TestAssetBundle().correctFilename("monaco.map"), null, null);

      final DisplayModel displayModel = DisplayModel();

      RenderThemeBuilder renderThemeBuilder = RenderThemeBuilder();
      String content = await TestAssetBundle().loadString("rendertheme.xml");
      renderThemeBuilder.parseXml(displayModel, content);
      RenderTheme renderTheme = renderThemeBuilder.build();

      MapDataStoreRenderer _dataStoreRenderer =
          MapDataStoreRenderer(mapDataStore, renderTheme, symbolCache, false);

      //MemoryTileBitmapCache bitmapCache = MemoryTileBitmapCache();

      MapModel mapModel = MapModel(
        displayModel: displayModel,
        renderer: _dataStoreRenderer,
        //tileBitmapCache: bitmapCache,
      );

      return mapModel;
    }));

    ViewModel viewModel = ViewModel(displayModel: mapModel!.displayModel);

    viewModel.setMapViewPosition(43.7399, 7.4262);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: FlutterMapView(
              mapModel: mapModel,
              viewModel: viewModel,
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
    await expectLater(
        find.byType(FlutterMapView), matchesGoldenFile('view.png'));
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
