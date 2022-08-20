import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/marker/marker.dart';
import 'package:mapsforge_flutter/src/marker/markercontext.dart';
import 'package:logging/logging.dart';

///
/// The flutter-derived class to paint all markers in the visible canvas area
///
class MarkerPainter extends CustomPainter {
  static final _log = new Logger('MarkerPainter');

  final MapViewPosition position;

  final IMarkerDataStore dataStore;

  final ViewModel viewModel;

  MarkerPainter({
    required this.position,
    required this.dataStore,
    required this.viewModel,
  }) : super(repaint: dataStore);

  @override
  void paint(Canvas canvas, Size size) {
    int time = DateTime.now().millisecondsSinceEpoch;
    List<Marker> markers = [];
    markers.addAll(dataStore.getMarkersToPaint(
      position.calculateBoundingBox(viewModel.viewDimension!),
      position.zoomLevel,
    ));
    int diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 50)
      _log.info(
          "diff: $diff ms for retrieving ${markers.length} markers at zoomlevel ${position.zoomLevel} from $dataStore");

    if (markers.length > 0) {
      FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);
      flutterCanvas.setClip(0, 0, viewModel.viewDimension!.width,
          viewModel.viewDimension!.height);
      MarkerContext context = MarkerContext(flutterCanvas, position);
      markers.forEach((element) {
        element.render(context);
      });
    }
    diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 50)
      _log.info(
          "diff: $diff ms for retrieving and rendering ${markers.length} markers at zoomlevel ${position.zoomLevel} from $dataStore");
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
