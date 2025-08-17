import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/datastore.dart';
import 'package:mapsforge_flutter/src/graphics/tilepicture.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/renderer/tiledependencies.dart';
import 'package:mapsforge_flutter/src/rendertheme/rendercontext.dart';
import 'package:mapsforge_flutter/src/utils/layerutil.dart';
import 'package:mapsforge_flutter/src/utils/mapsforge_constants.dart';

import '../rendertheme/renderinfo.dart';
import '../utils/timing.dart';
import 'canvasrasterer.dart';
import 'datastorereader.dart';

///
/// This renderer renders the bitmap for the tiles by using the given [Datastore].
///
class MapDataStoreRenderer extends JobRenderer {
  static final _log = new Logger('MapDataStoreRenderer');
  static final Tag TAG_NATURAL_WATER = const Tag("natural", "water");

  final Datastore datastore;

  final RenderTheme renderTheme;

  final SymbolCache symbolCache;

  /// When using the map heading north we can render the labels onto the images.
  /// However if you want to support rotation the labels should not rotate with
  /// the map so we are not allowed to render the labels onto the images.
  final bool renderLabels;

  TileDependencies? tileDependencies;

  late DatastoreReader _datastoreReader;

  MapDataStoreRenderer(this.datastore, this.renderTheme, this.symbolCache, this.renderLabels) {
    if (renderLabels) {
      this.tileDependencies = TileDependencies();
    } else {
      this.tileDependencies = null;
    }
    _datastoreReader = DatastoreReader();
  }

  @override
  @mustCallSuper
  void dispose() {
    tileDependencies?.dispose();
    super.dispose();
  }

  ///
  /// Executes a given job and returns a future with the bitmap of this job.
  /// @returns null if the datastore does not support the requested tile
  /// @returns the Bitmap for the requested tile
  @override
  Future<JobResult> executeJob(Job job) async {
    Timing timing = Timing(log: _log, active: true, prefix: "${job.tile.toString()} ");
    // current performance measurements for isolates indicates that isolates are too slow so it makes no sense to use them currently. Seems
    // we need something like 600ms to start an isolate whereas the whole read-process just needs about 200ms
    RenderthemeLevel renderthemeLevel = this.renderTheme.prepareZoomlevel(job.tile.zoomLevel);
    timing.lap(100, "$renderthemeLevel prepareZoomlevel");

    RenderContext? renderContext = await _datastoreReader.read(datastore, job.tile, renderthemeLevel, renderTheme.levels);

    //timing.lap(100, "RenderContext ${renderContext} created");
    if (renderContext == null) {
      TilePicture bmp = await createNoDataBitmap(MapsforgeConstants().tileSize);
      return JobResult(bmp, JOBRESULT.UNSUPPORTED);
    }
    await renderContext.initDrawingLayers(symbolCache);
    //renderContext.statistics();
    CanvasRasterer canvasRasterer = CanvasRasterer(MapsforgeConstants().tileSize, MapsforgeConstants().tileSize, "MapDatastoreRenderer ${job.tile.toString()}");
    canvasRasterer.startCanvasBitmap();
    Mappoint leftUpper = renderContext.projection.getLeftUpper(renderContext.upperLeft);
    //canvasRasterer.canvas.translate(-leftUpper.x, -leftUpper.y);
    canvasRasterer.drawWays(renderContext, leftUpper);

    List<RenderInfo> renderInfos = LayerUtil.collisionFreeOrdered(renderContext.labels, renderContext.projection);
    renderContext.labels.clear();
    renderContext.labels.addAll(renderInfos);
    for (List<RenderInfo> wayList in renderContext.clashDrawingLayer.ways) {
      List<RenderInfo> renderInfos = LayerUtil.collisionFreeOrdered(wayList, renderContext.projection);
      wayList.clear();
      wayList.addAll(renderInfos);
    }

    int labelCount = 0;
    if (this.renderLabels) {
      _LabelResult labelResult = _processLabels(renderContext);
      labelCount = labelResult.labelsToDisposeAfterDrawing.length + labelResult.labelsForNeighbours.length;
      //_log.info("Labels to draw: $labelsToDraw");
      // now draw the ways and the labels
      canvasRasterer.drawMapElements(labelResult.labelsForNeighbours, renderContext.projection, leftUpper, job.tile);
      canvasRasterer.drawMapElements(labelResult.labelsToDisposeAfterDrawing, renderContext.projection, leftUpper, job.tile);
      // labelsToDraw.forEach((element) {
      //   _log.info(
      //       "  $element, ${element.boundaryAbsolute!.intersects(renderContext.projection.boundaryAbsolute(job.tile)) ? "intersects" : "non-intersects"}");
      // });
    }
    timing.lap(100, "RenderContext ${renderContext}  final");
    TilePicture? picture = await canvasRasterer.finalizeCanvasBitmap();
    canvasRasterer.destroy();
    timing.done(100, "RenderContext ${renderContext} , $labelCount labels, ${canvasRasterer} completed");
    //_log.info("Executing ${job.toString()} returns ${bitmap.toString()}");
    //_log.info("ways: ${mapReadResult.ways.length}, Areas: ${Area.count}, ShapePaintPolylineContainer: ${ShapePaintPolylineContainer.count}");
    return JobResult(picture, JOBRESULT.NORMAL, renderContext.labels);
  }

  @override
  Future<JobResult> retrieveLabels(Job job) async {
    Timing timing = Timing(log: _log, active: true);
    // current performance measurements for isolates indicates that isolates are too slow so it makes no sense to use them currently. Seems
    // we need something like 600ms to start an isolate whereas the whole read-process just needs about 200ms
    RenderthemeLevel renderthemeLevel = this.renderTheme.prepareZoomlevel(job.tile.zoomLevel);

    RenderContext? renderContext = await _datastoreReader.readLabels(datastore, job.tile, renderthemeLevel, renderTheme.levels);

    timing.lap(100, "RenderContext ${renderContext}  for labels for tile ${renderContext?.upperLeft}");
    if (renderContext == null) {
      return JobResult(null, JOBRESULT.UNSUPPORTED);
    }

    // unfortunately we need the painter for captions in order to determine the size of the caption. In isolates however we cannot access
    // ui code. We are in an isolate here. We are doomed.
    for (RenderInfo renderInfo in renderContext.labels) {
      await renderInfo.createShapePaint(symbolCache);
    }
    List<RenderInfo<Shape>>? renderInfos = LayerUtil.collisionFreeOrdered(renderContext.labels, renderContext.projection);
    // this.labelStore.storeMapItems(
    //     job.tile, renderContext.labels, renderContext.projection);
    timing.done(100, "${renderInfos.length} items from collisionFreeOrdered for labels for tile ${renderContext.upperLeft}");
    //_log.info("Executing ${job.toString()} returns ${bitmap.toString()}");
    //_log.info("ways: ${mapReadResult.ways.length}, Areas: ${Area.count}, ShapePaintPolylineContainer: ${ShapePaintPolylineContainer.count}");
    return JobResult(null, JOBRESULT.NORMAL, renderInfos);
  }

  static List<Mappoint> getTilePixelCoordinates(int tileSize) {
    List<Mappoint> result = [];
    result.add(const Mappoint(0, 0));
    result.add(Mappoint(tileSize.toDouble(), 0));
    result.add(Mappoint(tileSize.toDouble(), tileSize.toDouble()));
    result.add(Mappoint(0, tileSize.toDouble()));
    result.add(result[0]);
    return result;
  }

  _LabelResult _processLabels(RenderContext renderContext) {
    // if we are drawing the labels per neighbour, we need to establish which neighbour-overlapping
    // elements need to be drawn.
    Set<RenderInfo> labelsToDisposeAfterDrawing = {};

    Set<RenderInfo> labelsForNeighbours = {};

    // get the overlapping elements for the current tile which were found while rendering the neighbours
    Set<Dependency>? labelsFromNeighbours = tileDependencies!.getOverlappingElements(renderContext.upperLeft);
    // if a neighbour has already been drawn, the elements drawn that overlap onto the
    // current neighbour should be in the neighbour dependencies, we add them to the labels that
    // need to be drawn onto this neighbour. For the multi-threaded renderer we also need to take
    // those tiles into account that are not yet in the TileCache: this is taken care of by the
    // set of tilesInProgress inside the TileDependencies.
    if (labelsFromNeighbours != null) {
      labelsFromNeighbours.forEach((dependency) {
        if (dependency.tiles.length == 0) {
          labelsToDisposeAfterDrawing.add(dependency.element);
        } else {
          labelsForNeighbours.add(dependency.element);
        }
      });
    }

    // at this point we have two lists: one is the list of labels that must be drawn because
    // they already overlap from other tiles [labelsToDraw]. The second one is [renderContext.labels] that contains
    // the elements on this neighbour that do not overlap onto a drawn neighbour.
    // now we go through this list, ordered by priority, to see which can be drawn without clashing.
    List<RenderInfo> toDraw2 =
        LayerUtil.removeCollisions(renderContext.labels, List.of(labelsToDisposeAfterDrawing)..addAll(labelsForNeighbours), renderContext.projection);

    // We need to get the labels from the adjacent tiles if they have already been drawn
    // as those overlapping items must also be drawn on the current neighbour. They must be drawn regardless
    // of priority clashes as a part of them has alread been drawn.
    Set<Tile> neighbours = renderContext.upperLeft.getNeighbours();
    // update dependencies, add to the dependencies list all the elements that overlap to the
    // neighbouring tiles, first clearing out the cache for this relation.
    for (RenderInfo element in toDraw2) {
      List<Tile>? added;
      for (Tile neighbour in neighbours) {
        if (element.intersects(renderContext.projection.boundaryAbsolute(neighbour), renderContext.projection)) {
          if (tileDependencies!.isDrawn(neighbour)) {
            // neighbour is drawn and this element intersects with the already
            // drawn neighbour, so we do not want to draw it at all
            added = null;
            break;
          } else {
            added ??= [];
            added.add(neighbour);
          }
        } else {
          added ??= [];
        }
      }
      if (added == null) {
        // do not draw the element since one of the intersecting neighbours are already drawn
        //element.dispose();
        //print("Neightpor not yet drawn at ${added} $element");
      } else {
        if (added.length > 0) {
          // the label is added to at least one neighbour, do not dispose() it
          tileDependencies!.addOverlappingElement(element, added);
          labelsForNeighbours.add(element);
          // print("Neightpor for neightbours drawn at ${added} $element");
        } else {
          // solely at this tile, we can safely dispose() the item after we draw it
          labelsToDisposeAfterDrawing.add(element);
          // print("Neightpor for dispose drawn at ${added} $element");
        }
      }
    }
    return _LabelResult(labelsForNeighbours, labelsToDisposeAfterDrawing);
  }

  @override
  String getRenderKey() {
    return "${renderTheme.hashCode ^ renderLabels.hashCode}";
  }
}

/////////////////////////////////////////////////////////////////////////////

class _LabelResult {
  final Set<RenderInfo> labelsToDisposeAfterDrawing;

  final Set<RenderInfo> labelsForNeighbours;

  _LabelResult(this.labelsForNeighbours, this.labelsToDisposeAfterDrawing);
}

/////////////////////////////////////////////////////////////////////////////
