import 'dart:math';

import 'package:mapsforge_flutter/src/mapfile/subfileparameter.dart';

import '../datastore/deserializer.dart';
import 'readbuffer.dart';
import 'subfileparameterbuilder.dart';

/**
 * A cache for database index blocks with a fixed size and LRU policy.
 */
class IndexNoCache {
  /**
   * Number of index entries that one index block consists of.
   */
  static final int INDEX_ENTRIES_PER_BLOCK = 128;

  /**
   * Maximum size in bytes of one index block.
   */
  static final int SIZE_OF_INDEX_BLOCK = INDEX_ENTRIES_PER_BLOCK * SubFileParameterBuilder.BYTES_PER_INDEX_ENTRY;

  /**
   * @param inputChannel the map file from which the index should be read and cached.
   * @param capacity     the maximum number of entries in the cache.
   * @throws IllegalArgumentException if the capacity is negative.
   */
  IndexNoCache(String filename, int capacity);

  /**
   * Destroy the cache at the end of its lifetime.
   */
  void destroy() {}

  /**
   * Returns the index entry of a block in the given map file. If the required index entry is not cached, it will be
   * read from the map file index and put in the cache.
   *
   * @param subFileParameter the parameters of the map file for which the index entry is needed.
   * @param blockNumber      the number of the block in the map file.
   * @return the index entry.
   * @throws IOException if an I/O error occurs during reading.
   */
  Future<int> getIndexEntry(SubFileParameter subFileParameter, int blockNumber, ReadBufferMaster readBufferMaster) async {
    // check if the block number is out of bounds
    if (blockNumber >= subFileParameter.numberOfBlocks) {
      throw new Exception("invalid block number: $blockNumber");
    }

    // calculate the index block number
    int indexBlockNumber = (blockNumber / INDEX_ENTRIES_PER_BLOCK).floor();

    // check for cached index block
    // cache miss, seek to the correct index block in the file and read it
    int indexBlockPosition = subFileParameter.indexStartAddress! + indexBlockNumber * SIZE_OF_INDEX_BLOCK;

    int remainingIndexSize = (subFileParameter.indexEndAddress - indexBlockPosition);
    int indexBlockSize = min(SIZE_OF_INDEX_BLOCK, remainingIndexSize);

    List<int> indexBlock = await readBufferMaster.readDirect(indexBlockPosition, indexBlockSize);

    // calculate the address of the index entry inside the index block
    int indexEntryInBlock = blockNumber % INDEX_ENTRIES_PER_BLOCK;
    int addressInIndexBlock = (indexEntryInBlock * SubFileParameterBuilder.BYTES_PER_INDEX_ENTRY);

    // return the real index entry
    return Deserializer.getFiveBytesLong(indexBlock, addressInIndexBlock);
  }

  @override
  String toString() {
    return 'IndexCache';
  }
}
