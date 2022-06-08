import 'dart:typed_data';

import 'package:ecache/ecache.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/exceptions/filenotfoundexception.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';
import 'dart:io';

import 'package:mapsforge_flutter/src/parameters.dart';

/// Reads the mapfile from a physical file
class ReadbufferFile implements ReadbufferSource {
  static final _log = new Logger('ReadbufferFile');

  /// The Random access file handle to the underlying file
  RandomAccessFile? _raf;

  /// The filename of the underlying file
  final String filename;

  int? _length;

  final StatisticsStorage<String, Readbuffer> _storage =
      StatisticsStorage<String, Readbuffer>();

  late LruCache<String, Readbuffer> _cache;

  ReadbufferFile(this.filename) {
    _cache = LruCache(storage: _storage, capacity: 1000);
  }

  @override
  Future<Uint8List> readDirect(
      int indexBlockPosition, int indexBlockSize) async {
    //int time = DateTime.now().millisecondsSinceEpoch;
    await _openRaf();
    RandomAccessFile newInstance = await _raf!.setPosition(indexBlockPosition);
    //_log.info("readDirect needed ${DateTime.now().millisecondsSinceEpoch - time} ms");
    Uint8List result = await newInstance.read(indexBlockSize);
    assert(result.length == indexBlockSize);
    return result;
  }

  /// Reads the given amount of bytes from the file into the read buffer and resets the internal buffer position. If
  /// the capacity of the read buffer is too small, a larger one is created automatically.
  ///
  /// @param length the amount of bytes to read from the file.
  /// @return true if the whole data was read successfully, false otherwise.
  /// @throws IOException if an error occurs while reading the file.
  @override
  Future<Readbuffer> readFromFile({int? offset, required int length}) async {
    assert(length > 0);
    // ensure that the read buffer is large enough
    if (length > Parameters.MAXIMUM_BUFFER_SIZE) {
      throw Exception("invalid read length: $length");
    }

    String cacheKey = "$offset-$length";
    Readbuffer? result = _cache.get(cacheKey);
    if (result != null) {
      // return a new copy so that the new buffer can work independently from the old one
      return Readbuffer.from(result);
    }

    //int time = DateTime.now().millisecondsSinceEpoch;
    await _openRaf();
    RandomAccessFile? _newRaf = _raf;
    if (offset != null) {
      assert(offset >= 0);
      _newRaf = await this._raf!.setPosition(offset);
    }
    Uint8List _bufferData = await _newRaf!.read(length);
    assert(_bufferData.length == length);
    //_log.info("readFromFile needed ${DateTime.now().millisecondsSinceEpoch - time} ms");
    result = Readbuffer(_bufferData, offset);
    _cache[cacheKey] = result;
    return result;
  }

  @override
  void close() {
    _raf?.close();
    _raf = null;
  }

  Future<RandomAccessFile?> _openRaf() async {
    if (_raf != null) {
      return Future.value(_raf);
    }
    File file = File(filename);
    bool ok = await file.exists();
    if (!ok) {
      throw FileNotFoundException(filename);
    }
    _raf = await file.open();
    return _raf;
  }

  @override
  Future<int> length() async {
    if (_length != null) return _length!;
    //int time = DateTime.now().millisecondsSinceEpoch;
    await _openRaf();
    _length = await _raf!.length();
    assert(_length != null && _length! >= 0);
    //_log.info("length needed ${DateTime.now().millisecondsSinceEpoch - time} ms");
    return _length!;
  }
}
