import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/marker/marker.dart';
import 'package:mapsforge_flutter/src/marker/markercontext.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

///
/// The flutter-derived class to paint all markers in the visible canvas area
///
class MarkerPainter extends CustomPainter {
  static final _log = new Logger('MarkerPainter');

  final MapViewPosition mapViewPosition;

  final IMarkerDataStore dataStore;

  final ViewModel viewModel;

  MarkerPainter({
    required this.mapViewPosition,
    required this.dataStore,
    required this.viewModel,
  }) : super(repaint: dataStore);

  @override
  void paint(Canvas canvas, Size size) {
    int time = DateTime.now().millisecondsSinceEpoch;
    List<Marker> markers = [];
    markers.addAll(dataStore.getMarkersToPaint(
      mapViewPosition.calculateBoundingBox(viewModel.mapDimension),
      mapViewPosition.zoomLevel,
    ));
    int diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 50)
      _log.info(
          "diff: $diff ms for retrieving ${markers.length} markers at zoomlevel ${mapViewPosition.zoomLevel} from $dataStore");

    if (markers.length > 0) {
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
          flutterCanvas, mapViewPosition, viewModel.viewScaleFactor);
      markers.forEach((element) {
        element.render(context);
      });
      if (mapViewPosition.scale != 1 && mapViewPosition.focalPoint != null) {
        (flutterCanvas).uiCanvas.restore();
      }
      if (viewModel.viewScaleFactor != 1) {
        (flutterCanvas).uiCanvas.restore();
      }
    }
    diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 50)
      _log.info(
          "diff: $diff ms for retrieving and rendering ${markers.length} markers at zoomlevel ${mapViewPosition.zoomLevel} from $dataStore");
  }

  @override
  bool shouldRepaint(MarkerPainter oldDelegate) {
    if (oldDelegate.mapViewPosition != mapViewPosition) return true;
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
