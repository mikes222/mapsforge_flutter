import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/singlemarkerpainter.dart';

import '../testassetbundle.dart';
import '../testhelper.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  testWidgets('Renders a circlemarker', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setViewDimension(800, 600);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);
    viewModel.mapViewPosition!.calculateBoundingBox(viewModel.mapDimension);

    CircleMarker circleMarker =
        CircleMarker(center: latLong, displayModel: displayModel);

    SingleMarkerPainter painter = SingleMarkerPainter(
        mapViewPosition: viewModel.mapViewPosition!,
        displayModel: displayModel,
        marker: circleMarker,
        viewModel: viewModel);

    await TestHelper.pumpWidget(
        tester: tester,
        child: CustomPaint(
          foregroundPainter: painter,
          child: Container(),
        ),
        goldenfile: 'circlemarker.png');
  });

  testWidgets('Renders a circlemarker with text', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setViewDimension(800, 600);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);
    viewModel.mapViewPosition!.calculateBoundingBox(viewModel.mapDimension);

    CircleMarker circleMarker = CircleMarker(
        center: latLong,
        displayModel: displayModel,
        markerCaption:
            MarkerCaption(displayModel: displayModel, text: "Markercaption"));

    SingleMarkerPainter painter = SingleMarkerPainter(
        mapViewPosition: viewModel.mapViewPosition!,
        displayModel: displayModel,
        marker: circleMarker,
        viewModel: viewModel);

    await TestHelper.pumpWidget(
        tester: tester,
        child: CustomPaint(
          foregroundPainter: painter,
          child: Container(),
        ),
        goldenfile: 'circlemarker_text.png');
  });

  testWidgets('Renders a filled circlemarker', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setViewDimension(800, 600);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);
    viewModel.mapViewPosition!.calculateBoundingBox(viewModel.mapDimension);

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

    await TestHelper.pumpWidget(
        tester: tester,
        child: CustomPaint(
          foregroundPainter: painter,
          child: Container(),
        ),
        goldenfile: 'circlemarker_filled.png');
  });
}
