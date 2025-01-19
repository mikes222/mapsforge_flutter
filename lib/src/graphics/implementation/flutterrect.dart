import 'dart:ui' as ui;

import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

class FlutterRect implements MapRect {
  final ui.Rect rect;

  Mappoint? _center;

  FlutterRect(double left, double top, double right, double bottom)
      : assert(bottom >= top),
        assert(right >= left),
        rect = ui.Rect.fromLTRB(left, top, right, bottom);

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
    return FlutterRect(
        getLeft() + x, getTop() + y, getRight() + x, getBottom() + y);
  }

  @override
  Mappoint getCenter() {
    if (_center != null) return _center!;
    _center =
        Mappoint((rect.left + rect.right) / 2, (rect.top + rect.bottom) / 2);
    return _center!;
  }

  @override
  double getHeight() {
    return rect.bottom - rect.top;
  }

  @override
  double getWidth() {
    return rect.right - rect.left;
  }
}
