import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/utils/timing.dart';

///
/// The flutter-derived class to paint all markers in the visible canvas area
///
class MarkerPainter extends CustomPainter {
  static final _log = new Logger('MarkerPainter');

  final IMarkerDataStore dataStore;

  final MarkerContext markerContext;

  const MarkerPainter({
    required this.dataStore,
    required this.markerContext,
  }) : super(repaint: dataStore);

  @override
  void paint(Canvas canvas, Size size) {
    Timing timing = Timing(log: _log);
    List<Marker> markers = dataStore.getMarkersToPaint(
      markerContext.boundingBox,
      markerContext.zoomLevel,
    );
    timing.lap(50, "retrieving ${markers.length} markers at zoomlevel ${markerContext.zoomLevel} from $dataStore for ${markerContext.boundingBox}");

    if (markers.length > 0) {
      // print(
      //     "MarkerPainter paint $size for ${markerContext.boundingBox} and ${markers.length} markers");
      FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);
      // Size(size.width * viewModel.viewScaleFactor,
      //     size.height * viewModel.viewScaleFactor));
      // print(
      //     "canvas size ${viewModel.mapDimension.width} / ${viewModel.mapDimension.height} and scaleFactor ${viewModel.viewScaleFactor}");
      // flutterCanvas.setClip(
      //     0, 0, viewModel.mapDimension.width, viewModel.mapDimension.height);

      markers.forEach((element) {
        element.render(flutterCanvas, markerContext);
      });
    }
    timing.done(50, "retrieving and rendering ${markers.length} markers at zoomlevel ${markerContext.zoomLevel} from $dataStore");
  }

  @override
  bool shouldRepaint(MarkerPainter oldDelegate) {
    if (oldDelegate.markerContext.boundingBox != markerContext.boundingBox) return true;
    if (oldDelegate.markerContext.zoomLevel != markerContext.zoomLevel) return true;
    return false;
  }

  @override
  bool? hitTest(Offset position) => null;
}
