import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/marker/markercontext.dart';

///
/// The flutter-derived class to paint one single markers in the visible canvas area
///
class SingleMarkerPainter extends CustomPainter {
  final MapViewPosition mapViewPosition;

  final DisplayModel displayModel;

  final BasicMarker marker;

  final ViewModel viewModel;

  SingleMarkerPainter({
    required this.mapViewPosition,
    required this.displayModel,
    required this.marker,
    required this.viewModel,
  }) : super();

  @override
  void paint(Canvas canvas, Size size) {
    FlutterCanvas flutterCanvas = FlutterCanvas(canvas,
        Size(viewModel.mapDimension.width, viewModel.mapDimension.height));
    flutterCanvas.setClip(
        0, 0, viewModel.mapDimension.width, viewModel.mapDimension.height);

    if (viewModel.viewScaleFactor != 1) {
      (flutterCanvas).uiCanvas.save();
      flutterCanvas.scale(
          const Mappoint(/*viewModel.viewDimension.width / 2*/ 0,
              /*viewModel.viewDimension.height / 2*/ 0),
          1 / viewModel.viewScaleFactor);
    }
    if (mapViewPosition.scale != 1 && mapViewPosition.focalPoint != null) {
      //_log.info("scaling to ${mapViewPosition.scale} around ${mapViewPosition.focalPoint}");
      (flutterCanvas).uiCanvas.save();
      flutterCanvas.scale(mapViewPosition.focalPoint!, mapViewPosition.scale);
    }

    MarkerContext context = MarkerContext(
        flutterCanvas, mapViewPosition, viewModel.viewScaleFactor, viewModel);
    marker.render(context);

    if (mapViewPosition.scale != 1 && mapViewPosition.focalPoint != null) {
      (flutterCanvas).uiCanvas.restore();
    }
    if (viewModel.viewScaleFactor != 1) {
      (flutterCanvas).uiCanvas.restore();
    }
  }

  @override
  bool shouldRepaint(SingleMarkerPainter oldDelegate) {
    if (oldDelegate.mapViewPosition != mapViewPosition) return true;
    return false; //dataStore.needsRepaint;
  }

  @override
  bool shouldRebuildSemantics(SingleMarkerPainter oldDelegate) {
    return false; //super.shouldRebuildSemantics(oldDelegate);
  }

  @override
  bool? hitTest(Offset position) => null;

  @override
  get semanticsBuilder => null;
}
