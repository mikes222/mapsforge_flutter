import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/src/buffer/readbuffer.dart';
import 'package:mapsforge_flutter_core/src/buffer/readbuffer_source.dart';
import 'package:mapsforge_flutter_core/src/utils/performance_profiler.dart';

/// A WASM-compatible implementation for reading file chunks from a URL.
/// This uses the `http` package to make range requests, avoiding `dart:html`.
class ReadbufferFileWebWasm implements ReadbufferSource {
  static final _log = Logger('ReadbufferFileWebWasm');

  final String _url;
  int? _length;
  int _position = 0;
  final http.Client _client;

  ReadbufferFileWebWasm.fromUrl(this._url) : _client = http.Client();

  @override
  void dispose() {
    _client.close();
  }

  @override
  void freeRessources() {
    // No-op
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
  Future<int> length() async {
    if (_length != null) return _length!;

    try {
      final response = await _client.head(Uri.parse(_url));
      if (response.statusCode == 200) {
        final contentLength = response.headers['content-length'];
        if (contentLength != null) {
          _length = int.parse(contentLength);
          return _length!;
        }
      }
    } catch (e) {
      _log.warning('HEAD request failed, falling back to GET: $e');
    }

    // Fallback to a GET request if HEAD fails or doesn't provide content-length
    try {
      final response = await _client.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        _length = response.bodyBytes.length;
        return _length!;
      }
    } catch (e) {
      _log.severe('Failed to get file size from URL: $_url', e);
    }

    throw Exception('Could not determine file length for $_url');
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

  Future<Uint8List> _readBytes(int position, int length) async {
    final headers = {'Range': 'bytes=$position-${position + length - 1}'};
    final response = await _client.get(Uri.parse(_url), headers: headers);

    if (response.statusCode == 206) {
      return response.bodyBytes;
    } else if (response.statusCode == 200) {
      // Server doesn't support range requests, handle it gracefully
      return response.bodyBytes.sublist(position, position + length);
    } else {
      throw Exception('HTTP request failed with status: ${response.statusCode}');
    }
  }
}
