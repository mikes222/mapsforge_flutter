import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/mapcanvas.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint.dart';
import 'package:mapsforge_flutter/src/rendertheme/wayproperties.dart';

import '../../maps.dart';
import '../../special.dart';
import '../graphics/matrix.dart';
import '../graphics/resourcebitmap.dart';
import '../model/maprectangle.dart';
import '../rendertheme/nodeproperties.dart';
import '../rendertheme/shape/shape_linesymbol.dart';

class ShapePaintLinesymbol extends ShapePaint<ShapeLinesymbol> {
  late final MapPaint fill;

  ResourceBitmap? bitmap;

  ShapePaintLinesymbol(ShapeLinesymbol shape) : super(shape) {
    fill = createPaint(style: Style.FILL);
  }

  @override
  Future<void> init(SymbolCache symbolCache) async {
    if (shape.bitmapSrc != null) {
      bitmap = await createBitmap(
          symbolCache: symbolCache,
          bitmapSrc: shape.bitmapSrc!,
          bitmapWidth: shape.getBitmapWidth(),
          bitmapHeight: shape.getBitmapHeight());
    }
  }

  @override
  void renderNode(MapCanvas canvas, NodeProperties nodeProperties,
      PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]) {}

  @override
  void renderWay(MapCanvas canvas, WayProperties wayProperties,
      PixelProjection projection, Mappoint leftUpper,
      [double rotationRadian = 0]) {
    if (bitmap == null) return;

    int skipPixels = shape.repeatStart.round();

    List<List<Mappoint>> coordinates = wayProperties
        .getCoordinatesRelativeToLeftUpper(projection, leftUpper, shape.dy);

    List<Mappoint?> c = coordinates[0];

    // get the first way point coordinates
    double previousX = c[0]!.x;
    double previousY = c[0]!.y;

    // draw the symbolContainer on each way segment
    int segmentLengthRemaining;
    double segmentSkipPercentage;

    for (int i = 1; i < c.length; ++i) {
      double theta = 0;
      // get the current way point coordinates
      double currentX = c[i]!.x;
      double currentY = c[i]!.y;

      // calculate the length of the current segment (Euclidian distance)
      double diffX = currentX - previousX;
      double diffY = currentY - previousY;
      double segmentLengthInPixel = sqrt(diffX * diffX + diffY * diffY);
      segmentLengthRemaining = segmentLengthInPixel.round();

      while (segmentLengthRemaining - skipPixels > shape.repeatStart) {
        // calculate the percentage of the current segment to skip
        segmentSkipPercentage = skipPixels / segmentLengthRemaining;

        // move the previous point forward towards the current point
        previousX += diffX * segmentSkipPercentage;
        previousY += diffY * segmentSkipPercentage;
        if (shape.rotate && theta == 0) {
          // if we do not rotate theta will be 0, which is correct
          theta = atan2(currentY - previousY, currentX - previousX);
        }

        Mappoint point = Mappoint(previousX, previousY);

        MapRectangle boundary = shape.calculateBoundary();

        if (point.x + boundary.left >= 0 &&
            point.y + boundary.bottom >= 0 &&
            point.x + boundary.right <= leftUpper.x &&
            point.y + boundary.top <= leftUpper.y) {
          Matrix? matrix;
          if (theta != 0) {
            matrix = GraphicFactory().createMatrix();
            matrix.rotate(theta, pivotX: boundary.left, pivotY: boundary.top);
          }

          // print(
          //     "drawing ${bitmap} at ${point.x + boundary.left} / ${point.y + boundary.top} $theta"); //bitmap.debugGetOpenHandleStackTraces();
          //print(StackTrace.current);
          canvas.drawBitmap(
              bitmap: bitmap!,
              matrix: matrix,
              left: point.x + boundary.left,
              top: point.y + boundary.top,
              paint: fill);

          // check if the symbolContainer should only be rendered once
          if (!shape.repeat) {
            //   bitmap.dispose();
            return;
          }
        }

        // recalculate the distances
        diffX = currentX - previousX;
        diffY = currentY - previousY;

        // recalculate the remaining length of the current segment
        segmentLengthRemaining -= skipPixels;

        // set the amount of pixels to skip before repeating the symbolContainer
        skipPixels = shape.repeatGap.round();
      }

      skipPixels -= segmentLengthRemaining;
      if (skipPixels < shape.repeatStart) {
        skipPixels = shape.repeatStart.round();
      }

      // set the previous way point coordinates for the next loop
      previousX = currentX;
      previousY = currentY;
    }
    //bitmap.dispose();
  }
}
