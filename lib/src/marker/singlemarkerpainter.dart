import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';

///
/// The flutter-derived class to paint one single markers in the visible canvas area
///
class SingleMarkerPainter extends CustomPainter {
  final BasicMarker marker;

  final MarkerContext markerContext;

  SingleMarkerPainter({
    required this.marker,
    required this.markerContext,
  }) : super();

  @override
  void paint(Canvas canvas, Size size) {
    FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);

    marker.render(flutterCanvas, markerContext);
  }

  @override
  bool shouldRepaint(SingleMarkerPainter oldDelegate) {
    if (oldDelegate.markerContext.boundingBox != markerContext.boundingBox)
      return true;
    if (oldDelegate.markerContext.zoomLevel != markerContext.zoomLevel)
      return true;
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
