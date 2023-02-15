import 'dart:ui' as ui;

import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/mappath.dart';
import 'package:mapsforge_flutter/src/graphics/maprect.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/matrix.dart';
import 'package:mapsforge_flutter/src/graphics/position.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttertextpaint.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

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

  // @override
  // HillshadingBitmap createMonoBitmap(int width, int height, Uint8List buffer, int padding, BoundingBox area) {
  //   // TODO: implement createMonoBitmap
  //   return null;
  // }

  // @override
  // ResourceBitmap createResourceBitmap(InputStream inputStream, double scaleFactor, int width, int height, int percent) {
  //   // TODO: implement createResourceBitmap
  //   return null;
  // }

  // @override
  // TileBitmap createTileBitmap(double tileSize, bool isTransparent, {InputStream inputStream}) {
  //   throw Exception("Cannot create a tileBitmap without bitmap");
  //   return FlutterTileBitmap(null);
  // }
  //
  // @override
  // InputStream platformSpecificSources(String relativePathPrefix, String src) {
  //   // TODO: implement platformSpecificSources
  //   return null;
  // }
  //
  // @override
  // ResourceBitmap renderSvg(InputStream inputStream, double scaleFactor, int width, int height, int percent) {
  //   // TODO: implement renderSvg
  //   return null;
  // }

  @override
  MapPaint createPaint() {
    return FlutterPaint(ui.Paint());
  }

  MapTextPaint createTextPaint() {
    return FlutterTextPaint();
  }

  @override
  MapPaint createPaintFrom(MapPaint from) {
    return FlutterPaint.from(from as FlutterPaint);
  }

  @override
  MapPath createPath() {
    return FlutterPath(ui.Path());
  }

  @override
  MapRect createRect(double left, double top, double right, double bottom) {
    return FlutterRect(left, top, right, bottom);
  }
}
