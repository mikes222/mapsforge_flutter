import 'dart:typed_data';

import 'package:mapsforge_flutter/graphics/canvas.dart';
import 'package:mapsforge_flutter/graphics/color.dart';
import 'package:mapsforge_flutter/graphics/display.dart';
import 'package:mapsforge_flutter/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/graphics/hillshadingbitmap.dart';
import 'package:mapsforge_flutter/graphics/matrix.dart';
import 'package:mapsforge_flutter/graphics/paint.dart';
import 'package:mapsforge_flutter/graphics/path.dart';
import 'package:mapsforge_flutter/graphics/position.dart';
import 'package:mapsforge_flutter/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/inputstream.dart';
import 'package:mapsforge_flutter/mapelements/pointtextcontainer.dart';
import 'package:mapsforge_flutter/mapelements/symbolcontainer.dart';
import 'package:mapsforge_flutter/model/boundingbox.dart';
import 'package:mapsforge_flutter/model/mappoint.dart';
import '../../graphics/bitmap.dart';

class FlutterGraphicFactory implements GraphicFactory {
  @override
  Bitmap createBitmap(int width, int height, bool isTransparent) {
    // TODO: implement createBitmap
    return null;
  }

  @override
  Canvas createCanvas() {
    // TODO: implement createCanvas
    return null;
  }

  @override
  int createColor(Color color) {
    // TODO: implement createColor
    return null;
  }

  @override
  int createColorSeparate(int alpha, int red, int green, int blue) {
    // TODO: implement createColorSeparate
    return null;
  }

  @override
  Matrix createMatrix() {
    // TODO: implement createMatrix
    return null;
  }

  @override
  HillshadingBitmap createMonoBitmap(
      int width, int height, Uint8List buffer, int padding, BoundingBox area) {
    // TODO: implement createMonoBitmap
    return null;
  }

  @override
  Paint createPaint(Paint paint) {
    // TODO: implement createPaint
    return null;
  }

  @override
  Path createPath() {
    // TODO: implement createPath
    return null;
  }

  @override
  PointTextContainer createPointTextContainer(
      Mappoint xy,
      Display display,
      int priority,
      String text,
      Paint paintFront,
      Paint paintBack,
      SymbolContainer symbolContainer,
      Position position,
      int maxTextWidth) {
    // TODO: implement createPointTextContainer
    return null;
  }

  @override
  ResourceBitmap createResourceBitmap(InputStream inputStream,
      double scaleFactor, int width, int height, int percent) {
    // TODO: implement createResourceBitmap
    return null;
  }

  @override
  TileBitmap createTileBitmap(int tileSize, bool isTransparent,
      {InputStream inputStream}) {
    // TODO: implement createTileBitmap
    return null;
  }

  @override
  InputStream platformSpecificSources(String relativePathPrefix, String src) {
    // TODO: implement platformSpecificSources
    return null;
  }

  @override
  ResourceBitmap renderSvg(InputStream inputStream, double scaleFactor,
      int width, int height, int percent) {
    // TODO: implement renderSvg
    return null;
  }
}
