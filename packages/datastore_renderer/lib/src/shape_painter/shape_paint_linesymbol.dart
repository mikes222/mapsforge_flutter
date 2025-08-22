import 'dart:math';

import 'package:dart_common/model.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/cache/symbol_cache_mgr.dart';
import 'package:datastore_renderer/src/model/ui_render_context.dart';
import 'package:datastore_renderer/src/ui/symbol_image.dart';
import 'package:datastore_renderer/src/ui/ui_matrix.dart';
import 'package:datastore_renderer/src/ui/ui_paint.dart';
import 'package:datastore_renderer/src/ui/ui_shape_painter.dart';
import 'package:logging/logging.dart';
import 'package:task_queue/task_queue.dart';

class ShapePaintLinesymbol extends UiShapePainter<RenderinstructionLinesymbol> {
  static final _log = Logger('ShapePaintLinesymbol');

  late final UiPaint fill;

  SymbolImage? symbolImage;

  static final TaskQueue _taskQueue = SimpleTaskQueue();

  ShapePaintLinesymbol._(RenderinstructionLinesymbol renderinstruction) : super(renderinstruction) {
    fill = UiPaint.fill(color: 0xff000000);
  }

  Future<void> init() async {
    try {
      symbolImage = await SymbolCacheMgr().getOrCreateSymbol(
        renderinstruction.bitmapSrc!,
        renderinstruction.getBitmapWidth(),
        renderinstruction.getBitmapHeight(),
      );
    } catch (error) {
      _log.warning("Error loading bitmap ${renderinstruction.bitmapSrc}", error);
    }
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
    if (symbolImage == null) return;
    if (renderContext is! UiRenderContext) throw Exception("renderContext is not UiRenderContext ${renderContext.runtimeType}");
    int skipPixels = renderinstruction.repeatStart.round();

    List<List<Mappoint>> coordinatesAbsolute = wayProperties.getCoordinatesAbsolute();

    List<Mappoint?> outerList = coordinatesAbsolute[0];
    if (outerList.length < 2) return;

    // get the first way point coordinates
    Mappoint previous = outerList[0]!;

    // draw the symbolContainer on each way segment
    int segmentLengthRemaining;
    double segmentSkipPercentage;

    MapRectangle boundary = symbolImage!.getBoundary();

    double radians = 0;
    if (renderinstruction.rotate) {
      // if we do not rotate theta will be 0, which is correct
      radians = previous.radiansTo(outerList.last!);
    }

    for (int i = 1; i < outerList.length; ++i) {
      // get the current way point coordinates
      Mappoint current = outerList[i]!;

      // calculate the length of the current segment (Euclidian distance)
      RelativeMappoint diff = current.offset(previous);
      double segmentLengthInPixel = sqrt(diff.x * diff.x + diff.y * diff.y);
      segmentLengthRemaining = segmentLengthInPixel.round();

      while (segmentLengthRemaining - skipPixels > renderinstruction.repeatStart) {
        // calculate the percentage of the current segment to skip
        segmentSkipPercentage = skipPixels / segmentLengthRemaining;

        // move the previous point forward towards the current point
        previous = Mappoint(previous.x + diff.x * segmentSkipPercentage, previous.y + diff.y * segmentSkipPercentage);

        RelativeMappoint relative = previous.offset(renderContext.reference).offset(0, renderinstruction.dy);

        UiMatrix? matrix;
        if (radians != 0) {
          matrix = UiMatrix();
          matrix.rotate(radians, pivotX: relative.x, pivotY: relative.y);
        }

        renderContext.canvas.drawPicture(
          symbolImage: symbolImage!,
          matrix: matrix,
          left: relative.x + boundary.left,
          top: relative.y + boundary.top,
          paint: fill,
        );

        // renderContext.canvas.drawCircle(relative.x, relative.y, boundary.getWidth() / 2, UiPaint.stroke(color: 0x80ff0000));
        // renderContext.canvas.drawCircle(relative.x + boundary.left, relative.y + boundary.top, 5, UiPaint.fill(color: 0xffff0000));

        // check if the symbolContainer should only be rendered once
        if (!renderinstruction.repeat) {
          return;
        }

        // recalculate the distances
        diff = current.offset(previous);

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
      previous = current;
    }
    //bitmap.dispose();
  }

  @override
  MapRectangle getBoundary() {
    throw UnimplementedError("Nodes not supported");
  }
}
