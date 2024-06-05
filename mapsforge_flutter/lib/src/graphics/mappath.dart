import 'dart:ui';

import 'package:mapsforge_flutter/src/graphics/maprect.dart';

import '../../core.dart';
import '../../special.dart';
import 'fillrule.dart';

abstract class MapPath {
  void clear();

  void close();

  bool isEmpty();

  void lineTo(double x, double y);

  void moveTo(double x, double y);

  void lineToMappoint(Mappoint point);

  void moveToMappoint(Mappoint point);

  void setFillRule(FillRule fillRule);

  void drawDash(MapPaint paint, Canvas uiCanvas);

  void drawLine(MapPaint paint, Canvas uiCanvas);

  void addRect(MapRect mapRect);
}
