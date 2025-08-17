import 'subfileparameter.dart';

/// An immutable container class which is the key for the index cache.
class IndexCacheEntryKey {
  final int indexBlockNumber;
  final SubFileParameter subFileParameter;

  /**
   * Creates an immutable key to be stored in a map.
   *
   * @param subFileParameter the parameters of the map file.
   * @param indexBlockNumber the number of the index block.
   */
  IndexCacheEntryKey(this.subFileParameter, this.indexBlockNumber) {}

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndexCacheEntryKey &&
          runtimeType == other.runtimeType &&
          indexBlockNumber == other.indexBlockNumber &&
          subFileParameter == other.subFileParameter;

  @override
  int get hashCode => indexBlockNumber.hashCode ^ subFileParameter.hashCode;

  @override
  String toString() {
    return 'IndexCacheEntryKey{indexBlockNumber: $indexBlockNumber}';
  }
}
