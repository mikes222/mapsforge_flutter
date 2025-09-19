import 'dart:math';
import 'dart:typed_data';

import 'package:ecache/ecache.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_debug.dart';
import 'package:mapsforge_flutter_mapfile/src/model/index_cache_entry_key.dart';
import 'package:mapsforge_flutter_mapfile/src/reader/subfile_parameter_builder.dart';

/// A cache for map file index blocks with a fixed size and a Last Recently Used (LRU)
/// eviction policy.
///
/// The map file index is divided into blocks. Caching these blocks in memory
/// significantly improves performance by reducing the number of disk reads required
/// to find the location of a specific map data block.
class IndexCache {
  static final _log = Logger('IndexCache');

  /// Number of index entries that one index block consists of.
  static const int INDEX_ENTRIES_PER_BLOCK = 128;

  /// Maximum size in bytes of one index block.
  static final int SIZE_OF_INDEX_BLOCK = INDEX_ENTRIES_PER_BLOCK * SubFileParameterBuilder.BYTES_PER_INDEX_ENTRY;

  final LruCache<IndexCacheEntryKey, Uint8List> _cache;

    /// Constructs an [IndexCache] with a given [capacity].
  ///
  /// [capacity] is the maximum number of index blocks to store in the cache.
  IndexCache(int capacity) : _cache = LruCache<IndexCacheEntryKey, Uint8List>(capacity: capacity, name: "MapfileIndexCache");

    /// Destroys the cache and releases all stored resources.
  void dispose() {
    _cache.dispose();
  }

    /// Returns the index entry for a given data block.
  ///
  /// An index entry is a 5-byte value that contains the offset of a data block
  /// within its sub-file, as well as a flag indicating if the block contains only
  /// water tiles.
  ///
  /// If the required index block is not already in the cache, it will be read
  /// from the [readBufferSource] and stored in the cache before the entry is returned.
  ///
  /// [subFileParameter] describes the sub-file being queried.
  /// [blockNumber] is the absolute number of the data block within the sub-file.
  /// [readBufferSource] is the file handle to read from if a cache miss occurs.
  Future<int> getIndexEntry(SubFileParameter subFileParameter, int blockNumber, ReadbufferSource readBufferSource) async {
    // check if the block number is out of bounds
    assert(blockNumber < subFileParameter.numberOfBlocks);

    // calculate the index block number
    int indexBlockNumber = (blockNumber / INDEX_ENTRIES_PER_BLOCK).floor();

    // create the cache entry key for this request
    IndexCacheEntryKey indexCacheEntryKey = IndexCacheEntryKey(subFileParameter, indexBlockNumber);

    // check for cached index block
    Uint8List indexBlock = await _cache.getOrProduce(indexCacheEntryKey, (key) async {
      // cache miss, seek to the correct index block in the file and read it
      int indexBlockPosition = subFileParameter.indexStartAddress + indexBlockNumber * SIZE_OF_INDEX_BLOCK;

      int remainingIndexSize = (subFileParameter.indexEndAddress - indexBlockPosition);
      int indexBlockSize = min(SIZE_OF_INDEX_BLOCK, remainingIndexSize);

      //ReadBufferMaster _readBufferMaster = ReadBufferMaster(filename);
      Readbuffer readbuffer = await readBufferSource.readFromFileAt(indexBlockPosition, indexBlockSize);
      return readbuffer.getBuffer(0, indexBlockSize);
    });

    // calculate the address of the index entry inside the index block
    int indexEntryInBlock = blockNumber % INDEX_ENTRIES_PER_BLOCK;
    int addressInIndexBlock = (indexEntryInBlock * SubFileParameterBuilder.BYTES_PER_INDEX_ENTRY);

    // return the real index entry
    return Deserializer.getFiveBytesLong(indexBlock, addressInIndexBlock);
  }

  @override
  String toString() {
    return 'IndexCache{map: $_cache}';
  }
}
