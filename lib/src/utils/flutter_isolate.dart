import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

/// always annotate your entry point with
/// ``@pragma('vm:entry-point')``
typedef Future<V> EntryPoint<V, R>(R request);

/// always annotate your entry point with
/// ``@pragma('vm:entry-point')``
typedef Future<Stream<V>> StreamEntryPoint<V, R>(R request);

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
  FlutterIsolateInstancePool({this.maxInstances = 10, this.createInstance, this.instanceParams});

  void dispose() {
    isolateInstances.forEach((action) => action.dispose());
    isolateInstances.clear();
    _subject.close();
  }

  /// Executes a computation in an isolate and returns the result. Creates a new
  /// isolate if none is available or waits until an isolate is available.
  Future<V> compute<V, R>(EntryPoint<V, R> entryPoint, R request) async {
    FlutterIsolateInstance isolateInstance = await _getInstance();
    try {
      Future<V> result = isolateInstance.compute(entryPoint, request);
      return result;
    } finally {
      isolateInstances.add(isolateInstance);
      --_isolateCounter;
      _subject.add(true);
    }
  }

  Future<FlutterIsolateInstance> _getInstance() async {
    while (_isolateCounter >= maxInstances) {
      await _subject.stream.first;
    }
    FlutterIsolateInstance? isolateInstance = isolateInstances.isNotEmpty ? isolateInstances.removeLast() : null;
    if (isolateInstance != null) return isolateInstance;
    return _createInstance();
  }

  Future<FlutterIsolateInstance> _createInstance() async {
    ++_isolateCounter;
    FlutterIsolateInstance isolateInstance = await FlutterIsolateInstance._create(createInstance, instanceParams);
    return isolateInstance;
  }
}

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
///   void perform(int param) {
///       FlutterIsolateInstance.isolateCompute(performStatic, param);
///   }
///
///   @pragma('vm:entry-point')
///   void performStatic(int param) {
///       MyClass instance = MyClass();
///       instance.perform(param);
///   }
/// }
///
/// There is also the possibility to create MyClass with paramters beforehand and calling the perform method multiple times for the same isolate.
///
class FlutterIsolateInstance {
  SendPort? _sendPort;

  Isolate? _isolate;

  // complete() will be called if the isolate is ready to receive commands.
  Completer _isolateCompleter = Completer();

  Map<int, _FlutterProcess> _flutterProcesses = {};

  FlutterIsolateInstance._();

  void dispose() {
    _isolate?.kill();
    _isolate = null;
    _sendPort = null;
  }

  static Future<FlutterIsolateInstance> _create(CreateInstanceFunction? createInstance, Object? instanceParams) async {
    FlutterIsolateInstance instance = FlutterIsolateInstance._();
    await instance.start(createInstance, instanceParams);
    return instance;
  }

  /// Starts a new isolate and handles the instance parameters to the constructor method of the isolate.
  /// Next step is to perform execution with [compute]. This is an alternative to [isolateCompute] and should only be used if the
  /// parameters needed to do the work in the isolate are static for each compute and are big/expensive.
  static Future<FlutterIsolateInstance> createInstance({required CreateInstanceFunction createInstance, required Object instanceParams}) async {
    FlutterIsolateInstance instance = await FlutterIsolateInstance._create(createInstance, instanceParams);
    return instance;
  }

  /// Performs a single computation in an isolate and disposes the isolate afterwards.
  static Future<V> isolateCompute<V, R>(EntryPoint<V, R> entryPoint, R request) async {
    FlutterIsolateInstance instance = await FlutterIsolateInstance._create(null, null);
    V result = await instance.compute(entryPoint, request);
    instance.dispose();
    return result;
  }

  /// Calls a method in an isolate which returns a stream of data.
  static Future<Stream<V>> isolateComputeStream<V, R>(StreamEntryPoint<V, R> entryPoint, R request) async {
    FlutterIsolateInstance instance = await FlutterIsolateInstance._create(null, null);
    Stream<V> result = instance.computeStream(entryPoint, request);
    result.doOnDone(() {
      instance.dispose();
    }).doOnError((error, stacktrace) {
      instance.dispose();
    });
    return result;
  }

  /// The first entry point called in the isolate. It establishes the communication with the main isolate, instantiates the isolate's class if necessary and
  /// waits for computational commands.
  @pragma('vm:entry-point')
  static Future<void> isolateEntryPoint(_IsolateInitInstanceParams isolateInitParams) async {
    // some methods (e.g. getTemporaryDirectory()) does not work without this initialization
    BackgroundIsolateBinaryMessenger.ensureInitialized(isolateInitParams.rootIsolateToken);
    // Open the ReceivePort to listen for incoming messages
    var receivePort = new ReceivePort();
    // Send message to other Isolate and inform it about this receiver
    isolateInitParams.sendPort.send(receivePort.sendPort);

    if (isolateInitParams.createInstanceHandle != null) {
      final createInstanceHandle = CallbackHandle.fromRawHandle(isolateInitParams.createInstanceHandle!);
      final createInstance = PluginUtilities.getCallbackFromHandle(createInstanceHandle);
      Object? instanceParams = isolateInitParams.object;
      createInstance!(instanceParams);
    }

    // Listen for messages from main isolate and returns the results.
    await for (var data in receivePort) {
      if (data is _IsolateRequestInstanceParams) {
        try {
          final entryPointHandle = CallbackHandle.fromRawHandle(data.entryPointHandle);
          final entryPoint = PluginUtilities.getCallbackFromHandle(entryPointHandle);
          entryPoint!(data.parameter).then((result) {
            // return result to main isolate
            isolateInitParams.sendPort.send(_IsolateReplyInstanceParams(id: data.id, result: result));
          });
        } catch (error, stacktrace) {
          // return error to main isolate
          isolateInitParams.sendPort.send(_IsolateErrorInstanceParams.error(id: data.id, error: error, stacktrace: stacktrace));
        }
      } else if (data is _IsolateRequestStreamParams) {
        try {
          final entryPointHandle = CallbackHandle.fromRawHandle(data.entryPointHandle);
          final entryPoint = PluginUtilities.getCallbackFromHandle(entryPointHandle);
          Stream stream = await entryPoint!(data.parameter);
          stream.listen((result) {
            // return result to main isolate
            isolateInitParams.sendPort.send(_IsolateStreamInstanceParams(id: data.id, result: result));
          }, onDone: () {
            isolateInitParams.sendPort.send(_IsolateStreamInstanceParams(id: data.id, result: null, isDone: true));
          });
        } catch (error, stacktrace) {
          // return error to main isolate
          print("Error: ${error.toString()}, ${stacktrace.toString()} ,${error.runtimeType} ,${stacktrace.runtimeType}");
          isolateInitParams.sendPort.send(_IsolateErrorInstanceParams.error(id: data.id, error: error, stacktrace: stacktrace));
        }
      }
    }
    return;
  }

  /// Starts a new isolate. Do not call this directly. Use [isolateCompute] instead. This runs in the main isolate.
  Future<void> start(CreateInstanceFunction? createInstance, Object? instanceParams) async {
    ReceivePort receivePort = ReceivePort();
    int? createInstanceHandle;
    if (createInstance != null) createInstanceHandle = PluginUtilities.getCallbackHandle(createInstance)!.toRawHandle();

    _IsolateInitInstanceParams initParams =
        _IsolateInitInstanceParams(ServicesBinding.rootIsolateToken!, receivePort.sendPort, createInstanceHandle, instanceParams);
    _isolate = await Isolate.spawn<_IsolateInitInstanceParams>(isolateEntryPoint, initParams);
    // let the listener run in background of the main isolate
    unawaited(_listenToIsolate(receivePort));
    return _isolateCompleter.future;
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
        if (flutterProcess is _FlutterStreamProcess) {
          flutterProcess.subject.addError(result.error, result.stacktrace);
          await flutterProcess.dispose();
        } else {
          flutterProcess._completer.completeError(result.error, result.stacktrace);
        }
      } else if (data is _IsolateStreamInstanceParams) {
        _IsolateStreamInstanceParams result = data;
        _FlutterProcess? flutterProcess = _flutterProcesses[result.id];
        if (flutterProcess == null) {
          print("Error: flutterProcess with id ${result.id} not found");
          continue;
        }
        if (flutterProcess is _FlutterStreamProcess) {
          if (result.isDone) {
            await flutterProcess.subject.close();
          } else {
            // send the status or ignore it if we have not started it a statusProcess
            flutterProcess.subject.add(result.result);
          }
        }
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

  /// Starts a single computation in an isolate. Do not call this method
  /// directly. Use [isolateCompute] instead.
  /// This method runs in the main isolate.
  Future<V> compute<V, R>(EntryPoint<V, R> entryPoint, R request) {
    assert(_sendPort != null, "wait until start() is done");
    final entryPointHandle = PluginUtilities.getCallbackHandle(entryPoint)!.toRawHandle();
    _FlutterProcess<V> flutterProcess = _FlutterProcess();
    _flutterProcesses[flutterProcess._id] = flutterProcess;
    _IsolateRequestInstanceParams<R> params = _IsolateRequestInstanceParams(flutterProcess._id, entryPointHandle, request);
    _sendPort!.send(params);
    return flutterProcess._completer.future;
  }

  /// Starts a stream computation in an isolate. Do not call this method directly. Use [isolateComputeStream] instead. This method runs in the main isolate.
  Stream<V> computeStream<V, R>(StreamEntryPoint<V, R> entryPoint, R request) {
    assert(_sendPort != null, "wait until start() is done");
    final entryPointHandle = PluginUtilities.getCallbackHandle(entryPoint)!.toRawHandle();
    _FlutterStreamProcess<V> flutterProcess = _FlutterStreamProcess();
    _flutterProcesses[flutterProcess._id] = flutterProcess;
    _IsolateRequestStreamParams<R> params = _IsolateRequestStreamParams(flutterProcess._id, entryPointHandle, request);

    _sendPort!.send(params);
    return flutterProcess.subject.stream;
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

/// Used if the method to be called returns a stream of data, e.g. Statusmessages. The _completer of the superclass is not used.
class _FlutterStreamProcess<V> extends _FlutterProcess<V> {
  final Subject<V> subject = PublishSubject();

  _FlutterStreamProcess();

  Future<void> dispose() async {
    await subject.close();
  }
}

//////////////////////////////////////////////////////////////////////////////

class _IsolateInitInstanceParams {
  final RootIsolateToken rootIsolateToken;

  final SendPort sendPort;

  final Object? object;

  final int? createInstanceHandle;

  _IsolateInitInstanceParams(this.rootIsolateToken, this.sendPort, this.createInstanceHandle, this.object);
}

//////////////////////////////////////////////////////////////////////////////

class _IsolateRequestInstanceParams<R> {
  final int entryPointHandle;

  final R parameter;

  final int id;

  _IsolateRequestInstanceParams(this.id, this.entryPointHandle, this.parameter);
}

//////////////////////////////////////////////////////////////////////////////

class _IsolateRequestStreamParams<R> {
  final int entryPointHandle;

  final R parameter;

  final int id;

  _IsolateRequestStreamParams(this.id, this.entryPointHandle, this.parameter);
}

/////////////////////////////////////////////////////////////////////////////

/// Sends the result of the isolate to the main isolate.
class _IsolateReplyInstanceParams<V> {
  final int id;

  final V? result;

  const _IsolateReplyInstanceParams({required this.id, this.result});
}

/////////////////////////////////////////////////////////////////////////////

/// Sends the status of the isolate to the main isolate but does NOT end the computation
class _IsolateStreamInstanceParams<V> {
  final int id;

  final V? result;

  final bool isDone;

  const _IsolateStreamInstanceParams({required this.id, this.result, this.isDone = false});
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

//////////////////////////////////////////////////////////////////////////////
