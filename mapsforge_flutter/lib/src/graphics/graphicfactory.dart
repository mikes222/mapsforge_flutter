import 'package:flutter/widgets.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttergraphicfactory.dart';

import '../graphics/position.dart';
import '../model/mappoint.dart';
import 'display.dart';
import 'mapcanvas.dart';
import 'mappaint.dart';
import 'mappath.dart';
import 'maprect.dart';
import 'matrix.dart';

abstract class GraphicFactory {
  static GraphicFactory? _instance;

  factory GraphicFactory() {
    if (_instance != null) return _instance!;
    _instance = const FlutterGraphicFactory();
    return _instance!;
  }

  const GraphicFactory._();

  //Bitmap createBitmap(int width, int height, bool isTransparent);

  MapCanvas createCanvas(double width, double height, [String? src]);

  int createColorSeparate(int alpha, int red, int green, int blue);

  Matrix createMatrix();

  /**
   * Create a single channel bitmap for hillshading, may include a buffer.
   */
//  HillshadingBitmap createMonoBitmap(int width, int height, Uint8List buffer, int padding, BoundingBox area);

  //Paint createPaint();

  MapPaint createPaint();

  MapTextPaint createTextPaint();

  MapPaint createPaintFrom(MapPaint from);

  MapPath createPath();

  MapRect createRect(double left, double top, double right, double bottom);
}
