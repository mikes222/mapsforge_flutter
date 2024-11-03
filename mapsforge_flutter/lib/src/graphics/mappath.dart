import 'dart:ui';

import 'package:mapsforge_flutter/src/graphics/maprect.dart';

import '../../core.dart';
import '../../special.dart';
import '../model/relative_mappoint.dart';
import 'fillrule.dart';

abstract class MapPath {
  void clear();

  void close();

  bool isEmpty();

  void lineTo(double x, double y);

  void moveTo(double x, double y);

  void lineToMappoint(RelativeMappoint point);

  void moveToMappoint(RelativeMappoint point);

  void setFillRule(FillRule fillRule);

  void drawPath(MapPaint paint, Canvas uiCanvas);

  void addRect(MapRect mapRect);
}
