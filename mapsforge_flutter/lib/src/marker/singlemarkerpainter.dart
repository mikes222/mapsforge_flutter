import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/marker/markercontext.dart';

///
/// The flutter-derived class to paint one single markers in the visible canvas area
///
class SingleMarkerPainter extends CustomPainter {
  final MapViewPosition position;

  final DisplayModel displayModel;

  final BasicMarker marker;

  final ViewModel viewModel;

  final GraphicFactory graphicFactory;

  SingleMarkerPainter(
      {required this.position,
      required this.displayModel,
      required this.marker,
      required this.viewModel,
      required this.graphicFactory})
      : super();

  @override
  void paint(Canvas canvas, Size size) {
    FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);
    flutterCanvas.setClip(0, 0, viewModel.viewDimension!.width.round(),
        viewModel.viewDimension!.height.round());
    MarkerContext context =
        MarkerContext(flutterCanvas, graphicFactory, position);
    marker.render(context);
  }

  @override
  bool shouldRepaint(SingleMarkerPainter oldDelegate) {
    if (oldDelegate.position != position) return true;
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
