import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/datastore.dart';
import 'package:mapsforge_flutter/src/datastore/datastorereadresult.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/datastore/way.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';
import 'package:mapsforge_flutter/src/paintelements/point/mapelementcontainer.dart';
import 'package:mapsforge_flutter/src/paintelements/shape/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/renderer/tiledependencies.dart';
import 'package:mapsforge_flutter/src/rendertheme/rendercontext.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/utils/isolatemixin.dart';
import 'package:mapsforge_flutter/src/utils/layerutil.dart';

import 'canvasrasterer.dart';

///
/// This renderer renders the bitmap for the tiles by using the given [Datastore].
///
class MapDataStoreRenderer extends JobRenderer
    with IsolateMixin<IsolateMapInitParam> {
  static final _log = new Logger('MapDataStoreRenderer');
  static final Tag TAG_NATURAL_WATER = const Tag("natural", "water");

  final Datastore datastore;

  final RenderTheme renderTheme;

  final SymbolCache symbolCache;

  final bool renderLabels;

  TileDependencies? tileDependencies;

  final TileBasedLabelStore labelStore;

  final bool useIsolate;

  MapDataStoreRenderer(
      this.datastore, this.renderTheme, this.symbolCache, this.renderLabels,
      {this.useIsolate = false})
      : labelStore = TileBasedLabelStore(100) {
    if (renderLabels) {
      this.tileDependencies = TileDependencies();
    } else {
      this.tileDependencies = null;
    }
  }

  ///
  /// Executes a given job and returns a future with the bitmap of this job.
  /// @returns null if the datastore does not support the requested tile
  /// @returns the Bitmap for the requested tile
  @override
  Future<JobResult> executeJob(Job job) async {
    bool showTiming = true;
    // current performance measurements for isolates indicates that isolates are too slow so it makes no sense to use them currently. Seems
    // we need something like 600ms to start an isolate whereas the whole read-process just needs about 200ms
    //_log.info("Executing ${job.toString()}");
    int time = DateTime.now().millisecondsSinceEpoch;
    RenderContext renderContext = RenderContext(job, renderTheme);
    this.renderTheme.prepareScale(job.tile.zoomLevel);
    if (!this.datastore.supportsTile(job.tile, renderContext.projection)) {
      // return if we do not have data for the requested tile in the datastore
      TileBitmap bmp = await createNoDataBitmap(job.tileSize);
      return JobResult(bmp, JOBRESULT.UNSUPPORTED);
    }
    DatastoreReadResult? mapReadResult;
    if (useIsolate) {
      // read the mapdata in an isolate which is flutter's way to create multithreaded processes
      await startIsolateJob(IsolateMapInitParam(datastore), entryPoint);
      IsolateMapReplyParams params =
          await sendToIsolate(IsolateMapRequestParam(job.tile, renderContext));
      mapReadResult = params.result;
      renderContext = params.renderContext;
    } else {
      // read the mapdata directly in this thread
      mapDataStore = this.datastore;
      IsolateMapReplyParams params = await _readMapDataInIsolate(
          IsolateMapRequestParam(job.tile, renderContext));
      mapReadResult = params.result;
      renderContext = params.renderContext;
    }
    int diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 100 && showTiming)
      _log.info(
          "mapReadResult took $diff ms for ${mapReadResult?.ways.length} ways and ${mapReadResult?.pointOfInterests.length} pois");
    if (mapReadResult == null) {
      TileBitmap bmp = await createNoDataBitmap(job.tileSize);
      return JobResult(bmp, JOBRESULT.UNSUPPORTED);
    }
    await _processMapReadResult(renderContext, mapReadResult, symbolCache);
    if ((mapReadResult.ways.length) > 100000) {
      _log.warning(
          "Many ways (${mapReadResult.ways.length}) in this readResult, consider shrinking your mapfile.");
    }
    diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 100 && showTiming) {
      _log.info(
          "_processReadMapData took $diff ms for ${mapReadResult.ways.length} ways and ${mapReadResult.pointOfInterests.length} pois");
      // Mappoint leftUpper = renderContext.projection.getLeftUpper(job.tile);
      // mapReadResult.ways.forEach((element1) {
      //   _log.info("  ${element1.latLongs.length} items");
      //   element1.latLongs.forEach((element2) {
      //     element2.forEach((element3) {
      //       _log.info(
      //           "    ${element3} is ${leftUpper.x - renderContext.projection.longitudeToPixelX(element3.longitude)} / ${leftUpper.y - renderContext.projection.latitudeToPixelY(element3.latitude)}");
      //     });
      //   });
      // });
    }
    CanvasRasterer canvasRasterer = CanvasRasterer(job.tileSize.toDouble(),
        job.tileSize.toDouble(), "MapDatastoreRenderer ${job.tile.toString()}");
    canvasRasterer.startCanvasBitmap();
    diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 100 && showTiming) _log.info("startCanvasBitmap took $diff ms");
    int waycount = canvasRasterer.drawWays(renderContext);
    diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 100 && showTiming)
      _log.info(
          "drawWays took $diff ms for ${renderContext.drawingLayers.length} way-layers");

    int labelCount = 0;
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
      labelResult.labelsToDisposeAfterDrawing.forEach((element) {
        element.dispose();
      });
      diff = DateTime.now().millisecondsSinceEpoch - time;
      if (diff > 100 && showTiming) {
        _log.info("drawMapElements took $diff ms for $labelCount labels");
        // labelsToDraw.forEach((element) {
        //   _log.info(
        //       "  $element, ${element.boundaryAbsolute!.intersects(renderContext.projection.boundaryAbsolute(job.tile)) ? "intersects" : "non-intersects"}");
        // });
      }
    } else {
      // store elements for this tile in the label cache
      this.labelStore.storeMapItems(job.tile, renderContext.labels);
      diff = DateTime.now().millisecondsSinceEpoch - time;
      if (diff > 100 && showTiming) _log.info("storeMapItems took $diff ms");
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
    diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 100 && showTiming)
      _log.info(
          "finalizeCanvasBitmap took $diff ms for $waycount ways, $labelCount elements and labels, $actions actions in canvas");
    //_log.info("Executing ${job.toString()} returns ${bitmap.toString()}");
    //_log.info("ways: ${mapReadResult.ways.length}, Areas: ${Area.count}, ShapePaintPolylineContainer: ${ShapePaintPolylineContainer.count}");
    return JobResult(bitmap, JOBRESULT.NORMAL);
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
    Set<MapElementContainer> labelsToDisposeAfterDrawing = {};

    Set<MapElementContainer> labelsForNeighbours = {};

    // we sort the list of labels for this tile and
    // remove those elements that clash in this list already.
    List<MapElementContainer> currentElementsOrdered =
        LayerUtil.collisionFreeOrdered(renderContext.labels);

    // get the overlapping elements for the current tile which were found while rendering the neighbours
    Set<MapElementContainer>? labelsFromNeighbours =
        tileDependencies!.getOverlappingElements(renderContext.job.tile);
    // if a neighbour has already been drawn, the elements drawn that overlap onto the
    // current neighbour should be in the neighbour dependencies, we add them to the labels that
    // need to be drawn onto this neighbour. For the multi-threaded renderer we also need to take
    // those tiles into account that are not yet in the TileCache: this is taken care of by the
    // set of tilesInProgress inside the TileDependencies.
    if (labelsFromNeighbours != null) {
      labelsFromNeighbours.forEach((element) {
        // todo find a way to know if this element can be disposed() afterwards or if it is still available for another tile
        // if (labelsToDisposeAfterDrawing.contains(element)) {
        //   labelsToDisposeAfterDrawing.remove(element);
        labelsForNeighbours.add(element);
        //print("Neightpor from beloved neightpours drawn $element");
        // } else if (labelsForNeighbours.contains(element)) {
        // } else {
        //   labelsToDisposeAfterDrawing.add(element);
        // }
      });
    }

    // at this point we have two lists: one is the list of labels that must be drawn because
    // they already overlap from other tiles [labelsToDraw]. The second one is [renderContext.labels] that contains
    // the elements on this neighbour that do not overlap onto a drawn neighbour.
    // now we go through this list, ordered by priority, to see which can be drawn without clashing.
    List<MapElementContainer> toDraw2 = LayerUtil.removeCollisions(
        currentElementsOrdered,
        List.of(labelsToDisposeAfterDrawing)..addAll(labelsForNeighbours));

    // We need to get the labels from the adjacent tiles if they have already been drawn
    // as those overlapping items must also be drawn on the current neighbour. They must be drawn regardless
    // of priority clashes as a part of them has alread been drawn.
    Set<Tile> neighbours = renderContext.job.tile.getNeighbours();
    // update dependencies, add to the dependencies list all the elements that overlap to the
    // neighbouring tiles, first clearing out the cache for this relation.
    for (MapElementContainer element in toDraw2) {
      List<Tile>? added;
      for (Tile neighbour in neighbours) {
        if (element
            .intersects(renderContext.projection.boundaryAbsolute(neighbour))) {
          bool neighbourAlreadyDrawn =
              tileDependencies!.addOverlappingElement(neighbour, element);
          if (neighbourAlreadyDrawn) {
            // we cannot draw this fully because the neighbour is already drawn, ignore this element
            added?.forEach((tile) {
              tileDependencies!.removeOverlappingElement(tile, element);
            });
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
        element.dispose();
        //print("Neightpor not yet drawn at ${added} $element");
      } else {
        if (added.length > 0) {
          // the label is added to at least one neighbour, do not dispose() it
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
    return "${renderTheme.hashCode}";
  }
}

/////////////////////////////////////////////////////////////////////////////

Datastore? mapDataStore;

/// see https://github.com/flutter/flutter/issues/13937
// Entry point for your Isolate
Future<void> entryPoint(IsolateMapInitParam isolateInitParams) async {
  // Open the ReceivePort to listen for incoming messages
  var receivePort = new ReceivePort();

  mapDataStore = isolateInitParams.datastore;
  //_init(isolateInitParams);

  // Send message to other Isolate and inform it about this receiver
  isolateInitParams.sendPort!.send(receivePort.sendPort);

  // Listen for messages
  await for (IsolateMapRequestParam data in receivePort) {
    try {
      IsolateMapReplyParams? result = await _readMapDataInIsolate(data);
      isolateInitParams.sendPort!.send(result);
    } catch (error, stacktrace) {
      isolateInitParams.sendPort!.send(IsolateMapReplyParams(
          renderContext: data.renderContext,
          error: error,
          stacktrace: stacktrace));
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

class IsolateMapInitParam extends IsolateInitParams {
  final Datastore datastore;

  IsolateMapInitParam(this.datastore);
}

/////////////////////////////////////////////////////////////////////////////

///
/// The parameters needed to execute the reading of the mapdata.
///
class IsolateMapRequestParam extends IsolateRequestParams {
  final Tile tile;

  final RenderContext renderContext;

  const IsolateMapRequestParam(this.tile, this.renderContext);
}

/////////////////////////////////////////////////////////////////////////////

class IsolateMapReplyParams extends IsolateReplyParams {
  final DatastoreReadResult? result;

  final RenderContext renderContext;

  const IsolateMapReplyParams(
      {this.result, required this.renderContext, error, stacktrace})
      : super(error: error, stacktrace: stacktrace);
}

/////////////////////////////////////////////////////////////////////////////

///
/// This is the execution of reading the mapdata. If called directly the execution is done in the main thread. If called
/// via [entryPoint] the execution is done in an isolate.
///
Future<IsolateMapReplyParams> _readMapDataInIsolate(
    IsolateMapRequestParam isolateParam) async {
  DatastoreReadResult? mapReadResult =
      await mapDataStore!.readMapDataSingle(isolateParam.tile);
  return IsolateMapReplyParams(
      result: mapReadResult, renderContext: isolateParam.renderContext);
}

Future<void> _processMapReadResult(final RenderContext renderContext,
    DatastoreReadResult mapReadResult, SymbolCache symbolCache) async {
  for (PointOfInterest pointOfInterest in mapReadResult.pointOfInterests) {
    List<RenderInstruction> renderInstructions =
        _retrieveRenderInstructionsForPoi(renderContext, pointOfInterest);
    for (RenderInstruction element in renderInstructions) {
      await element.renderNode(renderContext, pointOfInterest, symbolCache);
    }
  }

  // never ever call an async method 44000 times. It takes 2 seconds to do so!
//    Future.wait(mapReadResult.ways.map((way) => _renderWay(renderContext, PolylineContainer(way, renderContext.job.tile))));
  for (Way way in mapReadResult.ways) {
    PolylineContainer container =
        PolylineContainer(way, renderContext.job.tile);
    List<RenderInstruction> renderInstructions =
        _retrieveRenderInstructionsForWay(renderContext, container);
    for (RenderInstruction element in renderInstructions) {
      await element.renderWay(renderContext, container, symbolCache);
    }
  }
  if (mapReadResult.isWater) {
    _renderWaterBackground(renderContext);
  }
}

List<RenderInstruction> _retrieveRenderInstructionsForPoi(
    final RenderContext renderContext, PointOfInterest pointOfInterest) {
  renderContext.setDrawingLayers(pointOfInterest.layer);
  List<RenderInstruction> renderInstructions = renderContext.renderTheme
      .matchNode(renderContext.job.tile, pointOfInterest);
  return renderInstructions;
}

List<RenderInstruction> _retrieveRenderInstructionsForWay(
    final RenderContext renderContext, PolylineContainer way) {
  if (way.getCoordinatesAbsolute(renderContext.projection).length == 0)
    return [];
  renderContext.setDrawingLayers(way.getLayer());
  if (way.isClosedWay) {
    List<RenderInstruction> renderInstructions = renderContext.renderTheme
        .matchClosedWay(renderContext.job.tile, way.way);
    return renderInstructions;
  } else {
    List<RenderInstruction> renderInstructions = renderContext.renderTheme
        .matchLinearWay(renderContext.job.tile, way.way);
    return renderInstructions;
  }
}

void _renderWaterBackground(final RenderContext renderContext) {
  // renderContext.setDrawingLayers(0);
  // List<Mappoint> coordinates =
  //     getTilePixelCoordinates(renderContext.job.tileSize);
  // Mappoint tileOrigin =
  //     renderContext.projection.getLeftUpper(renderContext.job.tile);
  // for (int i = 0; i < coordinates.length; i++) {
  //   coordinates[i] = coordinates[i].offset(tileOrigin.x, tileOrigin.y);
  // }
  // Watercontainer way = Watercontainer(
  //     coordinates, renderContext.job.tile, [TAG_NATURAL_WATER]);
  //renderContext.renderTheme.matchClosedWay(databaseRenderer, renderContext, way);
}

/////////////////////////////////////////////////////////////////////////////

class _LabelResult {
  final Set<MapElementContainer> labelsToDisposeAfterDrawing;

  final Set<MapElementContainer> labelsForNeighbours;

  _LabelResult(this.labelsForNeighbours, this.labelsToDisposeAfterDrawing);
}
