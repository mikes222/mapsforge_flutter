import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinfo.dart';

import '../../core.dart';
import '../layer/job/job.dart';

/// A RenderContext contains all the information and data to render a map area, it is passed between
/// calls in order to avoid local data stored in the DatabaseRenderer.
class RenderContext {
  static final int MAX_DRAWING_LAYERS = 11;

  final Job job;

  final RenderTheme renderTheme;

  // The current drawing layer is the layer defined by the poi/way.
  late LayerPaintContainer currentDrawingLayer;

  /// The points to process. Points may be drawn directly into the tile or later onto the tile. Reason is that
  /// points should be drawn horizontally even if the underlying map (=tiles) are rotated.
  final List<RenderInfo> labels = [];

  late List<LayerPaintContainer> drawingLayers;

  /// A drawing layer for symbols which do not need to be rotated based on the current rotation of the map. This
  /// applies for example to arrows for one-way-streets. But before painting the arrows we want to avoid clashes.
  late LayerPaintContainer clashDrawingLayer;

  final PixelProjection projection;

  RenderContext(this.job, this.renderTheme)
      : projection = PixelProjection(job.tile.zoomLevel, job.tileSize) {
    this.drawingLayers = _createWayLists();
    currentDrawingLayer = drawingLayers[0];
    clashDrawingLayer = LayerPaintContainer(renderTheme.getLevels());
  }

  void setDrawingLayers(int layer) {
    assert(layer >= 0);
    if (layer >= RenderContext.MAX_DRAWING_LAYERS) {
      layer = RenderContext.MAX_DRAWING_LAYERS - 1;
    }
    this.currentDrawingLayer = drawingLayers.elementAt(layer);
  }

  /// The level is the order of the renderinstructions in the xml-file
  void addToCurrentDrawingLayer(int level, RenderInfo element) {
    currentDrawingLayer.add(level, element);
  }

  void addToClashDrawingLayer(int level, RenderInfo element) {
    clashDrawingLayer.add(level, element);
  }

  Future<void> initDrawingLayers(SymbolCache symbolCache) async {
    for (LayerPaintContainer layerPaintContainer in drawingLayers) {
      for (List<RenderInfo> wayList in layerPaintContainer.ways) {
        for (RenderInfo renderInfo in wayList) {
          await renderInfo.createShapePaint(symbolCache);
        }
      }
    }
    for (List<RenderInfo> wayList in clashDrawingLayer.ways) {
      for (RenderInfo renderInfo in wayList) {
        await renderInfo.createShapePaint(symbolCache);
      }
    }
    for (RenderInfo renderInfo in labels) {
      await renderInfo.createShapePaint(symbolCache);
    }
  }

  /**
   * Just a way of generating a hash key for a tile if only the RendererJob is known.
   *
   * @param tile the tile that changes
   * @return a RendererJob based on the current one, only tile changes
   */
  // Job otherTile(Tile tile) {
  //   return Job(tile, this.job.hasAlpha, this.job.textScale);
  // }

  List<LayerPaintContainer> _createWayLists() {
    List<LayerPaintContainer> result = [];
    int levels = this.renderTheme.getLevels();
    //print("LAYERS: $LAYERS, levels: $levels");

    for (int i = 0; i < MAX_DRAWING_LAYERS; ++i) {
      result.add(LayerPaintContainer(levels));
    }
    return result;
  }

  void disposeLabels() {
    labels.forEach((element) {
      //element.dispose();
    });
    labels.clear();
  }
}

/////////////////////////////////////////////////////////////////////////////

///
/// A container which holds all paintings for one layer. A layer is defined by the datastore. It is a property of the ways
/// in the datastore. So in other words you can define which way should be drawn in the back and which should be drawn
/// at the front.
class LayerPaintContainer {
  late List<List<RenderInfo>> ways;

  ///
  /// Define the maximum number of levels.
  LayerPaintContainer(int levels) {
    ways = List.generate(levels, (int index) => []);
  }

  void add(int level, RenderInfo element) {
    //_log.info("Adding level $level to layer with ${drawingLayers.length} levels");
    this.ways[level].add(element);
  }
}
