import 'package:mapsforge_flutter/src/projection/mercatorprojection.dart';
import 'package:mapsforge_flutter/src/projection/projection.dart';

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
    Projection projection = MercatorProjection.fromZoomlevel(baseZoomLevel!);
    int boundaryTileBottom = projection.latitudeToTileY(boundingBox!.minLatitude);
    int boundaryTileLeft = projection.longitudeToTileX(boundingBox!.minLongitude);
    int boundaryTileTop = projection.latitudeToTileY(boundingBox!.maxLatitude);
    int boundaryTileRight = projection.longitudeToTileX(boundingBox!.maxLongitude);

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
      startAddress!,
      subFileSize,
      zoomLevelMax!,
      zoomLevelMin!,
    );
  }
}
