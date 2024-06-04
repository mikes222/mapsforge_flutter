import 'dart:ui' as ui;
import 'dart:ui';

import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

import '../fillrule.dart';

class FlutterPath implements MapPath {
  final ui.Path path;

  @override
  final List<Offset> points = [];

  FlutterPath(this.path);

  @override
  void clear() {
    path.reset();
    points.clear();
  }

  @override
  void close() {
    path.close();
  }

  @override
  bool isEmpty() {
    return points.isEmpty;
  }

  @override
  void lineTo(double x, double y) {
    path.lineTo(x, y);
    points.add(Offset(x, y));
  }

  @override
  void moveTo(double x, double y) {
    path.moveTo(x, y);
    points.add(Offset(x, y));
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

  @override
  void lineToMappoint(Mappoint point) {
    path.lineTo(point.x, point.y);
    points.add(Offset(point.x, point.y));
  }

  @override
  void moveToMappoint(Mappoint point) {
    path.moveTo(point.x, point.y);
    points.add(Offset(point.x, point.y));
  }
}
