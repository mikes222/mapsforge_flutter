import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_debug.dart';
import 'package:mapsforge_flutter_mapfile/src/exceptions/mapfile_exception.dart';
import 'package:mapsforge_flutter_mapfile/src/reader/mapfile_info_builder.dart';

/// A builder that reads the parameters of a sub-file from the map file header and
/// constructs a [SubFileParameter] object.
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

    /// Reads the sub-file parameters from the given [readbuffer].
  void read(Readbuffer readbuffer, int fileSize, bool isDebug, BoundingBox boundingBox) {
    // get and check the base zoom level (1 byte)
    int baseZoomLevel = readbuffer.readByte();
    if (baseZoomLevel < 0 || baseZoomLevel > BASE_ZOOM_LEVEL_MAX) {
      throw MapFileException("invalid base zoom level: $baseZoomLevel");
    }
    this.baseZoomLevel = baseZoomLevel;

    // get and check the minimum zoom level (1 byte)
    int zoomLevelMin = readbuffer.readByte();
    if (zoomLevelMin < 0 || zoomLevelMin > 22) {
      throw Exception("invalid minimum zoom level: $zoomLevelMin");
    }
    this.zoomLevelMin = zoomLevelMin;

    // get and check the maximum zoom level (1 byte)
    int zoomLevelMax = readbuffer.readByte();
    if (zoomLevelMax < 0 || zoomLevelMax > 22) {
      throw Exception("invalid maximum zoom level: $zoomLevelMax");
    }
    this.zoomLevelMax = zoomLevelMax;

    // check for valid zoom level range
    if (zoomLevelMin > zoomLevelMax) {
      throw Exception("invalid zoom level range: $zoomLevelMin $zoomLevelMax");
    }

    // get and check the start address of the sub-file (8 bytes)
    int startAddress = readbuffer.readLong();
    if (startAddress < MapfileInfoBuilder.HEADER_SIZE_MIN || startAddress >= fileSize) {
      throw Exception("invalid start address: $startAddress");
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
      throw Exception("invalid sub-file size: $subFileSize");
    }
    this.subFileSize = subFileSize;

    this.boundingBox = boundingBox;
  }

    /// Builds the immutable [SubFileParameter] object from the parsed data.
  ///
  /// This method also calculates derived values such as the number of blocks and
  /// the tile boundaries.
  SubFileParameter build() {
    assert(boundingBox!.minLatitude <= boundingBox!.maxLatitude);
    assert(boundingBox!.minLongitude <= boundingBox!.maxLongitude);
    // calculate the XY numbers of the boundary tiles in this sub-file
    MercatorProjection projection = MercatorProjection.fromZoomlevel(baseZoomLevel!);
    int boundaryTileBottom = projection.latitudeToTileY(boundingBox!.minLatitude);
    int boundaryTileLeft = projection.longitudeToTileX(boundingBox!.minLongitude);
    int boundaryTileTop = projection.latitudeToTileY(boundingBox!.maxLatitude);
    int boundaryTileRight = projection.longitudeToTileX(boundingBox!.maxLongitude);
    assert(
      boundaryTileTop <= boundaryTileBottom,
      "lat ${boundingBox!.minLatitude} to ${boundingBox!.maxLatitude} recalculated to $boundaryTileBottom to $boundaryTileTop",
    );
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
      indexStartAddress! + numberOfBlocks * BYTES_PER_INDEX_ENTRY,
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
