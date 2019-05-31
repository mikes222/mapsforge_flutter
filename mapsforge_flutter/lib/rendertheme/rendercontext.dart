import 'dart:math';

import '../mapelements/mapelementcontainer.dart';
import '../model/tile.dart';
import '../renderer/canvasrasterer.dart';
import '../renderer/rendererjob.dart';
import '../renderer/shapepaintcontainer.dart';
import '../rendertheme/rule/rendertheme.dart';

/**
 * A RenderContext contains all the information and data to render a map area, it is passed between
 * calls in order to avoid local data stored in the DatabaseRenderer.
 */
class RenderContext {
  static final int LAYERS = 11;

  static final double STROKE_INCREASE = 1.5;
  static final int STROKE_MIN_ZOOM_LEVEL = 12;
  final RendererJob rendererJob;
  RenderTheme renderTheme;

  // Configuration that drives the rendering
  final CanvasRasterer canvasRasterer;

  // Data generated for the rendering process
  List<List<ShapePaintContainer>> drawingLayers;
  final List<MapElementContainer> labels;
  List<List<List<ShapePaintContainer>>> ways;

  RenderContext(this.rendererJob, this.canvasRasterer) : labels = new List() {
    this.renderTheme = rendererJob.renderTheme;
    this
        .renderTheme
        .scaleTextSize(rendererJob.textScale, rendererJob.tile.zoomLevel);
    this.ways = createWayLists();
    setScaleStrokeWidth(this.rendererJob.tile.zoomLevel);
  }

  void destroy() {
    this.canvasRasterer.destroy();
  }

  void setDrawingLayers(int layer) {
    if (layer < 0) {
      layer = 0;
    } else if (layer >= RenderContext.LAYERS) {
      layer = RenderContext.LAYERS - 1;
    }
    this.drawingLayers = ways.elementAt(layer);
  }

  void addToCurrentDrawingLayer(int level, ShapePaintContainer element) {
    this.drawingLayers.elementAt(level).add(element);
  }

  /**
   * Just a way of generating a hash key for a tile if only the RendererJob is known.
   *
   * @param tile the tile that changes
   * @return a RendererJob based on the current one, only tile changes
   */
  RendererJob otherTile(Tile tile) {
    return new RendererJob(
        tile,
        this.rendererJob.mapDataStore,
        this.rendererJob.renderTheme,
        this.rendererJob.displayModel,
        this.rendererJob.textScale,
        this.rendererJob.hasAlpha,
        this.rendererJob.labelsOnly);
  }

  List<List<List<ShapePaintContainer>>> createWayLists() {
    List<List<List<ShapePaintContainer>>> result = new List(LAYERS);
    int levels = this.renderTheme.getLevels();

    for (int i = LAYERS - 1; i >= 0; --i) {
      List<List<ShapePaintContainer>> innerWayList = new List(levels);
      for (int j = levels - 1; j >= 0; --j) {
        innerWayList.add(new List<ShapePaintContainer>(0));
      }
      result.add(innerWayList);
    }
    return result;
  }

  /**
   * Sets the scale stroke factor for the given zoom level.
   *
   * @param zoomLevel the zoom level for which the scale stroke factor should be set.
   */
  void setScaleStrokeWidth(int zoomLevel) {
    int zoomLevelDiff = max(zoomLevel - STROKE_MIN_ZOOM_LEVEL, 0);
    this.renderTheme.scaleStrokeWidth(
        pow(STROKE_INCREASE, zoomLevelDiff), this.rendererJob.tile.zoomLevel);
  }
}
