/// Holds all parameters of a sub-file. A subfile is a portion of a map. It is not necessarily dependent on a mapFILE.
class SubFileParameter {
  /// The id of this class. We have several SubFileParameters and one SubFileParameter may be responsible for several zoomLevels. To
  /// distinuish between the different parameters we need this id
  final int id;
  /**
   * Base zoom level of the sub-file, which equals to one block.
   */
  final int baseZoomLevel;

  /**
   * Vertical amount of blocks in the grid.
   */
  final int blocksHeight;

  /**
   * Horizontal amount of blocks in the grid.
   */
  final int blocksWidth;

  /**
   * Y number of the tile at the bottom boundary in the grid.
   */
  final int boundaryTileBottom;

  /**
   * X number of the tile at the left boundary in the grid.
   */
  final int boundaryTileLeft;

  /**
   * X number of the tile at the right boundary in the grid.
   */
  final int boundaryTileRight;

  /**
   * Y number of the tile at the top boundary in the grid.
   */
  final int boundaryTileTop;

  /**
   * Absolute end address of the index in the enclosing file.
   */
  final int indexEndAddress;

  /**
   * Absolute start address of the index in the enclosing file.
   */
  final int? indexStartAddress;

  /**
   * Total number of blocks in the grid.
   */
  final int numberOfBlocks;

  /**
   * Absolute start address of the sub-file in the enclosing file.
   */
  final int startAddress;

  /**
   * Size of the sub-file in bytes.
   */
  final int? subFileSize;

  /**
   * Maximum zoom level for which the block entries tables are made.
   */
  final int zoomLevelMax;

  /**
   * Minimum zoom level for which the block entries tables are made.
   */
  final int zoomLevelMin;

  SubFileParameter(
    this.id,
    this.baseZoomLevel,
    this.blocksHeight,
    this.blocksWidth,
    this.boundaryTileBottom,
    this.boundaryTileLeft,
    this.boundaryTileRight,
    this.boundaryTileTop,
    this.indexEndAddress,
    this.indexStartAddress,
    this.numberOfBlocks,
    this.startAddress,
    this.subFileSize,
    this.zoomLevelMax,
    this.zoomLevelMin,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubFileParameter &&
          runtimeType == other.runtimeType &&
          baseZoomLevel == other.baseZoomLevel &&
          blocksHeight == other.blocksHeight &&
          blocksWidth == other.blocksWidth &&
          boundaryTileBottom == other.boundaryTileBottom &&
          boundaryTileLeft == other.boundaryTileLeft &&
          boundaryTileRight == other.boundaryTileRight &&
          boundaryTileTop == other.boundaryTileTop &&
          indexEndAddress == other.indexEndAddress &&
          indexStartAddress == other.indexStartAddress &&
          numberOfBlocks == other.numberOfBlocks &&
          startAddress == other.startAddress &&
          subFileSize == other.subFileSize &&
          zoomLevelMax == other.zoomLevelMax &&
          zoomLevelMin == other.zoomLevelMin;

  @override
  int get hashCode =>
      baseZoomLevel.hashCode ^
      blocksHeight.hashCode ^
      blocksWidth.hashCode ^
      boundaryTileBottom.hashCode ^
      boundaryTileLeft.hashCode ^
      boundaryTileRight.hashCode ^
      boundaryTileTop.hashCode ^
      indexEndAddress.hashCode ^
      indexStartAddress.hashCode ^
      numberOfBlocks.hashCode ^
      startAddress.hashCode ^
      subFileSize.hashCode ^
      zoomLevelMax.hashCode ^
      zoomLevelMin.hashCode;

  @override
  String toString() {
    return 'SubFileParameter{baseZoomLevel: $baseZoomLevel, blocksHeight: $blocksHeight, blocksWidth: $blocksWidth, boundaryTileBottom: $boundaryTileBottom, boundaryTileLeft: $boundaryTileLeft, boundaryTileRight: $boundaryTileRight, boundaryTileTop: $boundaryTileTop, indexEndAddress: $indexEndAddress, indexStartAddress: $indexStartAddress, numberOfBlocks: $numberOfBlocks, startAddress: $startAddress, subFileSize: $subFileSize, zoomLevelMax: $zoomLevelMax, zoomLevelMin: $zoomLevelMin}';
  }

// Projection projection() {
//   if (_projection != null) return _projection!;
//   _projection = MercatorProjection.fromZoomlevel(baseZoomLevel!);
//   return _projection!;
// }
}
