import 'dart:ui' as ui;

import 'package:mapsforge_flutter_core/model.dart';

class UiRect {
  final ui.Rect _rect;

  Mappoint? _center;

  UiRect(double left, double top, double right, double bottom)
    : assert(bottom >= top),
      assert(right >= left),
      _rect = ui.Rect.fromLTRB(left, top, right, bottom);

  double getLeft() => _rect.left;

  double getTop() => _rect.top;

  double getRight() => _rect.right;

  double getBottom() => _rect.bottom;

  UiRect offset(double x, double y) {
    return UiRect(getLeft() + x, getTop() + y, getRight() + x, getBottom() + y);
  }

  Mappoint getCenter() {
    if (_center != null) return _center!;
    _center = Mappoint((_rect.left + _rect.right) / 2, (_rect.top + _rect.bottom) / 2);
    return _center!;
  }

  double getHeight() {
    return _rect.bottom - _rect.top;
  }

  double getWidth() {
    return _rect.right - _rect.left;
  }

  ui.Rect expose() => _rect;
}
