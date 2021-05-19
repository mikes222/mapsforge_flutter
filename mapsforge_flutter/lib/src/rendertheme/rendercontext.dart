import 'dart:math';

import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/projection/pixelprojection.dart';

import '../layer/job/job.dart';
import '../mapelements/mapelementcontainer.dart';
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
  final Job job;
  final RenderTheme renderTheme;

  final GraphicFactory graphicFactory;

  // Data generated for the rendering process
  List<List<ShapePaintContainer>>? drawingLayers;
  final List<MapElementContainer> labels;
  late List<List<List<ShapePaintContainer>>> ways;

  PixelProjection? _projection;

  RenderContext(this.job, this.renderTheme, this.graphicFactory) : labels = [] {
    this.renderTheme.scaleTextSize(job.textScale, job.tile.zoomLevel);
    this.ways = _createWayLists();
    setScaleStrokeWidth(this.job.tile.zoomLevel);
  }

  void dispose() {
    labels.forEach((element) {
      element.dispose();
    });
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
    //_log.info("Adding level $level to layer with ${drawingLayers.length} levels");
    this.drawingLayers![level].add(element);
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

  List<List<List<ShapePaintContainer>>> _createWayLists() {
    List<List<List<ShapePaintContainer>>> result = [];
    int levels = this.renderTheme.getLevels()!;
    assert(levels > 0);

    for (int i = 0; i < LAYERS; ++i) {
      List<List<ShapePaintContainer>> innerWayList = [];
      for (int j = 0; j < levels; ++j) {
        innerWayList.add([]);
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
    this.renderTheme.scaleStrokeWidth(pow(STROKE_INCREASE, zoomLevelDiff) as double, this.job.tile.zoomLevel);
  }

  PixelProjection get projection {
    if (_projection != null) return _projection!;
    _projection = PixelProjection(job.tile.zoomLevel, job.tileSize);
    return _projection!;
  }
}
