import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:mapsforge_flutter_core/src/buffer/readbuffer.dart';
import 'package:mapsforge_flutter_core/src/buffer/readbuffer_source.dart';
import 'package:mapsforge_flutter_core/src/utils/performance_profiler.dart';

/// Web-compatible implementation for reading chunks of files.
/// Supports both local files (via File API) and remote files (via HTTP Range requests).
class ReadbufferFileWebJs implements ReadbufferSource {
  // static final _log = Logger('ReadbufferFileWeb'); // Commented out as it is unused

  final dynamic _source; // html.File or String (URL)
  int? _length;
  int _position = 0;

  /// Create from a File object (user-selected file)
  ReadbufferFileWebJs.fromFile(html.File file) : _source = file;

  /// Create from a URL (remote file with Range request support)
  ReadbufferFileWebJs.fromUrl(String url) : _source = url;

  @override
  void dispose() {
    // No resources to dispose in web
  }

  @override
  Future<void> freeRessources() async {
    // No resources to free in web
  }

  @override
  Future<Readbuffer> readFromFile(int length) async {
    assert(length > 0);
    var session = PerformanceProfiler().startSession(category: "ReadbufferFile.read");

    final data = await _readBytes(_position, length);
    final result = Readbuffer(data, _position);

    session.complete();
    _position += length;
    return result;
  }

  @override
  Future<void> setPosition(int position) async {
    _position = position;
  }

  @override
  Future<Readbuffer> readFromFileAt(int position, int length) async {
    assert(length > 0);
    assert(position >= 0);

    var session = PerformanceProfiler().startSession(category: "ReadbufferFile.readAt");
    final data = await _readBytes(position, length);
    final result = Readbuffer(data, position);
    session.complete();
    return result;
  }

  @override
  Future<Readbuffer> readFromFileAtMax(int position, int length) async {
    assert(length > 0);
    assert(position >= 0);

    var session = PerformanceProfiler().startSession(category: "ReadbufferFile.readAt");
    final data = await _readBytes(position, length);
    final result = Readbuffer(data, position);
    session.complete();
    return result;
  }

  @override
  Future<int> length() async {
    if (_length != null) return _length!;

    if (_source is html.File) {
      _length = (_source).size;
    } else if (_source is String) {
      _length = await _getRemoteFileSize(_source);
    } else {
      throw UnsupportedError('Unsupported source type: ${_source.runtimeType}');
    }

    assert(_length! >= 0);
    return _length!;
  }

  @override
  int getPosition() => _position;

  @override
  Stream<List<int>> get inputStream async* {
    final fileLength = await length();
    _position = 0;

    while (_position < fileLength) {
      final chunkSize = (fileLength - _position).clamp(0, 10000);
      final readbuffer = await readFromFile(chunkSize);
      yield readbuffer.getBuffer(0, chunkSize);
    }
  }

  @override
  String toString() {
    return 'ReadbufferFileWeb{source: $_source, _length: $_length}';
  }

  /// Read bytes from the source (File or URL)
  Future<Uint8List> _readBytes(int position, int length) async {
    if (_source is html.File) {
      return _readFromFile(_source, position, length);
    } else if (_source is String) {
      return _readFromUrl(_source, position, length);
    } else {
      throw UnsupportedError('Unsupported source type: ${_source.runtimeType}');
    }
  }

  /// Read bytes from a local File using Blob.slice()
  Future<Uint8List> _readFromFile(html.File file, int position, int length) async {
    final blob = file.slice(position, position + length);
    final reader = html.FileReader();

    final completer = Completer<Uint8List>();
    reader.onLoad.listen((_) {
      final arrayBuffer = reader.result as ByteBuffer;
      completer.complete(Uint8List.view(arrayBuffer));
    });
    reader.onError.listen((e) => completer.completeError(e));

    reader.readAsArrayBuffer(blob);
    return completer.future;
  }

  /// Read bytes from a remote URL using HTTP Range requests
  Future<Uint8List> _readFromUrl(String url, int position, int length) async {
    final request = html.HttpRequest();
    request.open('GET', url);
    request.setRequestHeader('Range', 'bytes=$position-${position + length - 1}');
    request.responseType = 'arraybuffer';

    final completer = Completer<Uint8List>();
    request.onLoad.listen((_) {
      if (request.status == 206 || request.status == 200) {
        final arrayBuffer = request.response as ByteBuffer;
        final data = Uint8List.view(arrayBuffer);

        // Handle case where server doesn't support range requests
        if (request.status == 200 && data.length > length) {
          completer.complete(data.sublist(position, position + length));
        } else {
          completer.complete(data);
        }
      } else {
        completer.completeError('HTTP request failed: ${request.status}');
      }
    });
    request.onError.listen((e) => completer.completeError(e));

    request.send();
    return completer.future;
  }

  /// Get the size of a remote file using HEAD request
  Future<int> _getRemoteFileSize(String url) async {
    final request = html.HttpRequest();
    request.open('HEAD', url);

    final completer = Completer<int>();
    request.onLoad.listen((_) {
      final contentLength = request.getResponseHeader('Content-Length');
      if (contentLength != null) {
        completer.complete(int.parse(contentLength));
      } else {
        // Fallback: make a GET request and check the response size
        _getFallbackFileSize(url).then(completer.complete).catchError(completer.completeError);
      }
    });
    request.onError.listen((e) => completer.completeError(e));

    request.send();
    return completer.future;
  }

  /// Fallback method to get file size when HEAD request doesn't provide Content-Length
  Future<int> _getFallbackFileSize(String url) async {
    final request = html.HttpRequest();
    request.open('GET', url);
    request.responseType = 'arraybuffer';

    final completer = Completer<int>();
    request.onLoad.listen((_) {
      final arrayBuffer = request.response as ByteBuffer;
      completer.complete(arrayBuffer.lengthInBytes);
    });
    request.onError.listen((e) => completer.completeError(e));

    request.send();
    return completer.future;
  }
}
