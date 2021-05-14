import 'package:mapsforge_flutter/src/projection/mercatorprojectionimpl.dart';

import '../model/boundingbox.dart';
import 'subfileparameter.dart';

class SubFileParameterBuilder {
  /**
   * Number of bytes a single index entry consists of.
   */
  static final int BYTES_PER_INDEX_ENTRY = 5;

  int? baseZoomLevel;
  BoundingBox? boundingBox;
  int? indexStartAddress;
  int? startAddress;
  int? subFileSize;
  int? zoomLevelMax;
  int? zoomLevelMin;

  SubFileParameter build() {
    // calculate the XY numbers of the boundary tiles in this sub-file
    MercatorProjectionImpl mercatorProjectionImpl = MercatorProjectionImpl(500, this.baseZoomLevel!);
    int boundaryTileBottom = mercatorProjectionImpl.latitudeToTileY(boundingBox!.minLatitude!);
    int boundaryTileLeft = mercatorProjectionImpl.longitudeToTileX(boundingBox!.minLongitude!);
    int boundaryTileTop = mercatorProjectionImpl.latitudeToTileY(boundingBox!.maxLatitude!);
    int boundaryTileRight = mercatorProjectionImpl.longitudeToTileX(boundingBox!.maxLongitude!);

    // calculate the horizontal and vertical amount of blocks in this sub-file
    int blocksWidth = boundaryTileRight - boundaryTileLeft + 1;
    int blocksHeight = boundaryTileBottom - boundaryTileTop + 1;

    // calculate the total amount of blocks in this sub-file
    int numberOfBlocks = blocksWidth * blocksHeight;

    return new SubFileParameter(
      baseZoomLevel,
      boundaryTileBottom - boundaryTileTop + 1,
      boundaryTileRight - boundaryTileLeft + 1,
      boundaryTileBottom,
      boundaryTileLeft,
      boundaryTileRight,
      boundaryTileTop,
      this.indexStartAddress! + numberOfBlocks * BYTES_PER_INDEX_ENTRY,
      indexStartAddress,
      numberOfBlocks,
      startAddress,
      subFileSize,
      zoomLevelMax,
      zoomLevelMin,
    );
  }
}
