import 'dart:ui';

import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/matrix.dart';
import 'package:mapsforge_flutter/src/graphics/tilepicture.dart';
import 'package:mapsforge_flutter/src/model/linestring.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

import 'bitmap.dart';
import 'mappaint.dart';
import 'mappath.dart';
import 'maprect.dart';

///
/// The abstract representation of a canvas. In flutter the canvas is shown in the widget
abstract class MapCanvas {
  const MapCanvas();

  void destroy();

  Future<TilePicture> finalizeBitmap();

  void drawBitmap({
    required Bitmap bitmap,
    required double left,
    required double top,
    required MapPaint paint,
    Matrix? matrix,
  });

  void drawTilePicture({
    required TilePicture picture,
    required double left,
    required double top,
  });

  /// Draws a circle whereas the center of the circle is denoted by [x] and [y]
  void drawCircle(double x, double y, double radius, MapPaint paint);

  void drawLine(double x1, double y1, double x2, double y2, MapPaint paint);

  void drawPath(MapPath path, MapPaint paint);

  void drawRect(MapRect rect, MapPaint paint);

  void drawPathText(String text, LineString lineString, Mappoint reference, MapPaint paint, MapTextPaint mapTextPaint, double maxTextWidth);

  void drawText(String text, double x, double y, MapPaint paint, MapTextPaint mapTextPaint, double maxTextWidth);

  void fillColorFromNumber(int color);

  void setClip(double left, double top, double width, double height);

  void scale(Offset focalPoint, double scale);

  void translate(double dx, double dy);
}
