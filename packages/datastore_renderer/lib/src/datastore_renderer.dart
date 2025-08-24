import 'package:dart_common/datastore.dart';
import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_common/utils.dart';
import 'package:dart_rendertheme/model.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/renderer.dart';
import 'package:datastore_renderer/src/ui/tile_picture.dart';
import 'package:datastore_renderer/src/ui/ui_canvas.dart';
import 'package:datastore_renderer/src/util/datastore_reader.dart';
import 'package:datastore_renderer/src/util/layerutil.dart';
import 'package:datastore_renderer/src/util/painter_factory.dart';
import 'package:datastore_renderer/src/util/tile_dependencies.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

///
/// This renderer renders the bitmap for the tiles by using the given [Datastore].
///
class DatastoreRenderer extends Renderer {
  static final _log = Logger('DatastoreRenderer');
  static final Tag TAG_NATURAL_WATER = const Tag("natural", "water");

  final Datastore datastore;

  final Rendertheme renderTheme;

  /// When using the map heading north we can render the labels onto the images.
  /// However if you want to support rotation the labels should not rotate with
  /// the map so we are not allowed to render the labels onto the images.
  final bool renderLabels;

  TileDependencies? tileDependencies;

  late DatastoreReader _datastoreReader;

  DatastoreRenderer(this.datastore, this.renderTheme, this.renderLabels) {
    if (renderLabels) {
      tileDependencies = TileDependencies();
    } else {
      tileDependencies = null;
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
  Future<JobResult> executeJob(JobRequest job) async {
    Timing timing = Timing(log: _log, active: true, prefix: "${job.tile.toString()} ");
    // current performance measurements for isolates indicates that isolates are too slow so it makes no sense to use them currently. Seems
    // we need something like 600ms to start an isolate whereas the whole read-process just needs about 200ms
    RenderthemeZoomlevel renderthemeLevel = renderTheme.prepareZoomlevel(job.tile.zoomLevel);
    timing.lap(100, "$renderthemeLevel prepareZoomlevel");

    LayerContainerCollection? layerContainers = await _datastoreReader.read(datastore, job.tile, renderthemeLevel);

    //timing.lap(100, "RenderContext ${renderContext} created");
    if (layerContainers == null) {
      return JobResult.unsupported();
    }

    await PainterFactory().initDrawingLayers(layerContainers);
    UiCanvas canvas = UiCanvas.forRecorder(MapsforgeSettingsMgr().tileSize, MapsforgeSettingsMgr().tileSize);
    PixelProjection projection = PixelProjection(job.tile.zoomLevel);
    Mappoint leftUpper = projection.getLeftUpper(job.tile);
    UiRenderContext renderContext = UiRenderContext(canvas: canvas, reference: leftUpper, projection: projection);
    drawWays(layerContainers, renderContext);

    int labelCount = 0;
    if (renderLabels) {
      _LabelResult labelResult = _processLabels(renderContext, layerContainers.labels, job.tile);
      // rendering the labels directly into the canvas. Rotation of labels if the map rotates is not supported in this case.
      for (RenderInfo renderInfo in labelResult.labelsToDisposeAfterDrawing) {
        renderInfo.render(renderContext);
      }
      for (RenderInfo renderInfo in labelResult.labelsForNeighbours) {
        renderInfo.render(renderContext);
      }
    } else {
      // Returning the canvas with the map but without labels onto it. The labels have to be drawn directly into the view.
    }
    timing.lap(100, "Data read and prepared");
    TilePicture? picture = await canvas.finalizeBitmap();
    canvas.dispose();
    timing.done(100, "TilePicture created");
    //_log.info("Executing ${job.toString()} returns ${bitmap.toString()}");
    //_log.info("ways: ${mapReadResult.ways.length}, Areas: ${Area.count}, ShapePaintPolylineContainer: ${ShapePaintPolylineContainer.count}");
    return JobResult.normal(picture, layerContainers.labels);
  }

  @override
  Future<JobResult> retrieveLabels(JobRequest job) async {
    Timing timing = Timing(log: _log, active: true);
    // current performance measurements for isolates indicates that isolates are too slow so it makes no sense to use them currently. Seems
    // we need something like 600ms to start an isolate whereas the whole read-process just needs about 200ms
    RenderthemeZoomlevel renderthemeLevel = renderTheme.prepareZoomlevel(job.tile.zoomLevel);

    LayerContainerCollection? layerContainers = await _datastoreReader.readLabels(datastore, job.tile, job.rightLower ?? job.tile, renderthemeLevel);

    if (layerContainers == null) {
      return JobResult.unsupported();
    }

    await PainterFactory().initDrawingLayers(layerContainers);
    timing.done(100, "Retrieve labels for $job completed");
    return JobResult.normal(null, layerContainers.labels);
  }

  void drawWays(LayerContainerCollection layerContainers, UiRenderContext renderContext) {
    for (LayerContainer layerContainer in layerContainers.drawingLayers) {
      for (RenderInfo renderInfo in layerContainer.renderInfoCollection.renderInfos) {
        renderInfo.render(renderContext);
      }
    }
    for (RenderInfo renderInfo in layerContainers.clashingInfoCollection.renderInfos) {
      renderInfo.render(renderContext);
    }
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

  _LabelResult _processLabels(UiRenderContext renderContext, RenderInfoCollection renderInfoCollection, Tile tile) {
    // if we are drawing the labels per neighbour, we need to establish which neighbour-overlapping
    // elements need to be drawn.

    Set<RenderInfo> labelsForNeighbours = {};

    Set<RenderInfo> labelsToDisposeAfterDrawing = {};

    // get the overlapping elements for the current tile which were found while rendering the neighbours
    Set<Dependency>? labelsFromNeighbours = tileDependencies!.getOverlappingElements(tile);
    // if a neighbour has already been drawn, the elements drawn that overlap onto the
    // current neighbour should be in the neighbour dependencies, we add them to the labels that
    // need to be drawn onto this neighbour. For the multi-threaded renderer we also need to take
    // those tiles into account that are not yet in the TileCache: this is taken care of by the
    // set of tilesInProgress inside the TileDependencies.
    if (labelsFromNeighbours != null) {
      for (var dependency in labelsFromNeighbours) {
        if (dependency.tiles.isEmpty) {
          labelsToDisposeAfterDrawing.add(dependency.element);
        } else {
          labelsForNeighbours.add(dependency.element);
        }
      }
    }

    // at this point we have two lists: one is the list of labels that must be drawn because
    // they already overlap from other tiles [labelsToDraw]. The second one is [renderContext.labels] that contains
    // the elements on this neighbour that do not overlap onto a drawn neighbour.
    // now we go through this list, ordered by priority, to see which can be drawn without clashing.
    List<RenderInfo> toDraw2 = LayerUtil.removeCollisions(renderInfoCollection.renderInfos, List.of(labelsToDisposeAfterDrawing)..addAll(labelsForNeighbours));

    // We need to get the labels from the adjacent tiles if they have already been drawn
    // as those overlapping items must also be drawn on the current neighbour. They must be drawn regardless
    // of priority clashes as a part of them has alread been drawn.
    Set<Tile> neighbours = tile.getNeighbours();
    // update dependencies, add to the dependencies list all the elements that overlap to the
    // neighbouring tiles, first clearing out the cache for this relation.
    for (RenderInfo renderInfo in toDraw2) {
      List<Tile>? added;
      for (Tile neighbour in neighbours) {
        if (renderInfo.intersects(renderContext.projection.boundaryAbsolute(neighbour))) {
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
        if (added.isNotEmpty) {
          // the label is added to at least one neighbour, do not dispose() it
          tileDependencies!.addOverlappingElement(renderInfo, added);
          labelsForNeighbours.add(renderInfo);
          // print("Neightpor for neightbours drawn at ${added} $element");
        } else {
          // solely at this tile, we can safely dispose() the item after we draw it
          labelsToDisposeAfterDrawing.add(renderInfo);
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
