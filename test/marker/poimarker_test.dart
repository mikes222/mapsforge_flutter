import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/singlemarkerpainter.dart';
import 'package:mapsforge_flutter/src/view/transform_widget.dart';

import '../testassetbundle.dart';
import '../testhelper.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  testWidgets('Renders a poimarker', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);
    SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);

    PoiMarker circleMarker = PoiMarker(
      latLong: latLong,
      displayModel: displayModel,
      src: "jar:symbols/tourist/view_point.svg",
      width: 200,
      height: 200,
    );
    await tester.runAsync(() async {
      await circleMarker.initResources(symbolCache);
    });

    MarkerContext markerContext = MarkerContext(
      viewModel.mapViewPosition!.getCenter(),
      viewModel.mapViewPosition!.zoomLevel,
      viewModel.mapViewPosition!.projection,
      viewModel.mapViewPosition!.rotationRadian,
      BoundingBox(latLong.latitude - 0.01, latLong.longitude - 0.01, latLong.latitude + 0.01, latLong.longitude + 0.01),
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
        goldenfile: 'poimarker.png');
  });

  testWidgets('Renders a poimarker bottom-center', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);
    SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);

    PoiMarker circleMarker = PoiMarker(
      latLong: latLong,
      displayModel: displayModel,
      src: "jar:symbols/tourist/view_point.svg",
      width: 200,
      height: 200,
      position: Position.BELOW,
    );
    await tester.runAsync(() async {
      await circleMarker.initResources(symbolCache);
    });

    MarkerContext markerContext = MarkerContext(
      viewModel.mapViewPosition!.getCenter(),
      viewModel.mapViewPosition!.zoomLevel,
      viewModel.mapViewPosition!.projection,
      viewModel.mapViewPosition!.rotationRadian,
      BoundingBox(latLong.latitude - 0.01, latLong.longitude - 0.01, latLong.latitude + 0.01, latLong.longitude + 0.01),
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
        goldenfile: 'poimarker_bottomcenter.png');
  });

  testWidgets('Renders a poimarker bottom-center with text', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);
    SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);

    PoiMarker circleMarker = PoiMarker(
      latLong: latLong,
      displayModel: displayModel,
      src: "jar:symbols/tourist/view_point.svg",
      width: 200,
      height: 200,
      position: Position.BELOW,
    )..addCaption(caption: "PoiMarker with text", displayModel: displayModel);
    await tester.runAsync(() async {
      await circleMarker.initResources(symbolCache);
    });

    MarkerContext markerContext = MarkerContext(
      viewModel.mapViewPosition!.getCenter(),
      viewModel.mapViewPosition!.zoomLevel,
      viewModel.mapViewPosition!.projection,
      viewModel.mapViewPosition!.rotationRadian,
      BoundingBox(latLong.latitude - 0.01, latLong.longitude - 0.01, latLong.latitude + 0.01, latLong.longitude + 0.01),
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
        goldenfile: 'poimarker_bottomcenter_text.png');
  });

  testWidgets('Renders a poimarker bottom-center with text above', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);
    SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);

    PoiMarker circleMarker = PoiMarker(
      latLong: latLong,
      displayModel: displayModel,
      src: "jar:symbols/tourist/view_point.svg",
      width: 200,
      height: 200,
      position: Position.BELOW,
    )..addCaption(caption: "PoiMarker with text", displayModel: displayModel, position: Position.ABOVE);
    await tester.runAsync(() async {
      await circleMarker.initResources(symbolCache);
    });

    MarkerContext markerContext = MarkerContext(
      viewModel.mapViewPosition!.getCenter(),
      viewModel.mapViewPosition!.zoomLevel,
      viewModel.mapViewPosition!.projection,
      viewModel.mapViewPosition!.rotationRadian,
      BoundingBox(latLong.latitude - 0.01, latLong.longitude - 0.01, latLong.latitude + 0.01, latLong.longitude + 0.01),
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
        goldenfile: 'poimarker_bottomcenter_text_above.png');
  });

  testWidgets('Renders a poimarker bottom-center with text left', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);
    SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);

    PoiMarker circleMarker = PoiMarker(
      latLong: latLong,
      displayModel: displayModel,
      src: "jar:symbols/tourist/view_point.svg",
      width: 200,
      height: 200,
      position: Position.BELOW,
    )..addCaption(caption: "PoiMarker with text", displayModel: displayModel, position: Position.LEFT);
    await tester.runAsync(() async {
      await circleMarker.initResources(symbolCache);
    });

    MarkerContext markerContext = MarkerContext(
      viewModel.mapViewPosition!.getCenter(),
      viewModel.mapViewPosition!.zoomLevel,
      viewModel.mapViewPosition!.projection,
      viewModel.mapViewPosition!.rotationRadian,
      BoundingBox(latLong.latitude - 0.01, latLong.longitude - 0.01, latLong.latitude + 0.01, latLong.longitude + 0.01),
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
        goldenfile: 'poimarker_bottomcenter_text_left.png');
  });

  testWidgets('Renders a poimarker with text', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);
    SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);

    PoiMarker circleMarker = PoiMarker(
      latLong: latLong,
      displayModel: displayModel,
      src: "jar:symbols/tourist/view_point.svg",
    )..addCaption(caption: "Markercaption", displayModel: displayModel);
    await tester.runAsync(() async {
      await circleMarker.initResources(symbolCache);
    });

    MarkerContext markerContext = MarkerContext(
      viewModel.mapViewPosition!.getCenter(),
      viewModel.mapViewPosition!.zoomLevel,
      viewModel.mapViewPosition!.projection,
      viewModel.mapViewPosition!.rotationRadian,
      BoundingBox(latLong.latitude - 0.01, latLong.longitude - 0.01, latLong.latitude + 0.01, latLong.longitude + 0.01),
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
        goldenfile: 'poimarker_text.png');
  });

  testWidgets('Renders a poimarker with multiple captions', (WidgetTester tester) async {
    ILatLong latLong = const LatLong(46, 18);
    SymbolCache symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle()));

    final DisplayModel displayModel = DisplayModel(
      maxZoomLevel: 14,
    );
    ViewModel viewModel = ViewModel(displayModel: displayModel);
    viewModel.setMapViewPosition(latLong.latitude, latLong.longitude);

    PoiMarker circleMarker = PoiMarker(
      latLong: latLong,
      displayModel: displayModel,
      src: "jar:symbols/tourist/view_point.svg",
    )
      ..addCaption(caption: "Markercaption", displayModel: displayModel)
      ..addCaption(caption: "Markercaption", displayModel: displayModel, fontSize: 16, position: Position.ABOVE)
      ..addCaption(caption: "Markercaption", displayModel: displayModel, fontSize: 8, position: Position.RIGHT);
    await tester.runAsync(() async {
      await circleMarker.initResources(symbolCache);
    });

    MarkerContext markerContext = MarkerContext(
      viewModel.mapViewPosition!.getCenter(),
      viewModel.mapViewPosition!.zoomLevel,
      viewModel.mapViewPosition!.projection,
      viewModel.mapViewPosition!.rotationRadian,
      BoundingBox(latLong.latitude - 0.01, latLong.longitude - 0.01, latLong.latitude + 0.01, latLong.longitude + 0.01),
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
        goldenfile: 'poimarker_multiple_captions.png');
  });
}
