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
  testWidgets('Renders a rectmarker', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);

    RectMarker circleMarker = RectMarker(
        minLatLon: const LatLong(45.97, 17.9),
        maxLatLon: const LatLong(46.03, 18.1),
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
          centerTile: viewModel.mapViewPosition!.getCenter(),
          child: CustomPaint(
            foregroundPainter: painter,
            child: Container(),
          ),
        ),
        goldenfile: 'rectmarker.png');
  });
}
