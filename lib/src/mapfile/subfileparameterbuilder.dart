import 'package:mapsforge_flutter/src/mapfile/mapfile_info_builder.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/projection/mercatorprojection.dart';

import '../exceptions/mapfileexception.dart';
import '../model/boundingbox.dart';
import 'subfileparameter.dart';

class SubFileParameterBuilder {
  /// Maximum valid base zoom level of a sub-file.
  static final int BASE_ZOOM_LEVEL_MAX = 20;

  /// Number of bytes a single index entry consists of.
  static final int BYTES_PER_INDEX_ENTRY = 5;

  /// Length of the debug signature at the beginning of the index.
  static final int SIGNATURE_LENGTH_INDEX = 16;

  static int id = 0;
  int? baseZoomLevel;
  BoundingBox? boundingBox;
  int? indexStartAddress;
  int? startAddress;
  int? subFileSize;
  int? zoomLevelMax;
  int? zoomLevelMin;

  SubFileParameterBuilder() {
    ++id;
  }

  void read(Readbuffer readbuffer, int fileSize, bool isDebug,
      BoundingBox boundingBox) {
    // get and check the base zoom level (1 byte)
    int baseZoomLevel = readbuffer.readByte();
    if (baseZoomLevel < 0 || baseZoomLevel > BASE_ZOOM_LEVEL_MAX) {
      throw new MapFileException("invalid base zoom level: $baseZoomLevel");
    }
    this.baseZoomLevel = baseZoomLevel;

    // get and check the minimum zoom level (1 byte)
    int zoomLevelMin = readbuffer.readByte();
    if (zoomLevelMin < 0 || zoomLevelMin > 22) {
      throw new Exception("invalid minimum zoom level: $zoomLevelMin");
    }
    this.zoomLevelMin = zoomLevelMin;

    // get and check the maximum zoom level (1 byte)
    int zoomLevelMax = readbuffer.readByte();
    if (zoomLevelMax < 0 || zoomLevelMax > 22) {
      throw new Exception("invalid maximum zoom level: $zoomLevelMax");
    }
    this.zoomLevelMax = zoomLevelMax;

    // check for valid zoom level range
    if (zoomLevelMin > zoomLevelMax) {
      throw new Exception(
          "invalid zoom level range: $zoomLevelMin $zoomLevelMax");
    }

    // get and check the start address of the sub-file (8 bytes)
    int startAddress = readbuffer.readLong();
    if (startAddress < MapfileInfoBuilder.HEADER_SIZE_MIN ||
        startAddress >= fileSize) {
      throw new Exception("invalid start address: $startAddress");
    }
    this.startAddress = startAddress;

    int indexStartAddress = startAddress;
    if (isDebug) {
      // the sub-file has an index signature before the index
      indexStartAddress += SIGNATURE_LENGTH_INDEX;
    }
    this.indexStartAddress = indexStartAddress;

    // get and check the size of the sub-file (8 bytes)
    int subFileSize = readbuffer.readLong();
    if (subFileSize < 1) {
      throw new Exception("invalid sub-file size: $subFileSize");
    }
    this.subFileSize = subFileSize;

    this.boundingBox = boundingBox;
  }

  SubFileParameter build() {
    assert(boundingBox!.minLatitude <= boundingBox!.maxLatitude);
    assert(boundingBox!.minLongitude <= boundingBox!.maxLongitude);
    // calculate the XY numbers of the boundary tiles in this sub-file
    MercatorProjection projection =
        MercatorProjection.fromZoomlevel(baseZoomLevel!);
    int boundaryTileBottom =
        projection.latitudeToTileY(boundingBox!.minLatitude);
    int boundaryTileLeft =
        projection.longitudeToTileX(boundingBox!.minLongitude);
    int boundaryTileTop = projection.latitudeToTileY(boundingBox!.maxLatitude);
    int boundaryTileRight =
        projection.longitudeToTileX(boundingBox!.maxLongitude);
    assert(boundaryTileTop <= boundaryTileBottom,
        "lat ${boundingBox!.minLatitude} to ${boundingBox!.maxLatitude} recalculated to $boundaryTileBottom to $boundaryTileTop");
    assert(boundaryTileLeft <= boundaryTileRight);

    // calculate the horizontal and vertical amount of blocks in this sub-file
    int blocksWidth = boundaryTileRight - boundaryTileLeft + 1;
    int blocksHeight = boundaryTileBottom - boundaryTileTop + 1;

    // calculate the total amount of blocks in this sub-file
    int numberOfBlocks = blocksWidth * blocksHeight;

    return SubFileParameter(
      id,
      baseZoomLevel!,
      boundaryTileBottom - boundaryTileTop + 1,
      boundaryTileRight - boundaryTileLeft + 1,
      boundaryTileBottom,
      boundaryTileLeft,
      boundaryTileRight,
      boundaryTileTop,
      this.indexStartAddress! + numberOfBlocks * BYTES_PER_INDEX_ENTRY,
      indexStartAddress!,
      numberOfBlocks,
      startAddress!,
      subFileSize!,
      zoomLevelMax!,
      zoomLevelMin!,
      projection,
    );
  }
}
