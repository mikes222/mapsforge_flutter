import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/src/shape_painter/shape_paint_area.dart';
import 'package:datastore_renderer/src/shape_painter/shape_paint_caption.dart';
import 'package:datastore_renderer/src/shape_painter/shape_paint_circle.dart';
import 'package:datastore_renderer/src/shape_painter/shape_paint_linesymbol.dart';
import 'package:datastore_renderer/src/shape_painter/shape_paint_pathtext.dart';
import 'package:datastore_renderer/src/shape_painter/shape_paint_polyline.dart';
import 'package:datastore_renderer/src/shape_painter/shape_paint_symbol.dart';
import 'package:logging/logging.dart';

class PainterFactory {
  static final _log = Logger('RenderContext');

  int created = 0;

  Future<ShapePainter<T>> createShapePaint<T extends Renderinstruction>(RenderInfo<T> renderInfo) async {
    if (renderInfo.shapePainter != null) return renderInfo.shapePainter!;

    if (renderInfo.renderInstruction.getPainter() != null) {
      renderInfo.shapePainter = renderInfo.renderInstruction.getPainter()! as ShapePainter<T>;
      return renderInfo.renderInstruction.getPainter() as ShapePainter<T>;
    }

    switch (renderInfo.renderInstruction.getType()) {
      case "area":
        ShapePainter<T> shapePaint = await ShapePaintArea.create(renderInfo.renderInstruction as RenderinstructionArea) as ShapePainter<T>;
        renderInfo.shapePainter = shapePaint;
        ++created;
        return shapePaint;
      case "caption":

        /// we need to calculate the boundary for the caption. Remember that we cannot
        /// use ui code in isolates but here we are back again from isolates so we can
        /// calculate the width/height of the caption.
        ShapePainter<T> shapePaint =
            await ShapePaintCaption.create(renderInfo.renderInstruction as RenderinstructionCaption, caption: renderInfo.caption!) as ShapePainter<T>;
        renderInfo.shapePainter = shapePaint;
        ++created;
        // since captions are dependent on the node/way properties we are not allowed to use this instance for other shapes, so do not assign it to shape.shapePaint
        return shapePaint;
      case "circle":
        ShapePainter<T> shapePaint = await ShapePaintCircle.create(renderInfo.renderInstruction as RenderinstructionCircle) as ShapePainter<T>;
        renderInfo.shapePainter = shapePaint;
        ++created;
        return shapePaint;
      // case "Hillshading":
      //   shapePaint = ShapePaintHillshading(shape as ShapeHillshading) as ShapePainter<T>;
      //   break;
      case "linesymbol":
        ShapePainter<T> shapePaint = await ShapePaintLinesymbol.create(renderInfo.renderInstruction as RenderinstructionLinesymbol) as ShapePainter<T>;
        renderInfo.shapePainter = shapePaint;
        ++created;
        return shapePaint;
      case "pathtext":
        ShapePainter<T> shapePaint =
            await ShapePaintPathtext.create(renderInfo.renderInstruction as RenderinstructionPathtext, renderInfo.caption!, renderInfo.stringPath!)
                as ShapePainter<T>;
        renderInfo.shapePainter = shapePaint;
        ++created;
        // since captions are dependent on the node/way properties we are not allowed to use this instance for other shapes, so do not assign it to shape.shapePaint
        return shapePaint;
      case "polyline":
        // same as area but for open ways
        ShapePainter<T> shapePaint = await ShapePaintPolyline.create(renderInfo.renderInstruction as RenderinstructionPolyline) as ShapePainter<T>;
        renderInfo.shapePainter = shapePaint;
        ++created;
        return shapePaint;
      case "symbol":
        ShapePainter<T> shapePaint = await ShapePaintSymbol.create(renderInfo.renderInstruction as RenderinstructionSymbol) as ShapePainter<T>;
        renderInfo.shapePainter = shapePaint;
        ++created;
        return shapePaint;
      default:
        throw Exception("cannot find ShapePaint for ${renderInfo.renderInstruction.getType()} of type ${renderInfo.runtimeType}");
    }
  }

  Future<void> initDrawingLayers(List<LayerContainer> drawingLayers) async {
    Timing timing = Timing(log: _log);
    List<Future> futures = [];

    for (LayerContainer layerContainer in drawingLayers) {
      for (RenderInfo renderInfo in layerContainer.renderInfoCollection.renderInfos) {
        futures.add(createShapePaint(renderInfo));
        if (futures.length > 100) {
          await Future.wait(futures);
          futures.clear();
        }
      }
      for (RenderInfo renderInfo in layerContainer.clashingInfoCollection.renderInfos) {
        futures.add(createShapePaint(renderInfo));
        if (futures.length > 100) {
          await Future.wait(futures);
          futures.clear();
        }
      }
      for (RenderInfo renderInfo in layerContainer.labels.renderInfos) {
        futures.add(createShapePaint(renderInfo));
        if (futures.length > 100) {
          await Future.wait(futures);
          futures.clear();
        }
      }
    }
    await Future.wait(futures);
    timing.done(100, "initDrawingLayers");
  }
}
