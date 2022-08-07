import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/datastore/datastore.dart';
import 'package:mapsforge_flutter/src/datastore/datastorereadresult.dart';
import 'package:mapsforge_flutter/src/datastore/pointofinterest.dart';
import 'package:mapsforge_flutter/src/datastore/way.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/display.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/maptextpaint.dart';
import 'package:mapsforge_flutter/src/graphics/position.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttercanvas.dart';
import 'package:mapsforge_flutter/src/layer/job/job.dart';
import 'package:mapsforge_flutter/src/layer/job/jobresult.dart';
import 'package:mapsforge_flutter/src/mapelements/mapelementcontainer.dart';
import 'package:mapsforge_flutter/src/mapelements/pointtextcontainer.dart';
import 'package:mapsforge_flutter/src/mapelements/symbolcontainer.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';
import 'package:mapsforge_flutter/src/model/tag.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/renderer/polylinecontainer.dart';
import 'package:mapsforge_flutter/src/renderer/shapepaintcirclecontainer.dart';
import 'package:mapsforge_flutter/src/renderer/shapepaintpolylinecontainer.dart';
import 'package:mapsforge_flutter/src/renderer/tiledependencies.dart';
import 'package:mapsforge_flutter/src/renderer/watercontainer.dart';
import 'package:mapsforge_flutter/src/renderer/waydecorator.dart';
import 'package:mapsforge_flutter/src/rendertheme/rendercallback.dart';
import 'package:mapsforge_flutter/src/rendertheme/rendercontext.dart';
import 'package:mapsforge_flutter/src/rendertheme/renderinstruction/renderinstruction.dart';
import 'package:mapsforge_flutter/src/utils/isolatemixin.dart';
import 'package:mapsforge_flutter/src/utils/layerutil.dart';
import 'package:rxdart/rxdart.dart';

import 'canvasrasterer.dart';
import 'circlecontainer.dart';

///
/// This renderer renders the bitmap for the tiles by using the given [Datastore].
///
class MapDataStoreRenderer extends JobRenderer
    with IsolateMixin<IsolateMapInitParam>
    implements RenderCallback {
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
    RenderContext renderContext = RenderContext(job, renderTheme, symbolCache);
    if (!this.datastore.supportsTile(job.tile, renderContext.projection)) {
      // return if we do not have data for the requested tile in the datastore
      TileBitmap bmp = await createNoDataBitmap(job.tileSize);
      return JobResult(bmp, JOBRESULT.UNSUPPORTED);
    }
    DatastoreReadResult? mapReadResult;
    if (useIsolate) {
      if (showTiming)
        _log.info("Before starting the isolate to read map data from file");
      // read the mapdata in an isolate which is flutter's way to create multithreaded processes
      await startIsolateJob(IsolateMapInitParam(datastore), entryPoint);
      IsolateMapReplyParams params =
          await sendToIsolate(IsolateMapRequestParam(job.tile));
      mapReadResult = params.result;
    } else {
      //if (showTiming) _log.info("Before reading map data from file");
      // read the mapdata directly in this thread
      mapDataStore = this.datastore;
      mapReadResult =
          await readMapDataInIsolate(IsolateMapRequestParam(job.tile));
    }
    int diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 100 && showTiming)
      _log.info(
          "mapReadResult took $diff ms for ${mapReadResult?.ways.length} ways and ${mapReadResult?.pointOfInterests.length} pois");
    if (mapReadResult == null) {
      TileBitmap bmp = await createNoDataBitmap(job.tileSize);
      return JobResult(bmp, JOBRESULT.UNSUPPORTED);
    }
    if ((mapReadResult.ways.length) > 100000) {
      _log.warning(
          "Many ways (${mapReadResult.ways.length}) in this readResult, consider shrinking your mapfile.");
    }
    await _processReadMapData(renderContext, mapReadResult);
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
          "drawWays took $diff ms for ${renderContext.layerWays.length} way-layers");

    int labels = 0;
    if (this.renderLabels) {
      Set<MapElementContainer> labelsToDraw =
          await _processLabels(renderContext);
      labels = labelsToDraw.length;
      //_log.info("Labels to draw: $labelsToDraw");
      // now draw the ways and the labels
      canvasRasterer.drawMapElements(
          labelsToDraw, renderContext.projection, job.tile);
      diff = DateTime.now().millisecondsSinceEpoch - time;
      if (diff > 100 && showTiming) {
        _log.info(
            "drawMapElements took $diff ms for ${labelsToDraw.length} labels");
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
    renderContext.dispose();
    TileBitmap? bitmap =
        (await canvasRasterer.finalizeCanvasBitmap() as TileBitmap?);
    int actions = (canvasRasterer.canvas as FlutterCanvas).actions;
    canvasRasterer.destroy();
    diff = DateTime.now().millisecondsSinceEpoch - time;
    if (diff > 100 && showTiming)
      _log.info(
          "finalizeCanvasBitmap took $diff ms for $waycount ways, $labels elements and labels, $actions actions in canvas");
    //_log.info("Executing ${job.toString()} returns ${bitmap.toString()}");
    //_log.info("ways: ${mapReadResult.ways.length}, Areas: ${Area.count}, ShapePaintPolylineContainer: ${ShapePaintPolylineContainer.count}");
    return JobResult(bitmap, JOBRESULT.NORMAL);
  }

  Future<void> _processReadMapData(final RenderContext renderContext,
      DatastoreReadResult mapReadResult) async {
    for (PointOfInterest pointOfInterest in mapReadResult.pointOfInterests) {
      List<RenderInstruction> renderInstructions =
          _retrieveRenderInstructionsForPoi(renderContext, pointOfInterest);
      for (RenderInstruction element in renderInstructions) {
        if (renderContext.renderTheme.initPendings.contains(element)) {
          await element.initResources(renderContext.symbolCache);
          renderContext.renderTheme.initPendings.remove(element);
        }
      }
      renderInstructions.forEach((element) {
        element.renderNode(this, renderContext, pointOfInterest);
      });
    }

    // never ever call an async method 44000 times. It takes 2 seconds to do so!
//    Future.wait(mapReadResult.ways.map((way) => _renderWay(renderContext, PolylineContainer(way, renderContext.job.tile))));
    for (Way way in mapReadResult.ways) {
      PolylineContainer container =
          PolylineContainer(way, renderContext.job.tile);
      List<RenderInstruction> renderInstructions =
          _retrieveRenderInstructionsForWay(renderContext, container);
      if (renderContext.renderTheme.initPendings.isNotEmpty)
        for (RenderInstruction renderInstruction in renderInstructions) {
          if (renderContext.renderTheme.initPendings
              .contains(renderInstruction)) {
            await renderInstruction.initResources(renderContext.symbolCache);
            renderContext.renderTheme.initPendings.remove(renderInstruction);
          }
          //print("render way $renderInstruction for $way");
          //renderInstruction.renderWay(renderCallback, renderContext, way);
        }
      renderInstructions.forEach((element) {
        element.renderWay(this, renderContext, container);
      });
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
      // renderInstructions.forEach((element) {
      //   element.renderWay(this, renderContext, way);
      // });
    } else {
      List<RenderInstruction> renderInstructions = renderContext.renderTheme
          .matchLinearWay(renderContext.job.tile, way.way);
      return renderInstructions;
      // renderInstructions.forEach((element) {
      //   element.renderWay(this, renderContext, way);
      // });
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

  static List<Mappoint> getTilePixelCoordinates(int tileSize) {
    List<Mappoint> result = [];
    result.add(const Mappoint(0, 0));
    result.add(Mappoint(tileSize.toDouble(), 0));
    result.add(Mappoint(tileSize.toDouble(), tileSize.toDouble()));
    result.add(Mappoint(0, tileSize.toDouble()));
    result.add(result[0]);
    return result;
  }

  @override
  void renderArea(RenderContext renderContext, MapPaint? fill, MapPaint? stroke,
      int level, PolylineContainer way) {
    if ((fill == null || fill.isTransparent()) &&
        (stroke == null || stroke.isTransparent())) return;
    renderContext.addToCurrentDrawingLayer(
        level, ShapePaintPolylineContainer(way, fill, stroke, 0));
  }

  @override
  void renderAreaCaption(
      RenderContext renderContext,
      Display display,
      int priority,
      String caption,
      double horizontalOffset,
      double verticalOffset,
      MapPaint fill,
      MapPaint stroke,
      MapTextPaint mapTextPaint,
      Position position,
      int maxTextWidth,
      PolylineContainer way) {
    if (renderLabels) {
      Mappoint centerPoint = way
          .getCenterAbsolute(renderContext.projection)
          .offset(horizontalOffset, verticalOffset);
      //_log.info("centerPoint is ${centerPoint.toString()}, position is ${position.toString()} for $caption");
      PointTextContainer label = GraphicFactory().createPointTextContainer(
          centerPoint,
          display,
          priority,
          caption,
          fill,
          stroke,
          position,
          maxTextWidth,
          mapTextPaint);
      renderContext.labels.add(label);
    }
  }

  @override
  void renderAreaSymbol(
      RenderContext renderContext,
      Display display,
      int priority,
      Bitmap symbol,
      PolylineContainer way,
      MapPaint? symbolPaint) {
    if (renderLabels && !symbolPaint!.isTransparent()) {
      Mappoint centerPosition = way.getCenterAbsolute(renderContext.projection);
      renderContext.labels.add(new SymbolContainer(
          centerPosition, display, priority, symbol,
          paint: symbolPaint));
    }
  }

  @override
  void renderPointOfInterestCaption(
      RenderContext renderContext,
      Display display,
      int priority,
      String caption,
      double horizontalOffset,
      double verticalOffset,
      MapPaint fill,
      MapPaint stroke,
      MapTextPaint mapTextPaint,
      Position position,
      int maxTextWidth,
      PointOfInterest poi) {
    if (renderLabels) {
      Mappoint poiPosition =
          renderContext.projection.latLonToPixel(poi.position);
      //_log.info("poiCaption $caption at $poiPosition, postion $position, offset: $horizontalOffset, $verticalOffset ");
      renderContext.labels.add(GraphicFactory().createPointTextContainer(
          poiPosition.offset(horizontalOffset, verticalOffset),
          display,
          priority,
          caption,
          fill,
          stroke,
          position,
          maxTextWidth,
          mapTextPaint));
    }
  }

  @override
  void renderPointOfInterestCircle(RenderContext renderContext, double radius,
      MapPaint? fill, MapPaint? stroke, int level, PointOfInterest poi) {
    // ShapePaintContainers does not shift the position relative to the tile by themself. In case of ways this is done in the [PolylineContainer], but
    // in case of cirles this is not done at all so do it here for now
    if ((fill == null || fill.isTransparent()) &&
        (stroke == null || stroke.isTransparent())) return;
    Mappoint poiPosition = renderContext.projection
        .pixelRelativeToTile(poi.position, renderContext.job.tile);
    //_log.info("Adding circle $poiPosition with $radius");
    renderContext.addToCurrentDrawingLayer(
        level,
        ShapePaintCircleContainer(
            new CircleContainer(poiPosition, radius), fill, stroke, 0));
  }

  @override
  void renderPointOfInterestSymbol(RenderContext renderContext, Display display,
      int priority, Bitmap symbol, PointOfInterest poi, MapPaint? symbolPaint) {
    if (renderLabels && !symbolPaint!.isTransparent()) {
      Mappoint poiPosition =
          renderContext.projection.latLonToPixel(poi.position);
      renderContext.labels.add(new SymbolContainer(
          poiPosition, display, priority, symbol,
          paint: symbolPaint, alignCenter: true));
    }
  }

  @override
  void renderWay(RenderContext renderContext, MapPaint stroke, double dy,
      int level, PolylineContainer way) {
    if (!stroke.isTransparent()) {
      renderContext.addToCurrentDrawingLayer(
          level, ShapePaintPolylineContainer(way, null, stroke, dy));
    }
  }

  @override
  void renderWaySymbol(
      RenderContext renderContext,
      Display display,
      int priority,
      Bitmap symbol,
      double dy,
      bool alignCenter,
      bool repeat,
      double? repeatGap,
      double? repeatStart,
      bool? rotate,
      PolylineContainer way,
      MapPaint? symbolPaint) {
    if (renderLabels && !symbolPaint!.isTransparent()) {
      WayDecorator.renderSymbol(
          symbol,
          display,
          priority,
          dy,
          alignCenter,
          repeat,
          repeatGap!.toInt(),
          repeatStart!.toInt(),
          rotate,
          way.getCoordinatesAbsolute(renderContext.projection),
          renderContext.labels,
          symbolPaint);
    }
  }

  @override
  void renderWayText(
      RenderContext renderContext,
      Display display,
      int priority,
      String text,
      double dy,
      MapPaint fill,
      MapPaint stroke,
      MapTextPaint textPaint,
      bool? repeat,
      double? repeatGap,
      double? repeatStart,
      bool? rotate,
      PolylineContainer way) {
    if (renderLabels) {
      WayDecorator.renderText(
          way.getUpperLeft(),
          text,
          display,
          priority,
          dy,
          fill,
          stroke,
          textPaint,
          repeat,
          repeatGap!,
          repeatStart!,
          rotate,
          way.getCoordinatesAbsolute(renderContext.projection),
          renderContext.labels);
    }
  }

  Future<Set<MapElementContainer>> _processLabels(
      RenderContext renderContext) async {
    //return renderContext.labels.toSet();
    // if we are drawing the labels per neighbour, we need to establish which neighbour-overlapping
    // elements need to be drawn.
    Set<MapElementContainer> labelsToDraw = new Set();

    // first we need to get the labels from the adjacent tiles if they have already been drawn
    // as those overlapping items must also be drawn on the current neighbour. They must be drawn regardless
    // of priority clashes as a part of them has alread been drawn.
    Set<Tile> neighbours = renderContext.job.tile.getNeighbours();
    //Set<MapElementContainer> undrawableElements = new Set();
    bool fullybuilt = true;
    neighbours.forEach((Tile neighbour) {
      // get the overlapping elements for the current tile which were found while rendering the [neighbour]
      Set<MapElementContainer>? labels = tileDependencies!
          .getOverlappingElements(renderContext.job.tile, neighbour);
      // if a neighbour has already been drawn, the elements drawn that overlap onto the
      // current neighbour should be in the neighbour dependencies, we add them to the labels that
      // need to be drawn onto this neighbour. For the multi-threaded renderer we also need to take
      // those tiles into account that are not yet in the TileCache: this is taken care of by the
      // set of tilesInProgress inside the TileDependencies.
      if (labels != null) {
        labelsToDraw.addAll(labels);

        // but we need to remove the labels for this neighbour that overlap onto a neighbour that has been drawn
        // for (MapElementContainer current in renderContext.labels) {
        //   if (current.intersects(renderContext.projection.boundaryAbsolute(neighbour))) {
        //     undrawableElements.add(current);
        //   }
        // }
        // since we already have the data from that neighbour, we do not need to get the data for
        // it, so remove it from the neighbours list.
        //neighbours.remove(neighbour);
      } else {
        // the neighbour was not built up to now, this means we do not know whether we have to draw some labels
        fullybuilt = false;
      }
      //toRemove.add(neighbour);
    });
    //_log.info("undrawable: $undrawableElements");
    //_log.info("toRemove: $toRemove");
    //neighbours.removeWhere((tile) => toRemove.contains(tile));
    // now we remove the elements that overlap onto a drawn neighbour from the list of labels
    // for this neighbour
    //renderContext.labels.removeWhere((toTest) => undrawableElements.contains(toTest));

    // at this point we have two lists: one is the list of labels that must be drawn because
    // they already overlap from other tiles. The second one is currentLabels that contains
    // the elements on this neighbour that do not overlap onto a drawn neighbour. Now we sort this list and
    // remove those elements that clash in this list already.
    List<MapElementContainer> currentElementsOrdered =
        LayerUtil.collisionFreeOrdered(renderContext.labels);
    // now we go through this list, ordered by priority, to see which can be drawn without clashing.
    List<MapElementContainer> toDraw2 = [];
    currentElementsOrdered.forEach((MapElementContainer current) {
      bool removed = false;
      for (MapElementContainer label in labelsToDraw) {
        if (label.clashesWith(current)) {
          removed = true;
          break;
        }
      }
      if (!removed) toDraw2.add(current);
    });

    labelsToDraw.addAll(toDraw2);

    // update dependencies, add to the dependencies list all the elements that overlap to the
    // neighbouring tiles, first clearing out the cache for this relation.
    for (Tile neighbour in neighbours) {
      for (MapElementContainer element in toDraw2) {
        if (element
            .intersects(renderContext.projection.boundaryAbsolute(neighbour))) {
          tileDependencies!.addOverlappingElement(
              renderContext.job.tile, neighbour, element);
        }
      }
    }
    return labelsToDraw;
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
      DatastoreReadResult? result = await readMapDataInIsolate(data);
      isolateInitParams.sendPort!.send(IsolateMapReplyParams(result: result));
    } catch (error, stacktrace) {
      isolateInitParams.sendPort!
          .send(IsolateMapReplyParams(error: error, stacktrace: stacktrace));
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

  const IsolateMapRequestParam(this.tile);
}

/////////////////////////////////////////////////////////////////////////////

class IsolateMapReplyParams extends IsolateReplyParams {
  final DatastoreReadResult? result;

  const IsolateMapReplyParams({this.result, error, stacktrace})
      : super(error: error, stacktrace: stacktrace);
}

/////////////////////////////////////////////////////////////////////////////

///
/// This is the execution of reading the mapdata. If called directly the execution is done in the main thread. If called
/// via [entryPoint] the execution is done in an isolate.
///
Future<DatastoreReadResult?> readMapDataInIsolate(
    IsolateMapRequestParam isolateParam) async {
  DatastoreReadResult? mapReadResult =
      await mapDataStore!.readMapDataSingle(isolateParam.tile);
  return mapReadResult;
}
