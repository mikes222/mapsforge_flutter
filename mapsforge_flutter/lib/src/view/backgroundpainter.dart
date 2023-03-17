import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';

class BackgroundPainter extends CustomPainter {
  final DisplayModel displayModel;

  BackgroundPainter({required this.displayModel});

  @override
  void paint(Canvas canvas, Size size) {
    FlutterCanvas flutterCanvas = FlutterCanvas(canvas, size);
    flutterCanvas.fillColorFromNumber(this.displayModel.getBackgroundColor());
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) {
//    if (oldDelegate?.position != position) return true;
    return false;
  }

  @override
  bool shouldRebuildSemantics(BackgroundPainter oldDelegate) {
    return false; //super.shouldRebuildSemantics(oldDelegate);
  }

  @override
  bool? hitTest(Offset position) => null;

  @override
  get semanticsBuilder => null;
}
