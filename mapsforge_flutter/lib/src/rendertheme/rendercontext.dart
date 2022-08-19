import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/paintelements/point/mapelementcontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/shape_paint_container.dart';

import '../layer/job/job.dart';

/// A RenderContext contains all the information and data to render a map area, it is passed between
/// calls in order to avoid local data stored in the DatabaseRenderer.
class RenderContext {
  static final int MAX_DRAWING_LAYERS = 11;

  final Job job;

  final RenderTheme renderTheme;

  // Data generated for the rendering process
  late LayerPaintContainer currentDrawingLayer;

  /// The points to process. Points may be drawn directly into the tile or later onto the tile. Reason is that
  /// points should be drawn horizontally even if the underlying map (=tiles) are rotated.
  final List<MapElementContainer> labels = [];

  late List<LayerPaintContainer> drawingLayers;

  final PixelProjection projection;

  RenderContext(this.job, this.renderTheme)
      : projection = PixelProjection(job.tile.zoomLevel, job.tileSize) {
    this.drawingLayers = _createWayLists();
    currentDrawingLayer = drawingLayers[0];
  }

  void setDrawingLayers(int layer) {
    assert(layer >= 0);
    if (layer >= RenderContext.MAX_DRAWING_LAYERS) {
      layer = RenderContext.MAX_DRAWING_LAYERS - 1;
    }
    this.currentDrawingLayer = drawingLayers.elementAt(layer);
  }

  void addToCurrentDrawingLayer(int level, ShapePaintContainer element) {
    currentDrawingLayer.add(level, element);
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
      element.dispose();
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
  late List<List<ShapePaintContainer>> ways;

  ///
  /// Define the maximum number of levels.
  LayerPaintContainer(int levels) {
    ways = List.generate(levels, (int index) => []);
  }

  void add(int level, ShapePaintContainer element) {
    //_log.info("Adding level $level to layer with ${drawingLayers.length} levels");
    this.ways[level].add(element);
  }
}
