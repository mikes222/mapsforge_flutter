import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';

import '../../core.dart';
import '../../maps.dart';
import '../layer/job/jobset.dart';
import '../rendertheme/renderinfo.dart';

/// zooms and rotates the canvas when needed before painting the map
class LabelPainter extends CustomPainter {
  final ViewModel viewModel;

  final JobSet jobSet;

  final double rotationRadian;

  LabelPainter(
      {required this.viewModel,
      required this.jobSet,
      required this.rotationRadian})
      : super(repaint: jobSet);

  /// The [size] is the size of the widget in screenpixels, take care that we
  /// often use mappixels which is off by some zoomFactors
  @override
  void paint(Canvas canvas, Size size) {
//    print("labelPainter paint $size for ${jobSet.renderInfos?.length} labels");

    FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);
    // flutterCanvas.setClip(
    //     0, 0, viewModel.mapDimension.width, viewModel.mapDimension.height);

    // now do the drawing
    Mappoint center = jobSet.getCenter();
    PixelProjection projection = PixelProjection(jobSet.zoomLevel);
    jobSet.renderInfos?.forEach((RenderInfo<Shape> renderInfo) {
      //print("LabelPainter renderInfo: $renderInfo");
      renderInfo.render(flutterCanvas, projection, center, rotationRadian);
    });
  }

  @override
  bool shouldRepaint(covariant LabelPainter oldDelegate) {
    // print(
    //     "zoomPainter shouldRepaint ${oldDelegate.mapViewPosition != mapViewPosition}");
    if (oldDelegate.jobSet != jobSet ||
        oldDelegate.rotationRadian != rotationRadian) return true;
    return false;
  }
}
