import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/renderinstruction.dart';
import 'package:datastore_renderer/shape_painter.dart';
import 'package:logging/logging.dart';

class PainterFactory {
  static final _log = Logger('PainterFactory');

  int created = 0;

  Future<ShapePainter<T>> createShapePainter<T extends Renderinstruction>(RenderInfo<T> renderInfo) async {
    if (renderInfo.shapePainter != null) return renderInfo.shapePainter!;

    if (renderInfo.renderInstruction.getPainter() != null) {
      renderInfo.shapePainter = renderInfo.renderInstruction.getPainter()! as ShapePainter<T>;
      return renderInfo.renderInstruction.getPainter() as ShapePainter<T>;
    }

    switch (renderInfo.renderInstruction.getType()) {
      case "area":
        ShapePainter<T> shapePainter = await ShapePaintArea.create(renderInfo.renderInstruction as RenderinstructionArea) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        ++created;
        return shapePainter;
      case "caption":

        /// we need to calculate the boundary for the caption. Remember that we cannot
        /// use ui code in isolates but here we are back again from isolates so we can
        /// calculate the width/height of the caption.
        ShapePainter<T> shapePainter = await ShapePainterCaption.create(renderInfo.renderInstruction as RenderinstructionCaption) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        ++created;
        // since captions are dependent on the node/way properties we are not allowed to use this instance for other shapes, so do not assign it to shape.shapePainter
        return shapePainter;
      case "circle":
        ShapePainter<T> shapePainter = await ShapePainterCircle.create(renderInfo.renderInstruction as RenderinstructionCircle) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        ++created;
        return shapePainter;
      // case "Hillshading":
      //   shapePainter = ShapePaintHillshading(shape as ShapeHillshading) as ShapePainter<T>;
      //   break;
      case "icon":
        ShapePainter<T> shapePainter = await ShapePainterIcon.create(renderInfo.renderInstruction as RenderinstructionIcon) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        ++created;
        return shapePainter;
      case "linesymbol":
        ShapePainter<T> shapePainter = await ShapePainterLinesymbol.create(renderInfo.renderInstruction as RenderinstructionLinesymbol) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        ++created;
        return shapePainter;
      case "polyline":
        // same as area but for open ways
        ShapePainter<T> shapePainter = await ShapePainterPolyline.create(renderInfo.renderInstruction as RenderinstructionPolyline) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        ++created;
        return shapePainter;
      case "polylinetext":
        ShapePainter<T> shapePainter = await ShapePainterPolylineText.create(renderInfo.renderInstruction as RenderinstructionPolylineText) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        ++created;
        // since captions are dependent on the node/way properties we are not allowed to use this instance for other shapes, so do not assign it to shape.shapePainter
        return shapePainter;
      case "rect":
        ShapePainter<T> shapePainter = await ShapePainterRect.create(renderInfo.renderInstruction as RenderinstructionRect) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        ++created;
        return shapePainter;
      case "symbol":
        ShapePainter<T> shapePainter = await ShapePainterSymbol.create(renderInfo.renderInstruction as RenderinstructionSymbol) as ShapePainter<T>;
        renderInfo.shapePainter = shapePainter;
        ++created;
        return shapePainter;
      default:
        throw Exception("cannot find ShapePaint for ${renderInfo.renderInstruction.getType()} of type ${renderInfo.runtimeType}");
    }
  }

  Future<void> initDrawingLayers(LayerContainerCollection layerContainers) async {
    Timing timing = Timing(log: _log);
    List<Future> futures = [];

    for (LayerContainer layerContainer in layerContainers.drawingLayers) {
      for (RenderInfo renderInfo in layerContainer.renderInfoCollection.renderInfos) {
        futures.add(createShapePainter(renderInfo));
        if (futures.length > 100) {
          await Future.wait(futures);
          futures.clear();
        }
      }
    }
    for (RenderInfo renderInfo in layerContainers.clashingInfoCollection.renderInfos) {
      futures.add(createShapePainter(renderInfo));
      if (futures.length > 100) {
        await Future.wait(futures);
        futures.clear();
      }
    }
    for (RenderInfo renderInfo in layerContainers.labels.renderInfos) {
      futures.add(createShapePainter(renderInfo));
      if (futures.length > 100) {
        await Future.wait(futures);
        futures.clear();
      }
    }
    await Future.wait(futures);
    timing.done(100, "initDrawingLayers");
  }
}
