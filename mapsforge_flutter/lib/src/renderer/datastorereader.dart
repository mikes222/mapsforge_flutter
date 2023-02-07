import 'dart:isolate';

import '../../core.dart';
import '../../datastore.dart';
import '../../maps.dart';
import '../rendertheme/rendercontext.dart';
import '../utils/isolatemixin.dart';

/// Reads the content of a datastore - e.g. MapFile - either via isolate or direct
/// in the main thread.
class DatastoreReader with IsolateMixin<IsolateMapInitParam> {
  final bool useIsolate;

  DatastoreReader({required this.useIsolate});

  Future<IsolateMapReplyParams> read(
      Datastore datastore, Tile tile, PixelProjection projection) async {
    if (useIsolate) {
      await startIsolateJob(IsolateMapInitParam(datastore), entryPoint);
      IsolateMapReplyParams params =
          await sendToIsolate(IsolateMapRequestParam(tile, projection));
      return params;
    } else {
      // read the mapdata directly in this thread
      _mapDataStore = datastore;
      await _mapDataStore!.lateOpen();
      IsolateMapReplyParams params =
          await _readMapDataInIsolate(IsolateMapRequestParam(tile, projection));
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

  const IsolateMapRequestParam(this.tile, this.projection);
}

/////////////////////////////////////////////////////////////////////////////

class IsolateMapReplyParams extends IsolateReplyParams {
  final DatastoreReadResult? result;

  const IsolateMapReplyParams({this.result, error, stacktrace})
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
      isolateInitParams.sendPort!
          .send(IsolateMapReplyParams(error: error, stacktrace: stacktrace));
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
    return const IsolateMapReplyParams(result: null);
  }
  DatastoreReadResult? mapReadResult =
      await _mapDataStore!.readMapDataSingle(isolateParam.tile);
  return IsolateMapReplyParams(result: mapReadResult);
}
