import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/singlemarkerpainter.dart';

import '../testassetbundle.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _initLogging();
  });

  testWidgets('Renders a circlemarker', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setViewDimension(800, 600);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);
    viewModel.mapViewPosition!.calculateBoundingBox(viewModel.viewDimension);

    CircleMarker circleMarker =
        CircleMarker(center: latLong, displayModel: displayModel);

    SingleMarkerPainter painter = SingleMarkerPainter(
        mapViewPosition: viewModel.mapViewPosition!,
        displayModel: displayModel,
        marker: circleMarker,
        viewModel: viewModel);

    Key key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: Container(
              key: key,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: CustomPaint(
                foregroundPainter: painter,
                child: Container(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(find.byKey(key), matchesGoldenFile('circlemarker.png'));
  });

  testWidgets('Renders a filled circlemarker', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setViewDimension(800, 600);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);
    viewModel.mapViewPosition!.calculateBoundingBox(viewModel.viewDimension);

    SymbolCache symbolCache = FileSymbolCache(
        imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));
    CircleMarker circleMarker = CircleMarker(
        center: latLong,
        fillColor: 0xff00ff00,
        radius: 20,
        strokeWidth: 4,
        displayModel: displayModel);

    SingleMarkerPainter painter = SingleMarkerPainter(
      mapViewPosition: viewModel.mapViewPosition!,
      displayModel: displayModel,
      marker: circleMarker,
      viewModel: viewModel,
    );

    Key key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: Container(
              key: key,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: CustomPaint(
                foregroundPainter: painter,
                child: Container(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(
        find.byKey(key), matchesGoldenFile('circlemarker_filled.png'));
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
