import 'dart:async';

/// A web-compatible stub for the FlutterIsolateInstance.
///
/// This implementation provides the same API as the original but throws
/// [UnsupportedError] for any operation that attempts to use isolates,
/// as they are not available on the web platform.
typedef EntryPoint<T> = Future<void> Function(IsolateInitInstanceParams<T> isolateInitInstanceParam);
typedef RequestCallback<U, V> = Future<V> Function(U object);

class FlutterIsolateInstance {
  FlutterIsolateInstance();

  void dispose() {
    // No-op on web
  }

  Future<void> spawn<T>(EntryPoint<T> entryPoint, T initObject) async {
    throw UnsupportedError('Isolates are not supported on the web platform.');
  }

  Future<V> compute<U, V>(U request) {
    throw UnsupportedError('Isolates are not supported on the web platform.');
  }

  @pragma('vm:entry-point')
  static Future<void> isolateInit<U, V>(
      IsolateInitInstanceParams isolateInitInstanceParam,
      RequestCallback<U, V> requestCallback) async {
    throw UnsupportedError('Isolates are not supported on the web platform.');
  }
}

class IsolateInitInstanceParams<T> {
  final dynamic sendPort; // Use dynamic to avoid SendPort from dart:isolate
  final T? initObject;

  IsolateInitInstanceParams(this.sendPort, this.initObject);
}
