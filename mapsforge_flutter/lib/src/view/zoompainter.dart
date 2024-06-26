import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/layer/tilelayer.dart';

import '../../core.dart';
import '../layer/job/jobset.dart';

/// zooms and rotates the canvas when needed before painting the map
class ZoomPainter extends CustomPainter {
  final TileLayer tileLayer;

  final ViewModel viewModel;

  final JobSet jobSet;

  const ZoomPainter(
      {required this.tileLayer, required this.viewModel, required this.jobSet})
      : super(repaint: jobSet);

  /// The [size] is the size of the widget in screenpixels, take care that we
  /// often use mappixels which is off by some zoomFactors
  @override
  void paint(Canvas canvas, Size size) {
    // print("zoomPainter paint $size");
    MapViewPosition mapViewPosition = jobSet.mapViewPosition;

    FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);
    flutterCanvas.setClip(
        0, 0, viewModel.mapDimension.width, viewModel.mapDimension.height);
    mapViewPosition.calculateBoundingBox(viewModel.mapDimension);

    if (viewModel.viewScaleFactor != 1) {
      canvas.save();
      flutterCanvas.scale(
          const Mappoint(/*viewModel.viewDimension.width / 2*/ 0,
              /*viewModel.viewDimension.height / 2*/ 0),
          1 / viewModel.viewScaleFactor);
    }
    if (mapViewPosition.scale != 1 && mapViewPosition.focalPoint != null) {
      //_log.info("scaling to ${mapViewPosition.scale} around ${mapViewPosition.focalPoint}");
      canvas.save();
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
    // now do the drawing
    tileLayer.draw(viewModel, flutterCanvas, jobSet);

    if (mapViewPosition.scale != 1 && mapViewPosition.focalPoint != null) {
      //(canvas as FlutterCanvas).uiCanvas.drawCircle(Offset.zero, 20, Paint());
      canvas.restore();
      //(canvas as FlutterCanvas).uiCanvas.drawCircle(Offset.zero, 15, Paint()..color = Colors.amber);
    }
    if (viewModel.viewScaleFactor != 1) {
      canvas.restore();
    }

    if (mapViewPosition.rotationRadian != 0) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ZoomPainter oldDelegate) {
    // print(
    //     "zoomPainter shouldRepaint ${oldDelegate.mapViewPosition != mapViewPosition}");
    //if (oldDelegate.mapViewPosition != mapViewPosition) return true;
    return true;
  }
}
