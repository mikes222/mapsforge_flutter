import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/flutterpaint.dart';

import '../../core.dart';

/// zooms and rotates the canvas when needed before painting the map
class DebugPainter extends CustomPainter {
  final ViewModel viewModel;

  DebugPainter({required this.viewModel});

  /// The [size] is the size of the widget in screenpixels, take care that we
  /// often use mappixels which is off by some zoomFactors
  @override
  void paint(Canvas canvas, Size size) {
    // print(
    //     "debugPainter paint $size with scaleFactor ${viewModel.viewScaleFactor} and center ${viewModel.mapViewPosition?.getCenter()}");

    FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);
    // flutterCanvas.setClip(
    //     -size.width / 2 * viewModel.viewScaleFactor,
    //     -size.height / 2 * viewModel.viewScaleFactor,
    //     size.width * viewModel.viewScaleFactor,
    //     size.height * viewModel.viewScaleFactor);

    // now do the drawing
    // left upper circle
    flutterCanvas.drawCircle(
        -size.width / 2 * viewModel.viewScaleFactor,
        -size.height / 2 * viewModel.viewScaleFactor,
        50,
        FlutterPaint(Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4));
    // bottom-right circle
    flutterCanvas.drawCircle(
        size.width / 2 * viewModel.viewScaleFactor,
        size.height / 2 * viewModel.viewScaleFactor,
        50,
        FlutterPaint(Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4));
    // line from top-left to bottom-right
    canvas.drawLine(
        Offset(-size.width / 2 * viewModel.viewScaleFactor,
            -size.height / 2 * viewModel.viewScaleFactor),
        Offset(size.width / 2 * viewModel.viewScaleFactor,
            size.height / 2 * viewModel.viewScaleFactor),
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2);

    // horizontal lines
    for (int i = -50; i < 50; ++i) {
      canvas.drawLine(
          Offset(-size.width / 2 * viewModel.viewScaleFactor, i * 100),
          Offset(size.width / 2 * viewModel.viewScaleFactor, i * 100),
          Paint()..color = Colors.red);
      canvas.drawLine(
          Offset(-size.width / 2 * viewModel.viewScaleFactor, i * 100 + 50),
          Offset(
              -size.width / 2 * viewModel.viewScaleFactor + 50, i * 100 + 50),
          Paint()..color = Colors.red);
    }
    // vertical lines
    for (int i = -50; i < 50; ++i) {
      canvas.drawLine(
          Offset(i * 100, -size.height / 2 * viewModel.viewScaleFactor),
          Offset(i * 100, size.height / 2 * viewModel.viewScaleFactor),
          Paint()..color = Colors.orange);
      canvas.drawLine(
          Offset(i * 100 + 50, -size.height / 2 * viewModel.viewScaleFactor),
          Offset(
              i * 100 + 50, -size.height / 2 * viewModel.viewScaleFactor + 50),
          Paint()..color = Colors.orange);
    }
    // center circle
    flutterCanvas.drawCircle(
        0,
        0,
        20,
        FlutterPaint(Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4));
  }

  @override
  bool shouldRepaint(covariant DebugPainter oldDelegate) {
    return true;
  }
}
