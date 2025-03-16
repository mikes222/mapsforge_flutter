import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:rxdart/rxdart.dart';

/// always annotate your entry point with
/// ``@pragma('vm:entry-point')``
typedef Future<V> EntryPoint<V, R>(R request);

/// always annotate your entry point with
/// ``@pragma('vm:entry-point')``
typedef void CreateInstanceFunction(Object object);

//////////////////////////////////////////////////////////////////////////////

class FlutterIsolateInstancePool {
  final int maxInstances;

  int _isolateCounter = 0;

  Subject<bool> _subject = PublishSubject();

  List<FlutterIsolateInstance> isolateInstances = [];

  Object? instanceParams;

  CreateInstanceFunction? createInstance;

  /// Constructor for a pool of isolates.
  /// @param maxInstances The maximum number of isolates that can be created.
  /// @param createInstance The function to create an instance or null
  /// @param instanceParams The parameters to pass to the instance or null
  FlutterIsolateInstancePool(
      {this.maxInstances = 10, this.createInstance, this.instanceParams});

  void dispose() {
    isolateInstances.forEach((action) => action.dispose());
    isolateInstances.clear();
    _subject.close();
  }

  /// Executes a computation in an isolate and returns the result. Creates a new
  /// isolate if none is available or waits until an isolate is available.
  Future<V> compute<V, R>(EntryPoint<V, R> entryPoint, R request) async {
    FlutterIsolateInstance isolateInstance = await _getInstance();
    Future<V> result = isolateInstance.compute(entryPoint, request);
    isolateInstances.add(isolateInstance);
    _subject.add(true);
    return result;
  }

  Future<FlutterIsolateInstance> _getInstance() async {
    while (_isolateCounter > maxInstances) {
      await _subject.stream.first;
    }
    FlutterIsolateInstance? isolateInstance =
        isolateInstances.isNotEmpty ? isolateInstances.removeLast() : null;
    if (isolateInstance != null) return isolateInstance;
    return _createInstance();
  }

  Future<FlutterIsolateInstance> _createInstance() async {
    ++_isolateCounter;
    FlutterIsolateInstance isolateInstance =
        await FlutterIsolateInstance._create(createInstance, instanceParams);
    return isolateInstance;
  }
}

//////////////////////////////////////////////////////////////////////////////

class FlutterIsolateInstance {
  SendPort? _sendPort;

  Isolate? _isolate;

  Completer _isolateCompleter = Completer();

  Map<int, _FlutterProcess> _flutterProcesses = {};

  FlutterIsolateInstance._();

  void dispose() {
    //_receivePort?.close();
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
  }

  static Future<FlutterIsolateInstance> _create(
      CreateInstanceFunction? createInstance, Object? instanceParams) async {
    FlutterIsolateInstance instance = FlutterIsolateInstance._();
    await instance.start(createInstance, instanceParams);
    return instance;
  }

  /// Performs a single computation in an isolate and disposes the isolate afterwards.
  static Future<V> isolateCompute<V, R>(
      EntryPoint<V, R> entryPoint, R request) async {
    FlutterIsolateInstance instance =
        await FlutterIsolateInstance._create(null, null);
    V result = await instance.compute(entryPoint, request);
    instance.dispose();
    return result;
  }

  @pragma('vm:entry-point')
  static Future<void> isolateEntryPoint(
      _IsolateInitInstanceParams isolateInitParams) async {
    // Open the ReceivePort to listen for incoming messages
    var receivePort = new ReceivePort();
    // Send message to other Isolate and inform it about this receiver
    isolateInitParams.sendPort.send(receivePort.sendPort);

    if (isolateInitParams.createInstanceHandle != null) {
      final createInstanceHandle =
          CallbackHandle.fromRawHandle(isolateInitParams.createInstanceHandle!);
      final createInstance =
          PluginUtilities.getCallbackFromHandle(createInstanceHandle);
      Object? instanceParams = isolateInitParams.object;
      createInstance!(instanceParams);
    }

    // Listen for messages
    await for (var data in receivePort) {
      if (data is _IsolateRequestInstanceParams) {
        try {
          final entryPointHandle =
              CallbackHandle.fromRawHandle(data.entryPointHandle);
          final entryPoint =
              PluginUtilities.getCallbackFromHandle(entryPointHandle);
          entryPoint!(data.parameter).then((result) {
            isolateInitParams.sendPort
                .send(_IsolateReplyInstanceParams(id: data.id, result: result));
          });
        } catch (error, stacktrace) {
          isolateInitParams.sendPort.send(_IsolateReplyInstanceParams.error(
              id: data.id, error: error, stacktrace: stacktrace));
        }
      }
    }
    return;
  }

  /// Starts a new isolate. Do not call this directly. Use [isolateCompute] instead.
  Future<void> start(
      CreateInstanceFunction? createInstance, Object? instanceParams) async {
    ReceivePort receivePort = ReceivePort();
    int? createInstanceHandle;
    if (createInstance != null)
      createInstanceHandle =
          PluginUtilities.getCallbackHandle(createInstance)!.toRawHandle();

    _IsolateInitInstanceParams initParams = _IsolateInitInstanceParams(
        receivePort.sendPort, createInstanceHandle, instanceParams);
    _isolate = await Isolate.spawn<_IsolateInitInstanceParams>(
        isolateEntryPoint, initParams);
    // let the listener run in background
    //print("start sendport=$_sendPort vor listen");
    unawaited(_listenToIsolate(receivePort));
    //print("start sendport=$_sendPort nach listen");
    return _isolateCompleter.future;
  }

  Future<void> _listenToIsolate(ReceivePort receivePort) async {
    await for (var data in receivePort) {
      //tileCache.addTileBitmap(job.tile, tileBitmap);
      //print("received from isolate: ${data.toString()}");
      if (data is SendPort) {
        // Receive the SendPort from the Isolate
        _sendPort = data;
        _isolateCompleter.complete();
      } else if (data is _IsolateReplyInstanceParams) {
        _IsolateReplyInstanceParams result = data;
        _FlutterProcess? flutterProcess = _flutterProcesses.remove(result.id);
        if (flutterProcess == null) {
          print("Error: flutterProcess with id ${result.id} not found");
          continue;
        }
        if (result.error != null) {
          flutterProcess._completer
              .completeError(result.error, result.stacktrace);
        }
        flutterProcess._completer.complete(result.result);
      }
    }
  }

  /// Performs a single computation in an isolate. Do not call this method
  /// directly. Use [isolateCompute] instead.
  Future<V> compute<V, R>(EntryPoint<V, R> entryPoint, R request) {
    assert(_sendPort != null, "wait until start() is done");
    final entryPointHandle =
        PluginUtilities.getCallbackHandle(entryPoint)!.toRawHandle();
    _FlutterProcess<V> flutterProcess = _FlutterProcess();
    _flutterProcesses[flutterProcess._id] = flutterProcess;
    _IsolateRequestInstanceParams<R> params = _IsolateRequestInstanceParams(
        flutterProcess._id, entryPointHandle, request);
    _sendPort!.send(params);
    return flutterProcess._completer.future;
  }
}

//////////////////////////////////////////////////////////////////////////////

class _FlutterProcess<V> {
  static int _idCounter = 0;

  int _id = ++_idCounter;

  Completer<V> _completer = Completer<V>();

  _FlutterProcess();
}

//////////////////////////////////////////////////////////////////////////////

class _IsolateInitInstanceParams {
  final SendPort sendPort;

  final Object? object;

  final int? createInstanceHandle;

  _IsolateInitInstanceParams(
      this.sendPort, this.createInstanceHandle, this.object);
}

//////////////////////////////////////////////////////////////////////////////

class _IsolateRequestInstanceParams<R> {
  final int entryPointHandle;

  final R parameter;

  final int id;

  _IsolateRequestInstanceParams(this.id, this.entryPointHandle, this.parameter);
}

/////////////////////////////////////////////////////////////////////////////

class _IsolateReplyInstanceParams<V> {
  final int id;

  final V? result;

  final dynamic error;

  final dynamic stacktrace;

  const _IsolateReplyInstanceParams({required this.id, this.result})
      : error = null,
        stacktrace = null;

  const _IsolateReplyInstanceParams.error(
      {required this.id, this.error, this.stacktrace})
      : result = null;

  @override
  String toString() {
    return 'IsolateReplyParams{error: $error, stacktrace: $stacktrace}';
  }
}

//////////////////////////////////////////////////////////////////////////////
