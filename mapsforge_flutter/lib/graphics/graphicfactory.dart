import 'dart:typed_data';

import '../graphics/position.dart';
import '../mapelements/pointtextcontainer.dart';
import '../mapelements/symbolcontainer.dart';
import '../model/boundingbox.dart';
import '../model/mappoint.dart';

import '../inputstream.dart';
import 'bitmap.dart';
import 'canvas.dart';
import 'color.dart';
import 'display.dart';
import 'hillshadingbitmap.dart';
import 'matrix.dart';
import 'paint.dart';
import 'path.dart';
import 'resourcebitmap.dart';
import 'tilebitmap.dart';

abstract class GraphicFactory {
  Bitmap createBitmap(int width, int height, bool isTransparent);

  Canvas createCanvas();

  int createColor(Color color);

  int createColorSeparate(int alpha, int red, int green, int blue);

  Matrix createMatrix();

  /**
   * Create a single channel bitmap for hillshading, may include a buffer.
   */
  HillshadingBitmap createMonoBitmap(
      int width, int height, Uint8List buffer, int padding, BoundingBox area);

  //Paint createPaint();

  Paint createPaint(Paint paint);

  Path createPath();

  PointTextContainer createPointTextContainer(
      Mappoint xy,
      Display display,
      int priority,
      String text,
      Paint paintFront,
      Paint paintBack,
      SymbolContainer symbolContainer,
      Position position,
      int maxTextWidth);

  ResourceBitmap createResourceBitmap(InputStream inputStream,
      double scaleFactor, int width, int height, int percent, int hash);

  TileBitmap createTileBitmap(int tileSize, bool isTransparent,
      {InputStream inputStream});

  InputStream platformSpecificSources(String relativePathPrefix, String src);

  ResourceBitmap renderSvg(InputStream inputStream, double scaleFactor,
      int width, int height, int percent, int hash);
}
