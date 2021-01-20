import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/model/displaymodel.dart';
import 'package:mapsforge_flutter/src/model/mapviewposition.dart';

class BackgroundPainter extends ChangeNotifier implements CustomPainter {
  final MapViewPosition position;

  final DisplayModel displayModel;

  BackgroundPainter({@required this.position, @required this.displayModel})
      : assert(position != null),
        assert(displayModel != null);

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

  bool hitTest(Offset position) => null;

  @override
  get semanticsBuilder => null;
}
