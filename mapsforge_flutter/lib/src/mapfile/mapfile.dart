import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfilehelper.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfileinfo.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/mapfile/readbufferfile.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffermemory.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';
import 'package:mapsforge_flutter/src/mapfile/subfileparameter.dart';
import 'package:mapsforge_flutter/src/parameters.dart';
import 'package:mapsforge_flutter/src/projection/projection.dart';

import '../datastore/datastorereadresult.dart';
import '../datastore/mapdatastore.dart';
import '../datastore/pointofinterest.dart';
import '../datastore/poiwaybundle.dart';
import '../datastore/way.dart';
import '../projection/mercatorprojection.dart';
import '../reader/queryparameters.dart';
import 'indexcache.dart';
import 'mapfileheader.dart';

/// A class for reading binary map files.
/// The mapFile should be disposed if not needed anymore
class MapFile extends MapDataStore {
  static final _log = new Logger('MapFile');

  /**
   * Bitmask to extract the block offset from an index entry.
   */
  static final int BITMASK_INDEX_OFFSET = 0x7FFFFFFFFF;

  /**
   * Bitmask to extract the water information from an index entry.
   */
  static final int BITMASK_INDEX_WATER = 0x8000000000;

  /**
   * Default start zoom level.
   */
  static final int DEFAULT_START_ZOOM_LEVEL = 12;

  /// Amount of cache blocks that the index cache should store.
  static final int INDEX_CACHE_SIZE = 256;

  /**
   * Error message for an invalid first way offset.
   */
  static final String INVALID_FIRST_WAY_OFFSET = "invalid first way offset: ";

  /**
   * Length of the debug signature at the beginning of each block.
   */
  static final int SIGNATURE_LENGTH_BLOCK = 32;

  /// for debugging purposes
  static final bool complete = true;

  late final IndexCache _databaseIndexCache;

  int _fileSize = 0;

  late final MapFileHeader _mapFileHeader;
  final int? timestamp;

  int zoomLevelMin = 0;
  int zoomLevelMax = 30;

  late final MapfileHelper _helper;

  /// just to see if we should create a cache for blocks
  //final Set<int> _blockSet = Set();

  // final StatisticsStorage<String, PoiWayBundle> _storage =
  //     StatisticsStorage<String, PoiWayBundle>();
  //
  // late LruCache<String, PoiWayBundle> _blockCache;

  ReadbufferSource? readBufferSource;

  static Future<MapFile> from(String filename, int? timestamp, String? language,
      {ReadbufferSource? source}) async {
    MapFile mapFile = MapFile._(timestamp, language);
    await mapFile._init(source != null ? source : ReadbufferFile(filename));
    return mapFile;
  }

  static Future<MapFile> using(Uint8List content, int? timestamp,
      String? language) async {
    assert(content.length > 0);
    MapFile mapFile = MapFile._(timestamp, language);
    await mapFile._initContent(content);
    return mapFile;
  }

  /// Opens the given map file channel, reads its header data and validates them.
  ///
  /// @param filename the filename of the mapfile.
  /// @param language       the language to use (may be null).
  /// @throws MapFileException if the given map file channel is null or invalid.
  MapFile._(this.timestamp, String? language) : super(language);

  Future<MapFile> _init(ReadbufferSource source) async {
    _databaseIndexCache = new IndexCache(INDEX_CACHE_SIZE);
    this.readBufferSource = source;
    _mapFileHeader = MapFileHeader();
    // we will send this structure to the isolate later on. Unfortunately we cannot send the io library status to the isolate so we need to close and nullify it for now.
    // readBufferSource!.close();
    // readBufferSource = null;
    _helper = MapfileHelper(_mapFileHeader, preferredLanguage);
    //await lateOpen();
    return this;
  }

  Future<MapFile> _initContent(Uint8List content) async {
    _databaseIndexCache = new IndexCache(INDEX_CACHE_SIZE);
    this.readBufferSource = ReadbufferMemory(content);
    _mapFileHeader = MapFileHeader();
    // we will send this structure to the isolate later on. Unfortunately we cannot send the io library status to the isolate so we need to close and nullify it for now.
    _helper = MapfileHelper(_mapFileHeader, preferredLanguage);
    return this;
  }

  @override
  String toString() {
    return 'MapFile{_fileSize: $_fileSize, _mapFileHeader: $_mapFileHeader, timestamp: $timestamp, zoomLevelMin: $zoomLevelMin, zoomLevelMax: $zoomLevelMax, readBufferSource: $readBufferSource}';
  }

  @mustCallSuper
  void dispose() {
    this._databaseIndexCache.dispose();
    readBufferSource?.close();
    readBufferSource = null;
  }

  @override
  BoundingBox get boundingBox {
    return getMapFileInfo().boundingBox;
  }

  /**
   * Returns the creation timestamp of the map file.
   *
   * @param tile not used, as all tiles will shared the same creation date.
   * @return the creation timestamp inside the map file.
   */
  @override
  int? getDataTimestamp(Tile tile) {
    return this.timestamp;
  }

  /**
   * @return the header data for the current map file.
   */
  MapFileHeader getMapFileHeader() {
    return this._mapFileHeader;
  }

  /**
   * @return the metadata for the current map file. Make sure [lateOpen] is
   * already executed
   */
  MapFileInfo getMapFileInfo() {
    return this._mapFileHeader.getMapFileInfo();
  }

  /**
   * @return the map file supported languages (may be null).
   */
  List<String>? getMapLanguages() {
    String? languagesPreference = getMapFileInfo().languagesPreference;
    if (languagesPreference != null && languagesPreference
        .trim()
        .isNotEmpty) {
      return languagesPreference.split(",");
    }
    return null;
  }

  PoiWayBundle _processBlock(QueryParameters queryParameters,
      SubFileParameter subFileParameter,
      BoundingBox boundingBox,
      double tileLatitude,
      double tileLongitude,
      MapfileSelector selector,
      Readbuffer readBuffer) {
    if (!_processBlockSignature(readBuffer)) {
      throw Exception("ProcessblockSignature mismatch");
    }

    List<List<int>> zoomTable = _readZoomTable(subFileParameter, readBuffer);
    int zoomTableRow =
        queryParameters.queryZoomLevel - subFileParameter.zoomLevelMin;
    int poisOnQueryZoomLevel = zoomTable[zoomTableRow][0];
    int waysOnQueryZoomLevel = zoomTable[zoomTableRow][1];

    // get the relative offset to the first stored way in the block
    int firstWayOffset = readBuffer.readUnsignedInt();
    if (firstWayOffset < 0) {
      throw Exception(INVALID_FIRST_WAY_OFFSET + "$firstWayOffset");
    }

    // add the current buffer position to the relative first way offset
    firstWayOffset += readBuffer.bufferPosition;
    if (firstWayOffset > readBuffer.getBufferSize()) {
      throw Exception(INVALID_FIRST_WAY_OFFSET + "$firstWayOffset");
    }

    bool filterRequired =
        queryParameters.queryZoomLevel > subFileParameter.baseZoomLevel;

    List<PointOfInterest> pois = _helper.processPOIs(
        tileLatitude,
        tileLongitude,
        poisOnQueryZoomLevel,
        boundingBox,
        filterRequired,
        readBuffer);

    List<Way>? ways;
    if (MapfileSelector.POIS == selector) {
      ways = [];
    } else {
      // finished reading POIs, check if the current buffer position is valid
      assert(readBuffer.getBufferPosition() <= firstWayOffset,
      "invalid buffer position: ${readBuffer.getBufferPosition()}");
      if (firstWayOffset == readBuffer.getBufferSize()) {
        // no ways in this block
        ways = [];
      } else {
        // move the pointer to the first way
        readBuffer.setBufferPosition(firstWayOffset);

        ways = _helper.processWays(
            queryParameters,
            waysOnQueryZoomLevel,
            boundingBox,
            filterRequired,
            tileLatitude,
            tileLongitude,
            selector,
            readBuffer);
      }
    }

    return new PoiWayBundle(pois, ways);
  }

  /**
   * Processes the block signature, if present.
   *
   * @return true if the block signature could be processed successfully, false otherwise.
   */
  bool _processBlockSignature(Readbuffer readBuffer) {
    if (this._mapFileHeader
        .getMapFileInfo()
        .debugFile) {
      // get and check the block signature
      String signatureBlock =
      readBuffer.readUTF8EncodedString2(SIGNATURE_LENGTH_BLOCK);
      if (!signatureBlock.startsWith("###TileStart")) {
        _log.warning("invalid block signature: " + signatureBlock);
        return false;
      }
    }
    return true;
  }

  ///
  /// don't make this method private since we are using it in the example APP to analyze mapfiles
  ///
  Future<DatastoreReadResult> processBlocks(ReadbufferSource readBufferSource,
      QueryParameters queryParameters,
      SubFileParameter subFileParameter,
      BoundingBox boundingBox,
      MapfileSelector selector) async {
    bool queryIsWater = true;
    bool queryReadWaterInfo = false;
    Projection projection =
    MercatorProjection.fromZoomlevel(subFileParameter.baseZoomLevel);

    DatastoreReadResult mapFileReadResult =
    new DatastoreReadResult(pointOfInterests: [], ways: []);

    // read and process all blocks from top to bottom and from left to right
    for (int row = queryParameters.fromBlockY;
    row <= queryParameters.toBlockY;
    ++row) {
      for (int column = queryParameters.fromBlockX;
      column <= queryParameters.toBlockX;
      ++column) {
        // calculate the actual block number of the needed block in the file
        int blockNumber = row * subFileParameter.blocksWidth + column;
        // String cacheKey = "$blockNumber-${queryParameters.queryZoomLevel}";
        // PoiWayBundle? bundle = _blockCache.get(cacheKey);
        // if (bundle != null) {
        //   mapFileReadResult.add(bundle);
        //   print(
        //       "from cache: $row/$column/${queryParameters.queryZoomLevel}-${subFileParameter.id} ${subFileParameter.zoomLevelMax}");
        //   continue;
        // }

        // get the current index entry
        int currentBlockIndexEntry = await this
            ._databaseIndexCache
            .getIndexEntry(subFileParameter, blockNumber, readBufferSource);

        // check if the current query would still return a water tile
        if (queryIsWater) {
          // check the water flag of the current block in its index entry
          queryIsWater &= (currentBlockIndexEntry & BITMASK_INDEX_WATER) != 0;
          queryReadWaterInfo = true;
        }

        // get and check the current block pointer
        int currentBlockPointer = currentBlockIndexEntry & BITMASK_INDEX_OFFSET;
        if (currentBlockPointer < 1 ||
            currentBlockPointer > subFileParameter.subFileSize!) {
          _log.warning("invalid current block pointer: $currentBlockPointer");
          _log.warning("subFileSize: ${subFileParameter.subFileSize}");
          return mapFileReadResult;
        }

        int? nextBlockPointer;
        // check if the current block is the last block in the file
        if (blockNumber + 1 == subFileParameter.numberOfBlocks) {
          // set the next block pointer to the end of the file
          nextBlockPointer = subFileParameter.subFileSize;
        } else {
          // get and check the next block pointer
          nextBlockPointer = (await this._databaseIndexCache.getIndexEntry(
              subFileParameter, blockNumber + 1, readBufferSource)) &
          BITMASK_INDEX_OFFSET;
          if (nextBlockPointer > subFileParameter.subFileSize!) {
            _log.warning("invalid next block pointer: $nextBlockPointer");
            _log.warning("sub-file size: ${subFileParameter.subFileSize}");
            return mapFileReadResult;
          }
        }

        // calculate the size of the current block
        int currentBlockSize = (nextBlockPointer! - currentBlockPointer);
        if (currentBlockSize < 0) {
          _log.warning(
              "current block size must not be negative: $currentBlockSize");
          return mapFileReadResult;
        } else if (currentBlockSize == 0) {
          // the current block is empty, continue with the next block
          continue;
        } else if (currentBlockSize > Parameters.MAXIMUM_BUFFER_SIZE) {
          // the current block is too large, continue with the next block
          _log.warning("current block size too large: $currentBlockSize");
          continue;
        } else if (currentBlockPointer + currentBlockSize > this._fileSize) {
          _log.warning(
              "current block larger than file size: $currentBlockSize");
          return mapFileReadResult;
        }

        // _log.info(
        //     "Processing block $row/$column from currentBlockPointer ${subFileParameter.startAddress + currentBlockPointer} to nextBlockPointer ${subFileParameter.startAddress + nextBlockPointer} ($currentBlockSize byte)");

        // seek to the current block in the map file
        // read the current block into the buffer
        //ReadBuffer readBuffer = new ReadBuffer(inputChannel);
        Readbuffer readBuffer = await readBufferSource.readFromFile(
            length: currentBlockSize,
            offset: subFileParameter.startAddress + currentBlockPointer);

        // calculate the top-left coordinates of the underlying tile
        double tileLatitude = projection
            .tileYToLatitude((subFileParameter.boundaryTileTop + row));
        double tileLongitude = projection
            .tileXToLongitude((subFileParameter.boundaryTileLeft + column));

        PoiWayBundle poiWayBundle = _processBlock(
            queryParameters,
            subFileParameter,
            boundingBox,
            tileLatitude,
            tileLongitude,
            selector,
            readBuffer);
        //_blockCache.set(cacheKey, poiWayBundle);
        mapFileReadResult.add(poiWayBundle);
      }
    }

    // the query is finished, was the water flag set for all blocks?
    if (queryIsWater && queryReadWaterInfo) {
      // Deprecate water tiles rendering
      mapFileReadResult.isWater = true;
    }

    return mapFileReadResult;
  }

  /// Reads only labels for tile.
  ///
  /// @param tile tile for which data is requested.
  /// @return label data for the tile.
  @override
  Future<DatastoreReadResult> readLabelsSingle(Tile tile) async {
    return _readMapDataComplete(tile, tile, MapfileSelector.LABELS);
  }

  /// Reads data for an area defined by the tile in the upper left and the tile in
  /// the lower right corner.
  /// Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
  ///
  /// @param upperLeft  tile that defines the upper left corner of the requested area.
  /// @param lowerRight tile that defines the lower right corner of the requested area.
  /// @return map data for the tile.
  @override
  Future<DatastoreReadResult> readLabels(Tile upperLeft,
      Tile lowerRight) async {
    return _readMapDataComplete(upperLeft, lowerRight, MapfileSelector.LABELS);
  }

  /// Reads all map data for the area covered by the given tile at the tile zoom level.
  ///
  /// @param tile defines area and zoom level of read map data.
  /// @return the read map data.
  @override
  Future<DatastoreReadResult> readMapDataSingle(Tile tile) async {
    DatastoreReadResult result =
    await _readMapDataComplete(tile, tile, MapfileSelector.ALL);
    //print("$_storage");
    return result;
  }

  /// Reads data for an area defined by the tile in the upper left and the tile in
  /// the lower right corner.
  /// Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
  ///
  /// @param upperLeft  tile that defines the upper left corner of the requested area.
  /// @param lowerRight tile that defines the lower right corner of the requested area.
  /// @return map data for the tile.
  @override
  Future<DatastoreReadResult> readMapData(Tile upperLeft,
      Tile lowerRight) async {
    return _readMapDataComplete(upperLeft, lowerRight, MapfileSelector.ALL);
  }

  @override
  Future<void> lateOpen() async {
    // late reading of header. Necessary for isolates because we cannot transfer a non-null RandomAccessFile descriptor to the isolate.
    this._fileSize = await readBufferSource!.length();
    assert(_fileSize > 0);
    await this._mapFileHeader.readHeader(readBufferSource!, this._fileSize);
  }

  Future<DatastoreReadResult> _readMapDataComplete(Tile upperLeft,
      Tile lowerRight, MapfileSelector selector) async {
    await lateOpen();
    Projection projection =
    MercatorProjection.fromZoomlevel(upperLeft.zoomLevel);
    assert(supportsTile(upperLeft, projection));
    assert(supportsTile(lowerRight, projection));
    assert(upperLeft.zoomLevel == lowerRight.zoomLevel);
    int timer = DateTime
        .now()
        .millisecondsSinceEpoch;
    if (upperLeft.tileX > lowerRight.tileX ||
        upperLeft.tileY > lowerRight.tileY) {
      throw Exception(
          "upperLeft tile must be above and left of lowerRight tile");
    }

    QueryParameters queryParameters = new QueryParameters();
    queryParameters.queryZoomLevel =
        this._mapFileHeader.getQueryZoomLevel(upperLeft.zoomLevel);

    // get and check the sub-file for the query zoom level
    SubFileParameter? subFileParameter =
    this._mapFileHeader.getSubFileParameter(queryParameters.queryZoomLevel);
    if (subFileParameter == null) {
      throw Exception(
          "no sub-file for zoom level: ${queryParameters.queryZoomLevel}");
    }

    queryParameters.calculateBaseTiles(upperLeft, lowerRight, subFileParameter);
    queryParameters.calculateBlocks(subFileParameter);
    int diff = DateTime
        .now()
        .millisecondsSinceEpoch - timer;
    if (diff > 100)
      _log.info(
          "  readMapDataComplete took $diff ms up to create query $queryParameters");

    DatastoreReadResult? result = await processBlocks(
        readBufferSource!,
        queryParameters,
        subFileParameter,
        projection.boundingBoxOfTiles(upperLeft, lowerRight),
        selector);
    diff = DateTime
        .now()
        .millisecondsSinceEpoch - timer;
    if (diff > 100)
      _log.info("readMapDataComplete took $diff ms for $queryParameters");
    //readBufferMaster.close();
    return result;
  }

  /**
   * Reads only POI data for tile.
   *
   * @param tile tile for which data is requested.
   * @return POI data for the tile.
   */
  @override
  Future<DatastoreReadResult?> readPoiDataSingle(Tile tile) async {
    return _readMapDataComplete(tile, tile, MapfileSelector.POIS);
  }

  /**
   * Reads POI data for an area defined by the tile in the upper left and the tile in
   * the lower right corner.
   * This implementation takes the data storage of a MapFile into account for greater efficiency.
   *
   * @param upperLeft  tile that defines the upper left corner of the requested area.
   * @param lowerRight tile that defines the lower right corner of the requested area.
   * @return map data for the tile.
   */
  @override
  Future<DatastoreReadResult?> readPoiData(Tile upperLeft,
      Tile lowerRight) async {
    return _readMapDataComplete(upperLeft, lowerRight, MapfileSelector.POIS);
  }

  List<List<int>> _readZoomTable(SubFileParameter subFileParameter,
      Readbuffer readBuffer) {
    int rows =
        subFileParameter.zoomLevelMax - subFileParameter.zoomLevelMin + 1;
    List<List<int>> zoomTable = [];

    int cumulatedNumberOfPois = 0;
    int cumulatedNumberOfWays = 0;

    for (int row = 0; row < rows; ++row) {
      cumulatedNumberOfPois += readBuffer.readUnsignedInt();
      cumulatedNumberOfWays += readBuffer.readUnsignedInt();
      List<int> inner = [];
      inner.add(cumulatedNumberOfPois);
      inner.add(cumulatedNumberOfWays);
      zoomTable.add(inner);
    }

    return zoomTable;
  }

  /**
   * Restricts returns of data to zoom level range specified. This can be used to restrict
   * the use of this map data base when used in MultiMapDatabase settings.
   *
   * @param minZoom minimum zoom level supported
   * @param maxZoom maximum zoom level supported
   */
  void restrictToZoomRange(int minZoom, int maxZoom) {
    this.zoomLevelMax = maxZoom;
    this.zoomLevelMin = minZoom;
  }

  @override
  LatLong? get startPosition {
    if (null != getMapFileInfo().startPosition) {
      return getMapFileInfo().startPosition;
    }
    return getMapFileInfo().boundingBox.getCenterPoint();
  }

  @override
  int? get startZoomLevel {
    if (null != getMapFileInfo().startZoomLevel) {
      return getMapFileInfo().startZoomLevel;
    }
    return DEFAULT_START_ZOOM_LEVEL;
  }

  @override
  bool supportsTile(Tile tile, Projection projection) {
    if (tile.zoomLevel < zoomLevelMin || tile.zoomLevel > zoomLevelMax)
      return false;
    return tile
        .getBoundingBox(projection)
        .intersects(getMapFileInfo().boundingBox);
  }
}

/////////////////////////////////////////////////////////////////////////////

/// The Selector enum is used to specify which data subset is to be retrieved from a MapFile:
enum MapfileSelector {
  /// ALL: all data (as in version 0.6.0)
  ALL,

  /// POIS: only poi data, no ways (new after 0.6.0)
  POIS,

  /// LABELS: poi data and ways that have a name (new after 0.6.0)
  LABELS
}
