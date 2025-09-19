import 'package:mapsforge_flutter_core/src/projection/mercator_projection.dart';

/// An immutable data class that holds all parameters of a map file's sub-file.
///
/// A Mapsforge map file is divided into several sub-files, each containing the
/// map data for a specific range of zoom levels. This class stores the metadata
/// for one such sub-file, including its zoom range, size, and the location of its
/// index and data blocks within the main map file.
class SubFileParameter {
    /// A unique identifier for this sub-file parameter set.
  final int id;

    /// The base zoom level of this sub-file. All data within this sub-file is
  /// stored relative to this zoom level.
  final int baseZoomLevel;

    /// The height of the sub-file's grid in blocks.
  final int blocksHeight;

    /// The width of the sub-file's grid in blocks.
  final int blocksWidth;

    /// The Y-coordinate of the bottom-most tile at the base zoom level.
  final int boundaryTileBottom;

    /// The X-coordinate of the left-most tile at the base zoom level.
  final int boundaryTileLeft;

    /// The X-coordinate of the right-most tile at the base zoom level.
  final int boundaryTileRight;

    /// The Y-coordinate of the top-most tile at the base zoom level.
  final int boundaryTileTop;

    /// The absolute end address of this sub-file's index within the main map file.
  final int indexEndAddress;

    /// The absolute start address of this sub-file's index within the main map file.
  final int indexStartAddress;

    /// The total number of data blocks in this sub-file.
  final int numberOfBlocks;

    /// The absolute start address of this sub-file's data within the main map file.
  final int startAddress;

    /// The total size of this sub-file in bytes.
  final int subFileSize;

    /// The maximum zoom level that this sub-file provides data for.
  final int zoomLevelMax;

    /// The minimum zoom level that this sub-file provides data for.
  final int zoomLevelMin;

    /// A cached [MercatorProjection] instance for this sub-file's base zoom level.
  final MercatorProjection projection;

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
    this.projection,
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
