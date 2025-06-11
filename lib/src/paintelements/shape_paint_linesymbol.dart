import 'dart:math';

import 'package:isolate_task_queue/isolate_task_queue.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/model/relative_mappoint.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint.dart';
import 'package:mapsforge_flutter/src/rendertheme/wayproperties.dart';

import '../../maps.dart';
import '../../special.dart';
import '../graphics/matrix.dart';
import '../graphics/resourcebitmap.dart';
import '../model/maprectangle.dart';
import '../rendertheme/shape/shape_linesymbol.dart';

class ShapePaintLinesymbol extends ShapePaint<ShapeLinesymbol> {
  late final MapPaint fill;

  ResourceBitmap? bitmap;

  static TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintLinesymbol._(ShapeLinesymbol shape) : super(shape) {
    fill = createPaint(style: Style.FILL);
  }

  @override
  Future<void> init(SymbolCache symbolCache) async {
    bitmap =
        await createBitmap(symbolCache: symbolCache, bitmapSrc: shape.bitmapSrc!, bitmapWidth: shape.getBitmapWidth(), bitmapHeight: shape.getBitmapHeight());
  }

  static Future<ShapePaintLinesymbol> create(ShapeLinesymbol shape, SymbolCache symbolCache) async {
    return _taskQueue.add(() async {
      if (shape.shapePaint != null) return shape.shapePaint! as ShapePaintLinesymbol;
      ShapePaintLinesymbol shapePaint = ShapePaintLinesymbol._(shape);
      await shapePaint.init(symbolCache);
      shape.shapePaint = shapePaint;
      return shapePaint;
    });
  }

  @override
  void renderNode(MapCanvas canvas, Mappoint coordinatesAbsolute, Mappoint reference, [double rotationRadian = 0]) {}

  @override
  void renderWay(MapCanvas canvas, WayProperties wayProperties, PixelProjection projection, Mappoint reference, [double rotationRadian = 0]) {
    if (bitmap == null) return;

    int skipPixels = shape.repeatStart.round();

    List<List<Mappoint>> coordinatesAbsolute = wayProperties.getCoordinatesAbsolute(projection);

    List<Mappoint?> outerList = coordinatesAbsolute[0];

    // get the first way point coordinates
    double previousX = outerList[0]!.x;
    double previousY = outerList[0]!.y;

    // draw the symbolContainer on each way segment
    int segmentLengthRemaining;
    double segmentSkipPercentage;

    for (int i = 1; i < outerList.length; ++i) {
      double theta = 0;
      // get the current way point coordinates
      double currentX = outerList[i]!.x;
      double currentY = outerList[i]!.y;

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

        RelativeMappoint relative = Mappoint(previousX, previousY).offset(-reference.x, -reference.y + shape.dy);

        MapRectangle boundary = shape.calculateBoundary();

        // if (point.x + boundary.left >= 0 &&
        //     point.y + boundary.bottom >= 0 &&
        //     point.x + boundary.right <= leftUpper.x &&
        //     point.y + boundary.top <= leftUpper.y) {
        Matrix? matrix;
        if (theta != 0) {
          matrix = GraphicFactory().createMatrix();
          matrix.rotate(theta, pivotX: boundary.left, pivotY: boundary.top);
        }

        // print(
        //     "drawing ${bitmap} at ${point.x + boundary.left} / ${point.y + boundary.top} $theta"); //bitmap.debugGetOpenHandleStackTraces();
        //print(StackTrace.current);
        canvas.drawBitmap(bitmap: bitmap!, matrix: matrix, left: relative.x + boundary.left, top: relative.y + boundary.top, paint: fill);

        // check if the symbolContainer should only be rendered once
        if (!shape.repeat) {
          //   bitmap.dispose();
          return;
        }
        //    }

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
