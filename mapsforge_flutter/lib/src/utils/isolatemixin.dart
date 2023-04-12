import 'dart:async';
import 'dart:isolate';

import 'package:queue/queue.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

typedef Future<void> EntryPoint<T extends IsolateInitParams>(T initParams);

class IsolateMixin<T extends IsolateInitParams> {
  final _log = Logger('IsolateMixin');

  SendPort? _sendPort;

  Isolate? _isolate;

  Queue _queue = Queue(timeout: const Duration(milliseconds: 10000));

  final PublishSubject<IsolateReplyParams> _subject =
      PublishSubject<IsolateReplyParams>();

  // void reassignQueue(Queue executionQueue) {
  //   _queue.dispose();
  //   _queue = executionQueue;
  // }

  @mustCallSuper
  void dispose() {
    // clear the queue so that the next job will be the stopIsolate
    _queue.dispose();
    if (_isolate != null) {
      stopIsolateJob();
    }
  }

  Future<bool> isOpen() async {
    return await _queue.add(() async {
      return _sendPort != null;
    });
  }

  Future<T> sendToIsolate<T extends IsolateReplyParams>(
      IsolateRequestParams isolateRequestParams) async {
    try {
      return await _queue.add(() async {
        assert(_sendPort != null);
        _sendPort!.send(isolateRequestParams);
        var res = await _subject.first;
        //_log.info("Received ${res.runtimeType} for $isolateRequestParams");
        T result = res as T;
//      if (result.error != null) {
        // _log.warning(
        //     "Error ${result.error} while sending $isolateRequestParams",
        //     result.stacktrace);
//      }
        return result;
      });
    } on TimeoutException catch (error, stacktrace) {
      throw TimeoutException("Timeout while sending $isolateRequestParams");
    }
  }

  ///
  /// Isolates currently not suitable for our purpose. Most UI canvas calls are not accessible from isolates
  /// so we cannot produce the bitmap.
  @protected
  Future<void> startIsolateJob(
      T isolateInitParams, EntryPoint<T> entryPoint) async {
    try {
      return await _queue.add(() async {
//        logNow("start sendport=$_sendPort");
        if (_sendPort != null) return;
        int _time = DateTime.now().millisecondsSinceEpoch;
        ReceivePort receivePort = ReceivePort();
        isolateInitParams.sendPort = receivePort.sendPort;
        _isolate = await Isolate.spawn<T>(entryPoint, isolateInitParams);
        // let the listener run in background
        Completer<SendPort> completer = Completer<SendPort>();
//        logNow("start sendport=$_sendPort vor listen");
        unawaited(_listenToIsolate(receivePort, completer));
//        logNow("start sendport=$_sendPort nach listen");
        _sendPort = await completer.future;
//        logNow("start sendport=$_sendPort nach setSendPort");
        _log.info(
            "Starting isolate mixin for ${this.runtimeType} took ${DateTime.now().millisecondsSinceEpoch - _time} ms");
      });
    } on TimeoutException catch (error, stacktrace) {
      throw TimeoutException(
          "Timeout while starting isolate $isolateInitParams");
    }
  }

  Future<void> _listenToIsolate(
      ReceivePort receivePort, Completer completer) async {
    await for (var data in receivePort) {
      //tileCache.addTileBitmap(job.tile, tileBitmap);
      //print("received from isolate: ${data.toString()}");
      if (data is SendPort) {
        // Receive the SendPort from the Isolate
        completer.complete(data);
      } else if (data is IsolateReplyParams) {
        IsolateReplyParams result = data;
        _subject.add(result);
      } else if (data == null) {
        _subject.add(const IsolateReplyParams(
            error: "data is null in _listenToIsolate()"));
      }
    }
  }

  void stopIsolateJob() {
    //_receivePort?.close();
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
  }
}

/////////////////////////////////////////////////////////////////////////////

class IsolateInitParams {
  SendPort? sendPort;

  IsolateInitParams();
}

/////////////////////////////////////////////////////////////////////////////

class IsolateRequestParams {
  const IsolateRequestParams();
}

/////////////////////////////////////////////////////////////////////////////

class IsolateReplyParams {
  final dynamic error;

  final dynamic stacktrace;

  const IsolateReplyParams({this.error, this.stacktrace});

  @override
  String toString() {
    return 'IsolateReplyParams{error: $error, stacktrace: $stacktrace}';
  }
}

/////////////////////////////////////////////////////////////////////////////

/*
Future<void> entryPoint(IsolateInitParams isolateInitParams) async {
  // Open the ReceivePort to listen for incoming messages
  var receivePort = new ReceivePort();

  //_init(isolateInitParams);

  // Send message to other Isolate and inform it about this receiver
  isolateInitParams.sendPort!.send(receivePort.sendPort);

  // Listen for messages
  await for (IsolateFileRequestParams data in receivePort) {
    try {
      Image image = await perform(data.filename, data.png, data.tileSize);
      isolateInitParams.sendPort!.send(IsolateFileReplyParams(image: image));
    } catch (error, stacktrace) {
      isolateInitParams.sendPort!
          .send(IsolateFileReplyParams(error: error, stacktrace: stacktrace));
    }
  }
}
*/
