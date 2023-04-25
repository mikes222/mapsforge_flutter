import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/marker/markercontext.dart';
import 'package:mapsforge_flutter/src/utils/timing.dart';

///
/// The flutter-derived class to paint all markers in the visible canvas area
///
class MarkerPainter extends CustomPainter {
  static final _log = new Logger('MarkerPainter');

  final MapViewPosition mapViewPosition;

  final IMarkerDataStore dataStore;

  final ViewModel viewModel;

  const MarkerPainter({
    required this.mapViewPosition,
    required this.dataStore,
    required this.viewModel,
  }) : super(repaint: dataStore);

  @override
  void paint(Canvas canvas, Size size) {
    Timing timing = Timing(log: _log);
    List<Marker> markers = [];
    markers.addAll(dataStore.getMarkersToPaint(
      mapViewPosition.calculateBoundingBox(viewModel.mapDimension),
      mapViewPosition.zoomLevel,
    ));
    timing.lap(50,
        "retrieving ${markers.length} markers at zoomlevel ${mapViewPosition.zoomLevel} from $dataStore");

    if (markers.length > 0) {
      FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);
      // print(
      //     "canvas size ${viewModel.mapDimension.width} / ${viewModel.mapDimension.height} and scaleFactor ${viewModel.viewScaleFactor}");
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
      if (mapViewPosition.rotationRadian != 0) {
        canvas.save();
        canvas.translate(size.width * viewModel.viewScaleFactor / 2,
            size.height * viewModel.viewScaleFactor / 2);
        canvas.rotate(mapViewPosition.rotationRadian);
        canvas.translate(-size.width * viewModel.viewScaleFactor / 2,
            -size.height * viewModel.viewScaleFactor / 2);
      }

      MarkerContext context = MarkerContext(
          flutterCanvas, mapViewPosition, viewModel.viewScaleFactor, viewModel);
      markers.forEach((element) {
        element.render(context);
      });

      if (mapViewPosition.scale != 1 && mapViewPosition.focalPoint != null) {
        (flutterCanvas).uiCanvas.restore();
      }
      if (viewModel.viewScaleFactor != 1) {
        (flutterCanvas).uiCanvas.restore();
      }
      if (mapViewPosition.rotationRadian != 0) {
        canvas.restore();
      }
    }
    timing.lap(50,
        "retrieving and rendering ${markers.length} markers at zoomlevel ${mapViewPosition.zoomLevel} from $dataStore");
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
