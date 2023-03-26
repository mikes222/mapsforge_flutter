import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/datastore.dart';
import 'package:mapsforge_flutter/src/datastore/datastorereadresult.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';
import 'package:mapsforge_flutter/src/renderer/tiledependencies.dart';
import 'package:mapsforge_flutter/src/rendertheme/rendercontext.dart';
import 'package:mapsforge_flutter/src/utils/layerutil.dart';

import '../rendertheme/renderinfo.dart';
import '../rendertheme/shape/shape.dart';
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

  /// true if isolates should be used for reading the mapfile. Isolate is flutter's
  /// way of using threads. However due to the huge amount of data which must
  /// be tunneled between the threads isolates are currently slower than working
  /// directly in the main thread. The only advantage so far is that the main thread
  /// is not blocked while the data are read.
  final bool useIsolate;

  late DatastoreReader _datastoreReader;

  MapDataStoreRenderer(
      this.datastore, this.renderTheme, this.symbolCache, this.renderLabels,
      {this.useIsolate = false}) {
    if (renderLabels) {
      this.tileDependencies = TileDependencies();
    } else {
      this.tileDependencies = null;
    }
    _datastoreReader = DatastoreReader(useIsolate: useIsolate);
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
    Timing timing = Timing(log: _log, active: true);
    // current performance measurements for isolates indicates that isolates are too slow so it makes no sense to use them currently. Seems
    // we need something like 600ms to start an isolate whereas the whole read-process just needs about 200ms
    RenderContext renderContext = RenderContext(job, renderTheme);
    this.renderTheme.prepareScale(job.tile.zoomLevel);

    DatastoreReadResult? mapReadResult;
    IsolateMapReplyParams params = await _datastoreReader.read(
        datastore, job.tile, renderContext.projection, renderContext);
    mapReadResult = params.result;
    renderContext = params.renderContext;
    timing.lap(100,
        "${mapReadResult?.ways.length} ways and ${mapReadResult?.pointOfInterests.length} pois read for tile");
    if (mapReadResult == null) {
      TileBitmap bmp = await createNoDataBitmap(job.tileSize);
      return JobResult(bmp, JOBRESULT.UNSUPPORTED);
    }
    if ((mapReadResult.ways.length) > 100000) {
      _log.warning(
          "Many ways (${mapReadResult.ways.length}) in this readResult, consider shrinking your mapfile.");
    }
    await renderContext.initDrawingLayers(symbolCache);
    timing.lap(100,
        "${mapReadResult.ways.length} ways and ${mapReadResult.pointOfInterests.length} pois initialized for tile");
    CanvasRasterer canvasRasterer = CanvasRasterer(job.tileSize.toDouble(),
        job.tileSize.toDouble(), "MapDatastoreRenderer ${job.tile.toString()}");
    canvasRasterer.startCanvasBitmap();
    timing.lap(100, "startCanvasBitmap for tile");
    canvasRasterer.drawWays(renderContext);
    timing.lap(
        100, "${renderContext.drawingLayers.length} way-layers for tile");

    int labelCount = 0;
    List<RenderInfo<Shape>>? renderInfos;
    if (this.renderLabels) {
      _LabelResult labelResult = _processLabels(renderContext);
      labelCount = labelResult.labelsToDisposeAfterDrawing.length +
          labelResult.labelsForNeighbours.length;
      //_log.info("Labels to draw: $labelsToDraw");
      // now draw the ways and the labels
      canvasRasterer.drawMapElements(
          labelResult.labelsForNeighbours, renderContext.projection, job.tile);
      canvasRasterer.drawMapElements(labelResult.labelsToDisposeAfterDrawing,
          renderContext.projection, job.tile);
      // labelResult.labelsToDisposeAfterDrawing.forEach((element) {
      //   element.dispose();
      // });
      timing.lap(100, "$labelCount labels for tile");
      // labelsToDraw.forEach((element) {
      //   _log.info(
      //       "  $element, ${element.boundaryAbsolute!.intersects(renderContext.projection.boundaryAbsolute(job.tile)) ? "intersects" : "non-intersects"}");
      // });
    } else {
      // store elements for this tile in the label cache
      renderInfos = LayerUtil.collisionFreeOrdered(
          renderContext.labels, renderContext.projection);
      // this.labelStore.storeMapItems(
      //     job.tile, renderContext.labels, renderContext.projection);
      timing.lap(100, "storeMapItems for tile");
    }
//    if (!job.labelsOnly && renderContext.renderTheme.hasMapBackgroundOutside()) {
//      // blank out all areas outside of map
//      Rectangle insideArea = this.mapDataStore.boundingBox().getPositionRelativeToTile(job.tile);
//      if (!job.hasAlpha) {
//        renderContext.canvasRasterer.fillOutsideAreas(renderContext.renderTheme.getMapBackgroundOutside(), insideArea);
//      } else {
//        renderContext.canvasRasterer.fillOutsideAreas(Color.TRANSPARENT, insideArea);
//      }
//    }
    TileBitmap? bitmap =
        (await canvasRasterer.finalizeCanvasBitmap() as TileBitmap?);
    int actions = (canvasRasterer.canvas as FlutterCanvas).actions;
    canvasRasterer.destroy();
    timing.lap(100,
        "$labelCount elements and labels, $actions actions in canvas for tile");
    //_log.info("Executing ${job.toString()} returns ${bitmap.toString()}");
    //_log.info("ways: ${mapReadResult.ways.length}, Areas: ${Area.count}, ShapePaintPolylineContainer: ${ShapePaintPolylineContainer.count}");
    return JobResult(bitmap, JOBRESULT.NORMAL, renderInfos);
  }

  @override
  Future<JobResult> retrieveLabels(Job job) async {
    Timing timing = Timing(log: _log, active: true);
    // current performance measurements for isolates indicates that isolates are too slow so it makes no sense to use them currently. Seems
    // we need something like 600ms to start an isolate whereas the whole read-process just needs about 200ms
    RenderContext renderContext = RenderContext(job, renderTheme);
    this.renderTheme.prepareScale(job.tile.zoomLevel);

    DatastoreReadResult? mapReadResult;
    IsolateMapReplyParams params = await _datastoreReader.readLabels(
        datastore, job.tile, renderContext.projection, renderContext);
    mapReadResult = params.result;
    renderContext = params.renderContext;
    timing.lap(100,
        "${mapReadResult?.ways.length} ways and ${mapReadResult?.pointOfInterests.length} pois for labels");
    if (mapReadResult == null) {
      return JobResult(null, JOBRESULT.UNSUPPORTED);
    }
    if ((mapReadResult.ways.length) > 100000) {
      _log.warning(
          "Many ways (${mapReadResult.ways.length}) in this readResult, consider shrinking your mapfile.");
    }

    // unfortunately we need the painter for captions in order to determine the size of the caption. In isolates however we cannot access
    // ui code. We are in an isolate here. We are doomed.
    for (RenderInfo renderInfo in renderContext.labels) {
      await renderInfo.createShapePaint(symbolCache);
    }
    List<RenderInfo<Shape>>? renderInfos = LayerUtil.collisionFreeOrdered(
        renderContext.labels, renderContext.projection);
    // this.labelStore.storeMapItems(
    //     job.tile, renderContext.labels, renderContext.projection);
    timing.lap(100,
        "${renderInfos.length} items from collisionFreeOrdered for labels");
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

    // we sort the list of labels for this tile and
    // remove those elements that clash in this list already.
    List<RenderInfo> currentElementsOrdered = LayerUtil.collisionFreeOrdered(
        renderContext.labels, renderContext.projection);

    // get the overlapping elements for the current tile which were found while rendering the neighbours
    Set<Dependency>? labelsFromNeighbours =
        tileDependencies!.getOverlappingElements(renderContext.job.tile);
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
    List<RenderInfo> toDraw2 = LayerUtil.removeCollisions(
        currentElementsOrdered,
        List.of(labelsToDisposeAfterDrawing)..addAll(labelsForNeighbours),
        renderContext.projection);

    // We need to get the labels from the adjacent tiles if they have already been drawn
    // as those overlapping items must also be drawn on the current neighbour. They must be drawn regardless
    // of priority clashes as a part of them has alread been drawn.
    Set<Tile> neighbours = renderContext.job.tile.getNeighbours();
    // update dependencies, add to the dependencies list all the elements that overlap to the
    // neighbouring tiles, first clearing out the cache for this relation.
    for (RenderInfo element in toDraw2) {
      List<Tile>? added;
      for (Tile neighbour in neighbours) {
        if (element.intersects(
            renderContext.projection.boundaryAbsolute(neighbour),
            renderContext.projection)) {
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
