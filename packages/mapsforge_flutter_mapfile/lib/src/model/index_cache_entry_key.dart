import 'package:mapsforge_flutter_mapfile/mapfile_debug.dart';

/// An immutable key for an entry in the [IndexCache].
///
/// This key uniquely identifies an index block by combining the parameters of the
/// sub-file it belongs to with the block number within that sub-file.
class IndexCacheEntryKey {
  final int indexBlockNumber;
  final SubFileParameter subFileParameter;

    /// Creates an immutable key for an index cache entry.
  ///
  /// [subFileParameter] defines the sub-file that the index block belongs to.
  /// [indexBlockNumber] is the number of the index block within the sub-file.
  IndexCacheEntryKey(this.subFileParameter, this.indexBlockNumber);

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
