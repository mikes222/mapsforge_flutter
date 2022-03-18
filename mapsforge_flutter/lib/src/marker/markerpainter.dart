import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/marker/markercontext.dart';

///
/// The flutter-derived class to paint all markers in the visible canvas area
///
class MarkerPainter extends CustomPainter {
  static final _log = new Logger('MarkerPainter');

  final MapViewPosition position;

  final DisplayModel displayModel;

  final IMarkerDataStore dataStore;

  final ViewModel viewModel;

  final SymbolCache? symbolCache;

  MarkerPainter(
      {required this.position,
      required this.displayModel,
      required this.dataStore,
      required this.viewModel,
      this.symbolCache})
      : super(repaint: dataStore);

  @override
  void paint(Canvas canvas, Size size) {
    List<BasicMarker> markers = dataStore.getMarkers(
        symbolCache,
        position.calculateBoundingBox(viewModel.viewDimension!),
        position.zoomLevel);
    // _log.info("Drawing ${markers?.length ?? -1} markers");

    if (markers.length > 0) {
      FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);
      flutterCanvas.setClip(0, 0, viewModel.viewDimension!.width,
          viewModel.viewDimension!.height);
      MarkerContext context = MarkerContext(flutterCanvas, position);
      markers.forEach((element) {
        element.render(context, position.zoomLevel);
      });
    }
  }

  @override
  bool shouldRepaint(MarkerPainter oldDelegate) {
    if (oldDelegate.position != position) return true;
    return false; //dataStore.needsRepaint;
  }

  @override
  bool shouldRebuildSemantics(MarkerPainter oldDelegate) {
    return false; //super.shouldRebuildSemantics(oldDelegate);
  }

  @override
  bool? hitTest(Offset position) => null;

  @override
  get semanticsBuilder => null;
}
