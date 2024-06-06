import 'dart:ui' as ui;

import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttertextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/matrix.dart';

import 'fluttercanvas.dart';
import 'fluttermatrix.dart';
import 'flutterpaint.dart';
import 'flutterpath.dart';
import 'flutterrect.dart';

class FlutterGraphicFactory implements GraphicFactory {
  const FlutterGraphicFactory();

  // @override
  // Bitmap createBitmap(int width, int height, bool isTransparent) {
  //   // TODO: implement createBitmap
  //   return null;
  // }

  @override
  MapCanvas createCanvas(double width, double height, [String? src]) {
    return FlutterCanvas.forRecorder(width, height, src);
  }

  @override
  int createColorSeparate(int alpha, int red, int green, int blue) {
    return alpha << 24 | red << 16 | green << 8 | blue;
  }

  @override
  Matrix createMatrix() {
    return FlutterMatrix();
  }

  @override
  MapPaint createPaint() {
    return FlutterPaint(ui.Paint());
  }

  @override
  MapTextPaint createTextPaint() {
    return FlutterTextPaint();
  }

  @override
  MapPaint createPaintFrom(MapPaint from) {
    return FlutterPaint.from(from as FlutterPaint);
  }

  @override
  MapPath createPath() {
    return FlutterPath();
  }

  @override
  MapRect createRect(double left, double top, double right, double bottom) {
    return FlutterRect(left, top, right, bottom);
  }
}
