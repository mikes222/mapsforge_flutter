import 'dart:math';

import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/cache/symbol_cache_mgr.dart';
import 'package:datastore_renderer/src/ui/symbol_image.dart';
import 'package:datastore_renderer/src/ui/ui_canvas.dart';
import 'package:datastore_renderer/src/ui/ui_matrix.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_shape_painter.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintLinesymbol extends UiShapePainter<RenderinstructionLinesymbol> {
  late final UiPaint fill;

  SymbolImage? symbolImage;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintLinesymbol._(RenderinstructionLinesymbol renderinstruction) : super(renderinstruction) {
    fill = UiPaint.fill();
  }

  Future<void> init() async {
    symbolImage = await SymbolCacheMgr().getOrCreateSymbol(
      renderinstruction.bitmapSrc!,
      renderinstruction.getBitmapWidth(),
      renderinstruction.getBitmapHeight(),
    );
  }

  void dispose() {
    symbolImage?.dispose();
  }

  static Future<ShapePaintLinesymbol> create(RenderinstructionLinesymbol renderinstruction) async {
    return _taskQueue.add(() async {
      if (renderinstruction.shapePainter != null) return renderinstruction.shapePainter! as ShapePaintLinesymbol;
      ShapePaintLinesymbol shapePaint = ShapePaintLinesymbol._(renderinstruction);
      await shapePaint.init();
      renderinstruction.shapePainter = shapePaint;
      return shapePaint;
    });
  }

  @override
  void renderNode(RenderContext renderContext, NodeProperties nodeProperties) {}

  @override
  void renderWay(RenderContext renderContext, WayProperties wayProperties) {
    int skipPixels = renderinstruction.repeatStart.round();

    List<List<Mappoint>> coordinatesAbsolute = wayProperties.getCoordinatesAbsolute();

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

      while (segmentLengthRemaining - skipPixels > renderinstruction.repeatStart) {
        // calculate the percentage of the current segment to skip
        segmentSkipPercentage = skipPixels / segmentLengthRemaining;

        // move the previous point forward towards the current point
        previousX += diffX * segmentSkipPercentage;
        previousY += diffY * segmentSkipPercentage;
        if (renderinstruction.rotate && theta == 0) {
          // if we do not rotate theta will be 0, which is correct
          theta = atan2(currentY - previousY, currentX - previousX);
        }

        RelativeMappoint relative = Mappoint(previousX, previousY).offset(renderContext.reference).offset(0, renderinstruction.dy);

        MapRectangle boundary = symbolImage!.getBoundary();

        UiMatrix? matrix;
        if (theta != 0) {
          matrix = UiMatrix();
          matrix.rotate(theta, pivotX: boundary.left, pivotY: boundary.top);
        }

        // print(
        //     "drawing ${bitmap} at ${point.x + boundary.left} / ${point.y + boundary.top} $theta"); //bitmap.debugGetOpenHandleStackTraces();
        //print(StackTrace.current);
        renderContext.canvas.drawPicture(
          symbolImage: symbolImage!,
          matrix: matrix,
          left: relative.x + boundary.left,
          top: relative.y + boundary.top,
          paint: fill,
        );

        // check if the symbolContainer should only be rendered once
        if (!renderinstruction.repeat) {
          return;
        }

        // recalculate the distances
        diffX = currentX - previousX;
        diffY = currentY - previousY;

        // recalculate the remaining length of the current segment
        segmentLengthRemaining -= skipPixels;

        // set the amount of pixels to skip before repeating the symbolContainer
        skipPixels = renderinstruction.repeatGap.round();
      }

      skipPixels -= segmentLengthRemaining;
      if (skipPixels < renderinstruction.repeatStart) {
        skipPixels = renderinstruction.repeatStart.round();
      }

      // set the previous way point coordinates for the next loop
      previousX = currentX;
      previousY = currentY;
    }
    //bitmap.dispose();
  }
}
