import 'dart:ui' as ui;

import 'package:mapsforge_flutter/src/graphics/fillrule.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';

class FlutterRect implements MapRect {
  final ui.Rect rect;

  FlutterRect(double left, double top, double right, double bottom) : rect = ui.Rect.fromLTRB(left, top, right, bottom);
}
