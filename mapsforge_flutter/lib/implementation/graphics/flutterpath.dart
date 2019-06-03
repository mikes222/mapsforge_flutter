import 'dart:ui' as ui;

import 'package:mapsforge_flutter/graphics/fillrule.dart';
import 'package:mapsforge_flutter/graphics/mappath.dart';

class FlutterPath implements MapPath {
  final ui.Path path;

  FlutterPath(this.path);

  @override
  void clear() {
    path.reset();
  }

  @override
  void close() {
    path.close();
  }

  @override
  bool isEmpty() {
    // TODO: implement isEmpty
    return null;
  }

  @override
  void lineTo(double x, double y) {
    path.lineTo(x, y);
  }

  @override
  void moveTo(double x, double y) {
    path.moveTo(x, y);
  }

  @override
  void setFillRule(FillRule fillRule) {
    // TODO: implement setFillRule
  }
}
