import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/marker/markerrenderer.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

///
/// The flutter-derived class to paint all markers in the visible canvas area
///
class MarkerPainter implements CustomPainter {
  static final _log = new Logger('MarkerPainter');

  final MapViewPosition position;

  final DisplayModel displayModel;

  final MarkerRenderer markerRenderer;

  MarkerPainter({required this.position, required this.displayModel, required this.markerRenderer});

  @override
  void paint(Canvas canvas, Size size) {
    markerRenderer.draw(FlutterCanvas(canvas, size), position);
  }

  @override
  bool shouldRepaint(MarkerPainter oldDelegate) {
//    if (oldDelegate?.position != position) return true;
    return markerRenderer.shouldRepaint();
  }

  @override
  bool shouldRebuildSemantics(MarkerPainter oldDelegate) {
    return false; //super.shouldRebuildSemantics(oldDelegate);
  }

  bool? hitTest(Offset position) => null;

  @override
  get semanticsBuilder => null;

  @override
  void addListener(listener) {
    // informs a listener if a repaint is needed because a marker is finally initialized and ready to draw itself
    markerRenderer.addListener(listener);
  }

  @override
  void removeListener(listener) {
    markerRenderer.removeListener(listener);
  }
}
