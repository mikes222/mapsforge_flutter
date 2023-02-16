import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/singlemarkerpainter.dart';

import '../testassetbundle.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  testWidgets('Renders a poimarker', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);
    SymbolCache symbolCache = FileSymbolCache(
        imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setViewDimension(800, 600);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);
    viewModel.mapViewPosition!.calculateBoundingBox(viewModel.mapDimension);

    PoiMarker circleMarker = PoiMarker(
        latLong: latLong,
        displayModel: displayModel,
        src: "jar:symbols/tourist/view_point.svg");
    await circleMarker.initResources(symbolCache);

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
    await expectLater(find.byKey(key), matchesGoldenFile('poimarker.png'));
  });

  testWidgets('Renders a poimarker with text', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);
    SymbolCache symbolCache = FileSymbolCache(
        imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setViewDimension(800, 600);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);
    viewModel.mapViewPosition!.calculateBoundingBox(viewModel.mapDimension);

    PoiMarker circleMarker = PoiMarker(
        latLong: latLong,
        displayModel: displayModel,
        src: "jar:symbols/tourist/view_point.svg",
        markerCaption:
            MarkerCaption(displayModel: displayModel, text: "Markercaption"));
    await circleMarker.initResources(symbolCache);

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
    await expectLater(find.byKey(key), matchesGoldenFile('poimarker_text.png'));
  });
}
