import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';

import '../../core.dart';
import '../../maps.dart';
import '../layer/job/jobresult.dart';
import '../layer/job/jobset.dart';

/// zooms and rotates the canvas when needed before painting the map
class TilePainter extends CustomPainter {
  final ViewModel viewModel;

  final JobSet jobSet;

  TilePainter({required this.viewModel, required this.jobSet})
      : super(repaint: jobSet);

  /// The [size] is the size of the widget in screenpixels, take care that we
  /// often use mappixels which is off by some zoomFactors
  @override
  void paint(Canvas canvas, Size size) {
    // print(
    //     "tilePainter paint $size for ${jobSet.bitmaps.length} bitmaps with scaleFactor ${viewModel.viewScaleFactor}");

    FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);
    // flutterCanvas.setClip(
    //     -size.width / 2 * viewModel.viewScaleFactor,
    //     -size.height / 2 * viewModel.viewScaleFactor,
    //     size.width * viewModel.viewScaleFactor,
    //     size.height * viewModel.viewScaleFactor);

    // now do the drawing
    Mappoint center = jobSet.getCenter();
    PixelProjection projection = PixelProjection(jobSet.zoomLevel);
    //flutterCanvas.drawCircle(0, 0, 100, FlutterPaint(Paint()));
    jobSet.bitmaps.forEach((Tile tile, JobResult jobResult) {
      if (jobResult.picture != null) {
        Mappoint point = projection.getLeftUpper(tile);
        //print("drawing ${point.x - leftUpper.x} / ${point.y - leftUpper.y}");
        flutterCanvas.drawTilePicture(
            picture: jobResult.picture!,
            left: point.x - center.x,
            top: point.y - center.y);
      }
    });
  }

  @override
  bool shouldRepaint(covariant TilePainter oldDelegate) {
    // print(
    //     "zoomPainter shouldRepaint ${oldDelegate.mapViewPosition != mapViewPosition}");
    if (oldDelegate.jobSet != jobSet) return true;
    return false;
  }
}
