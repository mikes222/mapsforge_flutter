import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/singlemarkerpainter.dart';
import 'package:mapsforge_flutter/src/view/transform_widget.dart';

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
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);

    CircleMarker circleMarker =
        CircleMarker(center: latLong, displayModel: displayModel);

    MarkerContext markerContext = MarkerContext(
      viewModel.mapViewPosition!.getCenter(),
      viewModel.mapViewPosition!.zoomLevel,
      viewModel.mapViewPosition!.projection,
      viewModel.mapViewPosition!.rotationRadian,
      BoundingBox(latLong.latitude - 0.01, latLong.longitude - 0.01,
          latLong.latitude + 0.01, latLong.longitude + 0.01),
    );
    SingleMarkerPainter painter = SingleMarkerPainter(
      markerContext: markerContext,
      marker: circleMarker,
    );

    await TestHelper.pumpWidget(
        tester: tester,
        child: TransformWidget(
          viewModel: viewModel,
          mapViewPosition: viewModel.mapViewPosition!,
          screensize: Size(800, 600),
          mapCenter: viewModel.mapViewPosition!.getCenter(),
          child: CustomPaint(
            foregroundPainter: painter,
            child: Container(),
          ),
        ),
        goldenfile: 'circlemarker.png');
  });

  testWidgets('Renders a circlemarker with text', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);

    CircleMarker circleMarker = CircleMarker(
      center: latLong,
      displayModel: displayModel,
    )..addCaption(
        caption: 'Markercaption',
        displayModel: displayModel,
      );

    MarkerContext markerContext = MarkerContext(
      viewModel.mapViewPosition!.getCenter(),
      viewModel.mapViewPosition!.zoomLevel,
      viewModel.mapViewPosition!.projection,
      viewModel.mapViewPosition!.rotationRadian,
      BoundingBox(latLong.latitude - 0.01, latLong.longitude - 0.01,
          latLong.latitude + 0.01, latLong.longitude + 0.01),
    );
    SingleMarkerPainter painter = SingleMarkerPainter(
      markerContext: markerContext,
      marker: circleMarker,
    );

    await TestHelper.pumpWidget(
        tester: tester,
        child: TransformWidget(
          viewModel: viewModel,
          mapViewPosition: viewModel.mapViewPosition!,
          screensize: Size(800, 600),
          mapCenter: viewModel.mapViewPosition!.getCenter(),
          child: CustomPaint(
            foregroundPainter: painter,
            child: Container(),
          ),
        ),
        goldenfile: 'circlemarker_text.png');
  });

  testWidgets('Renders a filled circlemarker', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);

    CircleMarker circleMarker = CircleMarker(
        center: latLong,
        fillColor: 0xff00ff00,
        radius: 20,
        strokeWidth: 4,
        displayModel: displayModel);

    MarkerContext markerContext = MarkerContext(
      viewModel.mapViewPosition!.getCenter(),
      viewModel.mapViewPosition!.zoomLevel,
      viewModel.mapViewPosition!.projection,
      viewModel.mapViewPosition!.rotationRadian,
      BoundingBox(latLong.latitude - 0.01, latLong.longitude - 0.01,
          latLong.latitude + 0.01, latLong.longitude + 0.01),
    );
    SingleMarkerPainter painter = SingleMarkerPainter(
      markerContext: markerContext,
      marker: circleMarker,
    );

    await TestHelper.pumpWidget(
        tester: tester,
        child: TransformWidget(
          viewModel: viewModel,
          mapViewPosition: viewModel.mapViewPosition!,
          screensize: Size(800, 600),
          mapCenter: viewModel.mapViewPosition!.getCenter(),
          child: CustomPaint(
            foregroundPainter: painter,
            child: Container(),
          ),
        ),
        goldenfile: 'circlemarker_filled.png');
  });
}
