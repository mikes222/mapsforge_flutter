import 'dart:isolate';

import '../../core.dart';
import '../../datastore.dart';
import '../../maps.dart';
import '../rendertheme/nodeproperties.dart';
import '../rendertheme/rendercontext.dart';
import '../rendertheme/renderinstruction/renderinstruction.dart';
import '../rendertheme/wayproperties.dart';
import '../utils/isolatemixin.dart';

/// Reads the content of a datastore - e.g. MapFile - either via isolate or direct
/// in the main thread.
class DatastoreReader with IsolateMixin<IsolateMapInitParam> {
  final bool useIsolate;

  DatastoreReader({required this.useIsolate});

  Future<IsolateMapReplyParams> read(Datastore datastore, Tile tile,
      PixelProjection projection, RenderContext renderContext) async {
    if (useIsolate) {
      await startIsolateJob(IsolateMapInitParam(datastore), entryPoint);
      IsolateMapReplyParams params = await sendToIsolate(
          IsolateMapRequestParam(tile, projection, renderContext));
      return params;
    } else {
      // read the mapdata directly in this thread
      _mapDataStore = datastore;
      await _mapDataStore!.lateOpen();
      IsolateMapReplyParams params = await _readMapDataInIsolate(
          IsolateMapRequestParam(tile, projection, renderContext));
      return params;
    }
  }

  Future<IsolateMapReplyParams> readLabels(Datastore datastore, Tile tile,
      PixelProjection projection, RenderContext renderContext) async {
    if (useIsolate) {
      await startIsolateJob(IsolateMapInitParam(datastore), entryPoint);
      IsolateMapReplyParams params = await sendToIsolate(
          IsolateMapRequestParam(tile, projection, renderContext));
      return params;
    } else {
      // read the mapdata directly in this thread
      _mapDataStore = datastore;
      await _mapDataStore!.lateOpen();
      IsolateMapReplyParams params = await _readLabelsInIsolate(
          IsolateMapRequestParam(tile, projection, renderContext));
      return params;
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

  final PixelProjection projection;

  final RenderContext renderContext;

  const IsolateMapRequestParam(this.tile, this.projection, this.renderContext);
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

Datastore? _mapDataStore;

/// see https://github.com/flutter/flutter/issues/13937
// Entry point for your Isolate
Future<void> entryPoint(IsolateMapInitParam isolateInitParams) async {
  // Open the ReceivePort to listen for incoming messages
  var receivePort = ReceivePort();

  _mapDataStore = isolateInitParams.datastore;
  await _mapDataStore!.lateOpen();

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

///
/// This is the execution of reading the mapdata. If called directly the execution is done in the main thread. If called
/// via [entryPoint] the execution is done in an isolate.
///
Future<IsolateMapReplyParams> _readMapDataInIsolate(
    IsolateMapRequestParam isolateParam) async {
  if (!_mapDataStore!
      .supportsTile(isolateParam.tile, isolateParam.projection)) {
    return IsolateMapReplyParams(
        result: null, renderContext: isolateParam.renderContext);
  }
  DatastoreReadResult? mapReadResult =
      await _mapDataStore!.readMapDataSingle(isolateParam.tile);
  //print("mapReadResult $mapReadResult for ${isolateParam.tile}");
  if (mapReadResult != null)
    _processMapReadResult(isolateParam.renderContext, mapReadResult);
  return IsolateMapReplyParams(
      result: mapReadResult, renderContext: isolateParam.renderContext);
}

Future<IsolateMapReplyParams> _readLabelsInIsolate(
    IsolateMapRequestParam isolateParam) async {
  if (!_mapDataStore!
      .supportsTile(isolateParam.tile, isolateParam.projection)) {
    return IsolateMapReplyParams(
        result: null, renderContext: isolateParam.renderContext);
  }
  DatastoreReadResult? mapReadResult =
      await _mapDataStore!.readPoiDataSingle(isolateParam.tile);
  //print("mapReadResult $mapReadResult for ${isolateParam.tile}");
  if (mapReadResult != null)
    _processMapReadResult(isolateParam.renderContext, mapReadResult);
  return IsolateMapReplyParams(
      result: mapReadResult, renderContext: isolateParam.renderContext);
}

/// Creates rendering instructions based on the given ways and nodes
void _processMapReadResult(
    final RenderContext renderContext, DatastoreReadResult mapReadResult) {
  for (PointOfInterest pointOfInterest in mapReadResult.pointOfInterests) {
    NodeProperties nodeProperties = NodeProperties(pointOfInterest);
    List<RenderInstruction> renderInstructions =
        _retrieveRenderInstructionsForPoi(renderContext, nodeProperties);
    for (RenderInstruction element in renderInstructions) {
      element.renderNode(renderContext, nodeProperties);
    }
  }

  // never ever call an async method 44000 times. It takes 2 seconds to do so!
//    Future.wait(mapReadResult.ways.map((way) => _renderWay(renderContext, PolylineContainer(way, renderContext.job.tile))));
  for (Way way in mapReadResult.ways) {
    WayProperties wayProperties = WayProperties(way);
    List<RenderInstruction> renderInstructions =
        _retrieveRenderInstructionsForWay(renderContext, wayProperties);
    for (RenderInstruction element in renderInstructions) {
      element.renderWay(renderContext, wayProperties);
    }
  }
  if (mapReadResult.isWater) {
    _renderWaterBackground(renderContext);
  }
}

List<RenderInstruction> _retrieveRenderInstructionsForPoi(
    final RenderContext renderContext, NodeProperties nodeProperties) {
  renderContext.setDrawingLayers(nodeProperties.layer);
  List<RenderInstruction> renderInstructions = renderContext.renderTheme
      .matchNode(renderContext.job.tile, nodeProperties);
  return renderInstructions;
}

List<RenderInstruction> _retrieveRenderInstructionsForWay(
    final RenderContext renderContext, WayProperties wayProperties) {
  if (wayProperties.getCoordinatesAbsolute(renderContext.projection).length ==
      0) return [];
  renderContext.setDrawingLayers(wayProperties.getLayer());
  if (wayProperties.isClosedWay) {
    List<RenderInstruction> renderInstructions = renderContext.renderTheme
        .matchClosedWay(renderContext.job.tile, wayProperties.way);
    return renderInstructions;
  } else {
    List<RenderInstruction> renderInstructions = renderContext.renderTheme
        .matchLinearWay(renderContext.job.tile, wayProperties.way);
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
