import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/marker/markerrenderer.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/model/mapviewdimension.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

class MarkerPainter implements CustomPainter {
  final MapViewDimension mapViewDimension;

  final MapViewPosition position;

  final DisplayModel displayModel;

  final MarkerRenderer markerRenderer;

  MarkerPainter({@required this.mapViewDimension, @required this.position, @required this.displayModel, @required this.markerRenderer})
      : assert(mapViewDimension != null),
        assert(position != null),
        assert(displayModel != null),
        assert(markerRenderer != null);

  @override
  void paint(Canvas canvas, Size size) {
    //mapModel.mapViewDimension.setDimension(size.width, size.height);

    bool changed = mapViewDimension.setDimension(size.width, size.height);
    if (changed) {
      position.sizeChanged();
    }

    markerRenderer.draw(FlutterCanvas(canvas, size), mapViewDimension, position);
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

  bool hitTest(Offset position) => null;

  @override
  get semanticsBuilder => null;

  @override
  void addListener(listener) {}

  @override
  void removeListener(listener) {}
}
