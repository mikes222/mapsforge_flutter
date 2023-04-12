import 'dart:ui' as ui;

import 'package:mapsforge_flutter/src/graphics/fillrule.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';

class FlutterPath implements MapPath {
  final ui.Path path;

  FlutterPath(this.path);

  bool _empty = true;

  @override
  void clear() {
    path.reset();
    _empty = true;
  }

  @override
  void close() {
    path.close();
  }

  @override
  bool isEmpty() {
    return _empty;
  }

  @override
  void lineTo(double x, double y) {
    path.lineTo(x, y);
    _empty = false;
  }

  @override
  void moveTo(double x, double y) {
    path.moveTo(x, y);
    _empty = false;
  }

  @override
  void setFillRule(FillRule fillRule) {
    switch (fillRule) {
      case FillRule.EVEN_ODD:
        path.fillType = ui.PathFillType.evenOdd;
        break;
      case FillRule.NON_ZERO:
        path.fillType = ui.PathFillType.nonZero;
        break;
    }
  }
}
