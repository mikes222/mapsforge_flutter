import 'package:ecache/ecache.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';
import 'package:mapsforge_flutter/src/parameters.dart';
import 'package:mapsforge_storage/mapsforge_storage.dart';

/// Reads the mapfile from a physical file on external sdCard
class ReadbufferSd implements ReadbufferSource {
  static final _log = Logger('ReadbufferSd');

  final MapsforgeStorage storageHandler;

  int? _length;

  final StatisticsStorage<String, Readbuffer> _storage =
      StatisticsStorage<String, Readbuffer>();

  late LruCache<String, Readbuffer> _cache;

  ReadbufferSd(this.storageHandler) {
    _cache = LruCache(storage: _storage, capacity: 1000);
  }

  @override
  void close() {}

  @override
  Future<int> length() async {
    if (_length != null) return _length!;

    _length = await storageHandler.getLength();

    assert(_length != null && _length! >= 0);

    return _length!;
  }

  @override
  Future<Uint8List> readDirect(
      int indexBlockPosition, int indexBlockSize) async {
    final result =
        await storageHandler.readMapFile(indexBlockPosition, indexBlockSize);

    assert(result!.length == indexBlockSize);

    return result!;
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

    final bytes = await storageHandler.readMapFile(offset, length);

    assert(bytes?.length == length);

    result = Readbuffer(bytes!, offset);
    _cache[cacheKey] = result;

    return result;
  }
}
