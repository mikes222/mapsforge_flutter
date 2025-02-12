import 'dart:io';
import 'dart:typed_data';

import 'package:ecache/ecache.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';
import 'package:mapsforge_flutter/src/parameters.dart';

import '../utils/timing.dart';

/// Reads the mapfile from a physical file
class ReadbufferFile implements ReadbufferSource {
  static final _log = new Logger('ReadbufferFile');

  /// ressource for consecutive reads
  _ReadBufferFileResource? _resource;

  /// ressource for random access
  List<_ReadBufferFileResource> _resourceAts = [];

  /// The filename of the underlying file
  final String filename;

  int? _length;

  final Storage<String, Readbuffer> _storage =
      WeakReferenceStorage<String, Readbuffer>();

  late LruCache<String, Readbuffer> _cache;

  int _position = 0;

  ReadbufferFile(this.filename) {
    _cache = LruCache(storage: _storage, capacity: 500);
  }

  @override
  void dispose() {
    _resource?.close();
    _resource = null;
    _resourceAts.forEach((action) => action.close());
    _resourceAts.clear();
    _cache.clear();
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
    // ensure that the read buffer is large enough
    assert(length <= Parameters.MAXIMUM_BUFFER_SIZE);

    String cacheKey = "$_position-$length";

    Timing timing = Timing(log: _log);
    Readbuffer readbuffer =
        await _cache.getOrProduce(cacheKey, (String key) async {
      _resource ??= _ReadBufferFileResource(filename);
      Uint8List _bufferData = await _resource!.read(length);
      assert(_bufferData.length == length);
      _position += length;
      Readbuffer result = Readbuffer(_bufferData, _position);
      return result;
    });
    timing.lap(100, "readFromFile position: $_position, length: $length");
    return Readbuffer.from(readbuffer);
  }

  @override
  Future<Readbuffer> readFromFileAt(int position, int length) async {
    assert(length > 0);
    assert(position >= 0);
    // ensure that the read buffer is large enough
    assert(length <= Parameters.MAXIMUM_BUFFER_SIZE);

    String cacheKey = "$position-$length";

    Timing timing = Timing(log: _log);
    Readbuffer result = await _cache.getOrProduce(cacheKey, (String key) async {
      _ReadBufferFileResource _ressourceAt = _resourceAts.isNotEmpty
          ? _resourceAts.removeLast()
          : _ReadBufferFileResource(filename);
      await _ressourceAt.setPosition(position);
      Uint8List _bufferData = await _ressourceAt.read(length);
      assert(_bufferData.length == length);
      _resourceAts.add(_ressourceAt);
      Readbuffer result = Readbuffer(_bufferData, position);
      return result;
    });
    timing.lap(100, "readFromFile position: $position, length: $length");
    return Readbuffer.from(result);
  }

  @override
  Future<int> length() async {
    if (_length != null) return _length!;
    _ReadBufferFileResource _ressourceAt = _resourceAts.isNotEmpty
        ? _resourceAts.removeLast()
        : _ReadBufferFileResource(filename);
    _length = await _ressourceAt.length();
    assert(_length! >= 0);
    _resourceAts.add(_ressourceAt);
    //_log.info("length needed ${DateTime.now().millisecondsSinceEpoch - time} ms");
    return _length!;
  }

  @override
  String toString() {
    return 'ReadbufferFile{filename: $filename, _length: $_length}';
  }
}

//////////////////////////////////////////////////////////////////////////////

class _ReadBufferFileResource {
  static final _log = new Logger('_ReadBufferFileResource');

  /// The Random access file handle to the underlying file
  RandomAccessFile _raf;

  static int _increment = 0;

  final int _id = ++_increment;

  _ReadBufferFileResource(String filename) : _raf = File(filename).openSync();

  void close() {
    _raf.close();
  }

  Future<void> setPosition(int position) async {
    //_log.info("setPosition $position start ${_id}");
    await _raf.setPosition(position);
    //_log.info("setPosition $position end ${_id}");
  }

  Future<Uint8List> read(int length) async {
    //_log.info("read $length start ${_id}");
    Uint8List result = await _raf.read(length);
    //_log.info("read $length end ${_id}");
    return result;
  }

  Future<int> length() async {
    return await _raf.length();
  }
}
