import 'dart:math';
import 'dart:typed_data';

import 'package:ecache/ecache.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';

import '../datastore/deserializer.dart';
import 'indexcacheentrykey.dart';
import 'subfileparameter.dart';
import 'subfileparameterbuilder.dart';
import 'package:logging/logging.dart';

///
/// A cache for database index blocks with a fixed size and LRU policy.
///
class IndexCache {
  static final _log = new Logger('IndexCache');

  /// Number of index entries that one index block consists of.
  static const int INDEX_ENTRIES_PER_BLOCK = 128;

  /// Maximum size in bytes of one index block.
  static final int SIZE_OF_INDEX_BLOCK =
      INDEX_ENTRIES_PER_BLOCK * SubFileParameterBuilder.BYTES_PER_INDEX_ENTRY;

  final LruCache<IndexCacheEntryKey, Uint8List> _cache;

  int _successes = 0;

  int _misses = 0;

  /// @param inputChannel the map file from which the index should be read and cached.
  /// @param capacity     the maximum number of entries in the cache.
  /// @throws IllegalArgumentException if the capacity is negative.
  IndexCache(int capacity)
      : _cache = LruCache<IndexCacheEntryKey, Uint8List>(
            storage: StatisticsStorage(), capacity: capacity);

  /// Destroy the cache at the end of its lifetime.
  void dispose() {
    _log.info(
        "Statistics for IndexCache: ${_cache.storage.toString()}, successes: $_successes, misses: $_misses");
    this._cache.clear();
  }

  /**
   * Returns the index entry of a block in the given map file. If the required index entry is not cached, it will be
   * read from the map file index and put in the cache.
   *
   * @param subFileParameter the parameters of the map file for which the index entry is needed.
   * @param blockNumber      the number of the block in the map file.
   * @return the index entry.
   * @throws IOException if an I/O error occurs during reading.
   */
  Future<int> getIndexEntry(SubFileParameter subFileParameter, int blockNumber,
      ReadbufferSource readBufferMaster) async {
    // check if the block number is out of bounds
    assert(blockNumber < subFileParameter.numberOfBlocks);

    // calculate the index block number
    int indexBlockNumber = (blockNumber / INDEX_ENTRIES_PER_BLOCK).floor();

    // create the cache entry key for this request
    IndexCacheEntryKey indexCacheEntryKey =
        new IndexCacheEntryKey(subFileParameter, indexBlockNumber);

    // check for cached index block
    Uint8List? indexBlock = this._cache[indexCacheEntryKey];
    if (indexBlock == null) {
      // cache miss, seek to the correct index block in the file and read it
      int indexBlockPosition = subFileParameter.indexStartAddress! +
          indexBlockNumber * SIZE_OF_INDEX_BLOCK;

      int remainingIndexSize =
          (subFileParameter.indexEndAddress - indexBlockPosition);
      int indexBlockSize = min(SIZE_OF_INDEX_BLOCK, remainingIndexSize);

      //ReadBufferMaster _readBufferMaster = ReadBufferMaster(filename);
      indexBlock =
          await readBufferMaster.readDirect(indexBlockPosition, indexBlockSize);
      //_readBufferMaster.close();

      // put the index block in the map
      this._cache[indexCacheEntryKey] = indexBlock;
      ++_misses;
    } else {
      ++_successes;
    }

    // calculate the address of the index entry inside the index block
    int indexEntryInBlock = blockNumber % INDEX_ENTRIES_PER_BLOCK;
    int addressInIndexBlock =
        (indexEntryInBlock * SubFileParameterBuilder.BYTES_PER_INDEX_ENTRY);

    // return the real index entry
    return Deserializer.getFiveBytesLong(indexBlock, addressInIndexBlock);
  }

  @override
  String toString() {
    return 'IndexCache{map: $_cache, successes: $_successes, misses: $_misses}';
  }
}
