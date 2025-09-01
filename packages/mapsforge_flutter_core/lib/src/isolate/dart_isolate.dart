import 'dart:async';
import 'dart:isolate';

/// always annotate your entry point with
/// ``@pragma('vm:entry-point')``
typedef EntryPoint<T> = Future<void> Function(IsolateInitInstanceParams<T> isolateInitInstanceParam);

/// always annotate your entry point with
/// ``@pragma('vm:entry-point')``
typedef RequestCallback<U, V> = Future<V> Function(U object);

//////////////////////////////////////////////////////////////////////////////

/// One instance for an isolate. Easiest approach: Implement your class without isolate.
///
/// class MyClass {
///   void perform(int param) {
///       print("Implementation");
///   }
/// }
///
/// If this works create a new class.
///
/// @pragma('vm:entry-point')
/// class IsolateMyClass {
///
///   final FlutterIsolateInstance _isolateInstance = FlutterIsolateInstance();
///
///   static MyClass? _myClass;
///
///   void perform(int param) {
///       return await _isolateInstance.compute(param);
///   }
///
///   static Future<IsolateWorkingClass> instantiate(String instanceparam) async {
///     IsolateWorkingClass isolateWorkingClass = IsolateWorkingClass._();
///     await isolateWorkingClass._isolateInstance.spawn(entryPoint, instanceparam);
///      return isolateWorkingClass;
///   }
///
//   @pragma('vm:entry-point')
//   static Future<void> entryPoint(IsolateInitInstanceParams<String> key) async {
//     _workingClass = WorkingClass(key.initObject!);
//     await FlutterIsolateInstance.isolateInit(key, _entryPointStatic);
//   }
//
//   @pragma('vm:entry-point')
//   static Future<String> _entryPointStatic(int key) async {
//     return _workingClass!.perform(key);
//   }
/// }
///
/// It is also possible to create MyClass with parameters beforehand and calling the perform method multiple times for the same isolate - even concurrently.
///
class FlutterIsolateInstance {
  SendPort? _sendPort;

  Isolate? _isolate;

  // complete() will be called if the isolate is ready to receive commands.
  final Completer _isolateCompleter = Completer();

  final Map<int, _FlutterProcess> _flutterProcesses = {};

  FlutterIsolateInstance();

  void dispose() {
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
  }

  /// Starts a new isolate. Optionally handle parameters to the isolate for initialization. This should be done if the parameters are the same for all future
  /// calls to the isolate and especially if the parameters are huge so that you do not need to send them for each call to the isolate.
  Future<void> spawn<T>(EntryPoint<T> entryPoint, T initObject) async {
    ReceivePort receivePort = ReceivePort();
    unawaited(_listenToIsolate(receivePort));
    IsolateInitInstanceParams<T> initParams = IsolateInitInstanceParams<T>(receivePort.sendPort, initObject);
    _isolate = await Isolate.spawn<IsolateInitInstanceParams<T>>(entryPoint, initParams); //, onError: errorRp.sendPort);
    // let the listener run in background of the main isolate
    return _isolateCompleter.future;
  }

  /// Starts a single computation in an isolate. This method runs in the main isolate.
  Future<V> compute<U, V>(U request) {
    assert(_sendPort != null, "wait until start() is done");
    _FlutterProcess<V> flutterProcess = _FlutterProcess();
    _flutterProcesses[flutterProcess._id] = flutterProcess;
    _IsolateRequestInstanceParams params = _IsolateRequestInstanceParams<U>(flutterProcess._id, request);
    _sendPort!.send(params);
    return flutterProcess._completer.future;
  }

  /// The first entry point called in the isolate. It establishes the communication with the main isolate, instantiates the isolate's class if necessary and
  /// waits for computational commands.
  @pragma('vm:entry-point')
  static Future<void> isolateInit<U, V>(IsolateInitInstanceParams isolateInitInstanceParam, RequestCallback<U, V> requestCallback) async {
    // Open the ReceivePort to listen for incoming messages
    var receivePort = ReceivePort();
    unawaited(_listenToMainIsolate(receivePort, isolateInitInstanceParam.sendPort, requestCallback));
    // Send message to other Isolate and inform it about this receiver
    isolateInitInstanceParam.sendPort.send(receivePort.sendPort);
    return;
  }

  /// Listens to the request from the main isolate. This method runs in the isolate.
  static Future<void> _listenToMainIsolate<U, V>(ReceivePort receivePort, SendPort sendPort, RequestCallback<U, V> requestCallback) async {
    await for (var data in receivePort) {
      if (data is _IsolateRequestInstanceParams) {
        // convert to U before starting the unawaited() method to throw stacktrace if necessary
        U param = data.parameter;
        unawaited(_handleRequest(sendPort, requestCallback, param, data.id));
      }
    }
  }

  static Future<void> _handleRequest<U, V>(SendPort sendPort, RequestCallback<U, V> requestCallback, U parameter, int id) async {
    try {
      V result = await requestCallback(parameter);
      _IsolateReplyInstanceParams replyParams = _IsolateReplyInstanceParams(id: id, result: result);
      sendPort.send(replyParams);
    } catch (error, stacktrace) {
      _IsolateErrorInstanceParams errorParams = _IsolateErrorInstanceParams.error(id: id, error: error, stacktrace: stacktrace);
      sendPort.send(errorParams);
    }
  }

  /// listen to the results of an isolate. This method runs in the main isolate.
  Future<void> _listenToIsolate(ReceivePort receivePort) async {
    await for (var data in receivePort) {
      //tileCache.addTileBitmap(job.tile, tileBitmap);
      //print("received from isolate: ${data.toString()}");
      if (data is SendPort) {
        // Receive the SendPort from the Isolate
        _sendPort = data;
        _isolateCompleter.complete();
      } else if (data is _IsolateErrorInstanceParams) {
        _IsolateErrorInstanceParams result = data;
        _FlutterProcess? flutterProcess = _flutterProcesses.remove(result.id);
        if (flutterProcess == null) {
          print("Error: flutterProcess with id ${result.id} not found");
          continue;
        }
        flutterProcess._completer.completeError(result.error, result.stacktrace);
      } else if (data is _IsolateReplyInstanceParams) {
        _IsolateReplyInstanceParams result = data;
        _FlutterProcess? flutterProcess = _flutterProcesses.remove(result.id);
        if (flutterProcess == null) {
          print("Error: flutterProcess with id ${result.id} not found");
          continue;
        }
        flutterProcess._completer.complete(result.result);
      }
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class _FlutterProcess<V> {
  static int _idCounter = 0;

  final int _id = ++_idCounter;

  final Completer<V> _completer = Completer<V>();

  _FlutterProcess();
}

//////////////////////////////////////////////////////////////////////////////

class IsolateInitInstanceParams<T> {
  final SendPort sendPort;

  final T? initObject;

  IsolateInitInstanceParams(this.sendPort, this.initObject);
}

//////////////////////////////////////////////////////////////////////////////

class _IsolateRequestInstanceParams<U> {
  final U parameter;

  final int id;

  _IsolateRequestInstanceParams(this.id, this.parameter);
}

//////////////////////////////////////////////////////////////////////////////

/// Sends the result of the isolate to the main isolate.
class _IsolateReplyInstanceParams<V> {
  final int id;

  final V? result;

  const _IsolateReplyInstanceParams({required this.id, this.result});
}

/////////////////////////////////////////////////////////////////////////////

/// Sends an error to the main isolate.
class _IsolateErrorInstanceParams {
  final int id;

  final dynamic error;

  final dynamic stacktrace;

  const _IsolateErrorInstanceParams.error({required this.id, this.error, this.stacktrace});

  @override
  String toString() {
    return 'IsolateReplyParams{error: $error, stacktrace: $stacktrace}';
  }
}
