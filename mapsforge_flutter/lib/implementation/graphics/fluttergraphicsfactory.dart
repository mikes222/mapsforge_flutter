import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:mapsforge_flutter/graphics/color.dart';
import 'package:mapsforge_flutter/graphics/display.dart';
import 'package:mapsforge_flutter/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/graphics/hillshadingbitmap.dart';
import 'package:mapsforge_flutter/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/graphics/matrix.dart';
import 'package:mapsforge_flutter/graphics/mappaint.dart';
import 'package:mapsforge_flutter/graphics/mappath.dart';
import 'package:mapsforge_flutter/graphics/position.dart';
import 'package:mapsforge_flutter/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/inputstream.dart';
import 'package:mapsforge_flutter/mapelements/pointtextcontainer.dart';
import 'package:mapsforge_flutter/mapelements/symbolcontainer.dart';
import 'package:mapsforge_flutter/model/boundingbox.dart';
import 'package:mapsforge_flutter/model/mappoint.dart';

import '../../graphics/bitmap.dart';
import 'fluttercanvas.dart';
import 'fluttercolor.dart';
import 'flutterpaint.dart';
import 'flutterpath.dart';
import 'fluttertilebitmap.dart';

class FlutterGraphicFactory implements GraphicFactory {
  @override
  Bitmap createBitmap(int width, int height, bool isTransparent) {
    // TODO: implement createBitmap
    return null;
  }

  @override
  MapCanvas createCanvas(double width, double height) {
    return FlutterCanvas.forRecorder(width, height);
  }

  @override
  int createColor(Color color) {
    return FlutterColor.getColor(color);
  }

  @override
  int createColorSeparate(int alpha, int red, int green, int blue) {
    return alpha << 24 | red << 16 | green << 8 | blue;
  }

  @override
  Matrix createMatrix() {
    // TODO: implement createMatrix
    return null;
  }

  @override
  HillshadingBitmap createMonoBitmap(int width, int height, Uint8List buffer, int padding, BoundingBox area) {
    // TODO: implement createMonoBitmap
    return null;
  }

  @override
  PointTextContainer createPointTextContainer(Mappoint xy, Display display, int priority, String text, MapPaint paintFront,
      MapPaint paintBack, SymbolContainer symbolContainer, Position position, int maxTextWidth) {
    // TODO: implement createPointTextContainer
    return null;
  }

  @override
  ResourceBitmap createResourceBitmap(InputStream inputStream, double scaleFactor, int width, int height, int percent) {
    // TODO: implement createResourceBitmap
    return null;
  }

  @override
  TileBitmap createTileBitmap(int tileSize, bool isTransparent, {InputStream inputStream}) {
    throw Exception("Cannot create a tileBitmap without bitmap");
    return FlutterTileBitmap(null);
  }

  @override
  InputStream platformSpecificSources(String relativePathPrefix, String src) {
    // TODO: implement platformSpecificSources
    return null;
  }

  @override
  ResourceBitmap renderSvg(InputStream inputStream, double scaleFactor, int width, int height, int percent) {
    // TODO: implement renderSvg
    return null;
  }

  @override
  MapPaint createPaint() {
    return FlutterPaint(ui.Paint());
  }

  @override
  MapPath createPath() {
    return FlutterPath(ui.Path());
  }
}
