import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/src/buffer/readbuffer.dart';
import 'package:mapsforge_flutter_core/src/buffer/readbuffer_source.dart';
import 'package:mapsforge_flutter_core/src/utils/performance_profiler.dart';

/// Reads chunks of a file from the disc. Supports reading multiple chunks concurrently (underlying RandomAccessFile forbids this).
class ReadbufferFile implements ReadbufferSource {
  static final _log = new Logger('ReadbufferFile');

  /// ressource for consecutive reads
  _ReadbufferFileResource? _resource;

  /// ressource for a specific position
  final Queue<_ReadbufferFileResource> _resourceAts = Queue();

  /// The filename of the underlying file
  final String filename;

  int? _length;

  int _position = 0;

  ReadbufferFile(this.filename);

  @override
  void dispose() {
    freeRessources();
  }

  @override
  void freeRessources() {
    _resource?.close();
    _resource = null;
    for (var resource in _resourceAts) {
      resource.close();
    }
    _resourceAts.clear();
  }

  /// Reads the given amount of bytes from the file into the read buffer and resets the internal buffer position. If
  /// the capacity of the read buffer is too small, a larger one is created automatically.
  ///
  /// @param length the amount of bytes to read from the file.
  /// @return true if the whole data was read successfully, false otherwise.
  /// @throws IOException if an error occurs while reading the file.
  @override
  Future<Readbuffer> readFromFile(int length) async {
    assert(length > 0);
    var session = PerformanceProfiler().startSession(category: "ReadbufferFile.read");
    _resource ??= _ReadbufferFileResource(filename);
    Uint8List bufferData = await _resource!.read(length);
    Readbuffer result = Readbuffer(bufferData, _position);
    session.complete();
    _position += length;
    return result;
  }

  @override
  Future<void> setPosition(int position) async {
    _resource ??= _ReadbufferFileResource(filename);
    await _resource!.setPosition(position);
    _position = position;
  }

  @override
  Future<Readbuffer> readFromFileAt(int position, int length) async {
    assert(length > 0);
    assert(position >= 0);

    var session = PerformanceProfiler().startSession(category: "ReadbufferFile.readAt");
    _ReadbufferFileResource resourceAt = _resourceAts.isNotEmpty ? _resourceAts.removeFirst() : _ReadbufferFileResource(filename);
    Uint8List bufferData = await resourceAt.readAt(position, length);
    _resourceAts.addLast(resourceAt);
    Readbuffer result = Readbuffer(bufferData, position);
    session.complete();
    return result;
  }

  @override
  Future<int> length() async {
    if (_length != null) return _length!;
    _ReadbufferFileResource resourceAt = _resourceAts.isNotEmpty ? _resourceAts.removeFirst() : _ReadbufferFileResource(filename);
    _length = await resourceAt.length();
    _resourceAts.addLast(resourceAt);
    assert(_length! >= 0);
    //_log.info("length needed ${DateTime.now().millisecondsSinceEpoch - time} ms");
    return _length!;
  }

  @override
  String toString() {
    return 'ReadbufferFile{filename: $filename, _length: $_length}';
  }

  @override
  int getPosition() {
    return _position;
  }

  @override
  Stream<List<int>> get inputStream async* {
    int length = await this.length();
    while (_position < length) {
      int l = math.min(length - _position, 10000);
      Readbuffer readbuffer = await readFromFile(l);
      yield readbuffer.getBuffer(0, l);
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class _ReadbufferFileResource {
  /// The Random access file handle to the underlying file
  final RandomAccessFile _raf;

  _ReadbufferFileResource(String filename) : _raf = File(filename).openSync();

  void close() {
    _raf.close();
  }

  Future<void> setPosition(int position) async {
    await _raf.setPosition(position);
  }

  Future<Uint8List> read(int length) async {
    Uint8List result = await _raf.read(length);
    assert(result.length == length);
    return result;
  }

  Future<Uint8List> readAt(int position, int length) async {
    RandomAccessFile raf = await _raf.setPosition(position);
    Uint8List result = await raf.read(length);
    assert(result.length == length, "read ${result.length} != requested $length for reading file at position ${position.toRadixString(16)}");
    return result;
  }

  Future<int> length() async {
    return await _raf.length();
  }
}
