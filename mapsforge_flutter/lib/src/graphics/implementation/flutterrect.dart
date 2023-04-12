import 'dart:ui' as ui;

import 'package:mapsforge_flutter/src/graphics/maprect.dart';

class FlutterRect implements MapRect {
  final ui.Rect rect;

  FlutterRect(double left, double top, double right, double bottom)
      : rect = ui.Rect.fromLTRB(left, top, right, bottom);

  @override
  double getLeft() => rect.left;

  @override
  double getTop() => rect.top;

  @override
  double getRight() => rect.right;

  @override
  double getBottom() => rect.bottom;

  @override
  MapRect offset(double x, double y) {
    return FlutterRect(getLeft() + x, getTop() + y, getRight() + x, getBottom() + y);
  }

}
