import 'dart:typed_data';

import 'package:ecache/ecache.dart';
import 'package:flutter/cupertino.dart';
import 'package:isolate_task_queue/isolate_task_queue.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfile_helper.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfile_info_builder.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/mapfile/readbufferfile.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffermemory.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';
import 'package:mapsforge_flutter/src/mapfile/subfileparameter.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';
import 'package:mapsforge_flutter/src/parameters.dart';
import 'package:mapsforge_flutter/src/projection/projection.dart';

import '../../datastore.dart';
import '../datastore/poiwaybundle.dart';
import '../projection/mercatorprojection.dart';
import '../reader/queryparameters.dart';
import '../utils/timing.dart';
import 'indexcache.dart';
import 'mapfile_info.dart';

@pragma("vm:entry-point")
class IsolateMapfile implements Datastore {
  /// The instance of the mapfile in the isolate
  static MapFile? mapFile;

  /// The parameter needed to create a mapfile in the isolate
  static late final String filename;

  static late final String? preferredLanguage;

  /// a long-running instance of an isolate
  late final FlutterIsolateInstance _isolateInstance;

  IsolateMapfile._();

  static Future<IsolateMapfile> create(String filename, [String? preferredLanguage]) async {
    IsolateMapfile _instance = IsolateMapfile._();
    _instance._isolateInstance = await FlutterIsolateInstance.createInstance(
        createInstance: _createInstanceStatic, instanceParams: _MapfileInstanceRequest(filename, preferredLanguage));
    return _instance;
  }

  @override
  void dispose() {
    _isolateInstance.dispose();
  }

  @pragma('vm:entry-point')
  static void _createInstanceStatic(Object request) {
    filename = (request as _MapfileInstanceRequest).filename;
    preferredLanguage = request.preferredLanguage;
  }

  @override
  Future<DatastoreReadResult?> readLabels(Tile upperLeft, Tile lowerRight) {
    // TODO: implement readLabels
    throw UnimplementedError();
  }

  @override
  Future<DatastoreReadResult?> readLabelsSingle(Tile tile) async {
    DatastoreReadResult? result = await _isolateInstance.compute(_readLabelsSingleStatic, _MapfileReadSingleRequest(tile));
    return result;
  }

  @pragma('vm:entry-point')
  static Future<DatastoreReadResult?> _readLabelsSingleStatic(_MapfileReadSingleRequest request) async {
    mapFile ??= await MapFile.from(filename, 0, preferredLanguage);
    return mapFile!.readLabelsSingle(request.tile);
  }

  @override
  Future<DatastoreReadResult> readMapData(Tile upperLeft, Tile lowerRight) {
    // TODO: implement readMapData
    throw UnimplementedError();
  }

  @override
  Future<DatastoreReadResult?> readMapDataSingle(Tile tile) async {
    DatastoreReadResult? result = await _isolateInstance.compute(_readMapDataSingleStatic, _MapfileReadSingleRequest(tile));
    return result;
  }

  @pragma('vm:entry-point')
  static Future<DatastoreReadResult?> _readMapDataSingleStatic(_MapfileReadSingleRequest request) async {
    mapFile ??= await MapFile.from(filename, 0, preferredLanguage);
    return mapFile!.readMapDataSingle(request.tile);
  }

  @override
  Future<DatastoreReadResult?> readPoiData(Tile upperLeft, Tile lowerRight) {
    // TODO: implement readPoiData
    throw UnimplementedError();
  }

  @override
  Future<DatastoreReadResult?> readPoiDataSingle(Tile tile) {
    // TODO: implement readPoiDataSingle
    throw UnimplementedError();
  }

  @override
  Future<bool> supportsTile(Tile tile) async {
    bool result = await _isolateInstance.compute(_supportsTileStatic, _MapfileSupportsTileRequest(tile));
    return result;
  }

  @pragma('vm:entry-point')
  static Future<bool> _supportsTileStatic(_MapfileSupportsTileRequest request) async {
    mapFile ??= await MapFile.from(filename, 0, preferredLanguage);
    return mapFile!.supportsTile(request.tile);
  }

  @override
  Future<BoundingBox> getBoundingBox() async {
    BoundingBox result = await _isolateInstance.compute(_getBoundingBoxStatic, _MapfileBoundingBoxRequest());
    return result;
  }

  @pragma('vm:entry-point')
  static Future<BoundingBox> _getBoundingBoxStatic(_MapfileBoundingBoxRequest request) async {
    mapFile ??= await MapFile.from(filename, 0, preferredLanguage);
    return mapFile!.getBoundingBox();
  }
}

//////////////////////////////////////////////////////////////////////////////

class _MapfileInstanceRequest {
  final String filename;

  final String? preferredLanguage;

  _MapfileInstanceRequest(this.filename, this.preferredLanguage);
}

//////////////////////////////////////////////////////////////////////////////

class _MapfileBoundingBoxRequest {
  _MapfileBoundingBoxRequest();
}

//////////////////////////////////////////////////////////////////////////////

class _MapfileReadSingleRequest {
  final Tile tile;

  _MapfileReadSingleRequest(this.tile);
}

//////////////////////////////////////////////////////////////////////////////

class _MapfileSupportsTileRequest {
  final Tile tile;

  _MapfileSupportsTileRequest(this.tile);
}

//////////////////////////////////////////////////////////////////////////////

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

  int _fileSize = -1;

  final int? timestamp;

  ZoomlevelRange zoomlevelRange = const ZoomlevelRange.standard();

  late final MapfileInfo _mapFileInfo;

  late final MapfileHelper _helper;

  final TaskQueue _queue = SimpleTaskQueue();

  late final ReadbufferSource readBufferSource;

  Cache<String, Readbuffer> _cache = LfuCache(storage: StatisticsStorage(), capacity: 100);

  static Future<MapFile> from(String filename, int? timestamp, String? language, {ReadbufferSource? source}) async {
    MapFile mapFile = MapFile._(timestamp, language);
    await mapFile._init(source != null ? source : ReadbufferFile(filename));
    return mapFile;
  }

  static Future<MapFile> using(Uint8List content, int? timestamp, String? language) async {
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
  MapFile._(this.timestamp, String? language) : super((language?.trim().toLowerCase().isEmpty ?? true) ? null : language?.trim().toLowerCase());

  Future<MapFile> _init(ReadbufferSource source) async {
    _databaseIndexCache = new IndexCache(INDEX_CACHE_SIZE);
    this.readBufferSource = source;
    return this;
  }

  Future<MapFile> _initContent(Uint8List content) async {
    _databaseIndexCache = new IndexCache(INDEX_CACHE_SIZE);
    this.readBufferSource = ReadbufferMemory(content);
    return this;
  }

  @override
  String toString() {
    return 'MapFile{_fileSize: $_fileSize, _mapFileHeader: $_mapFileInfo, timestamp: $timestamp, zoomlevelRange: $zoomlevelRange, readBufferSource: $readBufferSource}';
  }

  @override
  @mustCallSuper
  void dispose() {
    this._databaseIndexCache.dispose();
    readBufferSource.dispose();
  }

  /**
   * Returns the creation timestamp of the map file.
   *
   * @param tile not used, as all tiles will shared the same creation date.
   * @return the creation timestamp inside the map file.
   */
  @override
  Future<int?> getDataTimestamp(Tile tile) {
    return Future.value(this.timestamp);
  }

  /**
   * @return the header data for the current map file.
   */
  MapfileInfo getMapFileInfo() {
    return this._mapFileInfo;
  }

  /**
   * @return the metadata for the current map file. Make sure [lateOpen] is
   * already executed
   */
  MapHeaderInfo getMapHeaderInfo() {
    return this._mapFileInfo.getMapHeaderInfo();
  }

  /**
   * @return the map file supported languages (may be null).
   */
  List<String>? getMapLanguages() {
    String? languagesPreference = getMapHeaderInfo().languagesPreference;
    if (languagesPreference != null && languagesPreference.trim().isNotEmpty) {
      return languagesPreference.split(",");
    }
    return null;
  }

  PoiWayBundle _processBlock(QueryParameters queryParameters, SubFileParameter subFileParameter, BoundingBox boundingBox, double tileLatitude,
      double tileLongitude, MapfileSelector selector, Readbuffer readBuffer) {
    if (!_processBlockSignature(readBuffer)) {
      throw Exception("ProcessblockSignature mismatch");
    }

    List<List<int>> zoomTable = _readZoomTable(subFileParameter, readBuffer);
    int zoomTableRow = queryParameters.queryZoomLevel - subFileParameter.zoomLevelMin;
    int poisOnQueryZoomLevel = zoomTable[zoomTableRow][0];
    int waysOnQueryZoomLevel = zoomTable[zoomTableRow][1];

    // get the relative offset to the first stored way in the block
    int firstWayOffset = readBuffer.readUnsignedInt();
    if (firstWayOffset < 0) {
      throw Exception(INVALID_FIRST_WAY_OFFSET + "$firstWayOffset");
    }

    // add the current buffer position to the relative first way offset
    firstWayOffset += readBuffer.getBufferPosition();
    if (firstWayOffset > readBuffer.getBufferSize()) {
      throw Exception(INVALID_FIRST_WAY_OFFSET + "$firstWayOffset");
    }

    bool filterRequired = queryParameters.queryZoomLevel > subFileParameter.baseZoomLevel;

    List<PointOfInterest> pois = _helper.processPOIs(tileLatitude, tileLongitude, poisOnQueryZoomLevel, boundingBox, filterRequired, readBuffer, this);

    List<Way>? ways;
    if (MapfileSelector.POIS == selector) {
      ways = [];
    } else {
      // finished reading POIs, check if the current buffer position is valid
      assert(readBuffer.getBufferPosition() <= firstWayOffset, "invalid buffer position: ${readBuffer.getBufferPosition()}");
      if (firstWayOffset == readBuffer.getBufferSize()) {
        // no ways in this block
        ways = [];
      } else {
        // move the pointer to the first way
        readBuffer.setBufferPosition(firstWayOffset);

        ways = _helper.processWays(queryParameters, waysOnQueryZoomLevel, boundingBox, filterRequired, tileLatitude, tileLongitude, selector, readBuffer, this);
      }
    }

    return new PoiWayBundle(pois, ways);
  }

  /// Processes the block signature, if present.
  ///
  /// @return true if the block signature could be processed successfully, false otherwise.
  bool _processBlockSignature(Readbuffer readBuffer) {
    if (this._mapFileInfo.getMapHeaderInfo().debugFile) {
      // get and check the block signature
      String signatureBlock = readBuffer.readUTF8EncodedString2(SIGNATURE_LENGTH_BLOCK);
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
  Future<DatastoreReadResult> processBlocks(ReadbufferSource readBufferSource, QueryParameters queryParameters, SubFileParameter subFileParameter,
      BoundingBox boundingBox, MapfileSelector selector) async {
    bool queryIsWater = true;
    bool queryReadWaterInfo = false;

    DatastoreReadResult mapFileReadResult = new DatastoreReadResult(pointOfInterests: [], ways: []);

    // read and process all blocks from top to bottom and from left to right
    for (int row = queryParameters.fromBlockY; row <= queryParameters.toBlockY; ++row) {
      for (int column = queryParameters.fromBlockX; column <= queryParameters.toBlockX; ++column) {
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
        int currentBlockIndexEntry = await this._databaseIndexCache.getIndexEntry(subFileParameter, blockNumber, readBufferSource);

        // check if the current query would still return a water tile
        if (queryIsWater) {
          // check the water flag of the current block in its index entry
          queryIsWater &= (currentBlockIndexEntry & BITMASK_INDEX_WATER) != 0;
          queryReadWaterInfo = true;
        }

        // get and check the current block pointer
        int currentBlockPointer = currentBlockIndexEntry & BITMASK_INDEX_OFFSET;
        if (currentBlockPointer < 1 || currentBlockPointer > subFileParameter.subFileSize) {
          _log.warning(
              "invalid current block pointer: 0x${currentBlockPointer.toRadixString(16)} with subFileSize: 0x${subFileParameter.subFileSize.toRadixString(16)} for blocknumber $blockNumber");
          return mapFileReadResult;
        }

        int? nextBlockPointer;
        // check if the current block is the last block in the file
        if (blockNumber + 1 == subFileParameter.numberOfBlocks) {
          // set the next block pointer to the end of the file
          nextBlockPointer = subFileParameter.subFileSize;
        } else {
          // get and check the next block pointer
          nextBlockPointer = (await this._databaseIndexCache.getIndexEntry(subFileParameter, blockNumber + 1, readBufferSource)) & BITMASK_INDEX_OFFSET;
          if (nextBlockPointer > subFileParameter.subFileSize) {
            _log.warning("invalid next block pointer: $nextBlockPointer");
            _log.warning("sub-file size: ${subFileParameter.subFileSize}");
            return mapFileReadResult;
          }
        }

        // calculate the size of the current block
        int currentBlockSize = (nextBlockPointer - currentBlockPointer);
        if (currentBlockSize < 0) {
          _log.warning("current block size must not be negative: $currentBlockSize");
          return mapFileReadResult;
        } else if (currentBlockSize == 0) {
          // the current block is empty, continue with the next block
          continue;
        } else if (currentBlockSize > Parameters.MAXIMUM_BUFFER_SIZE) {
          // the current block is too large, continue with the next block
          _log.warning("current block size too large: $currentBlockSize");
          continue;
        } else if (currentBlockPointer + currentBlockSize > this._fileSize) {
          _log.warning("current block larger than file size: $currentBlockSize");
          return mapFileReadResult;
        }

        String key = "${subFileParameter.startAddress + currentBlockPointer}-$currentBlockSize";
        Readbuffer readbuffer = await _cache.getOrProduce(key, (key) async {
          Readbuffer readBuffer = await readBufferSource.readFromFileAt(subFileParameter.startAddress + currentBlockPointer, currentBlockSize);
          return readBuffer;
        });

        // calculate the top-left coordinates of the underlying tile
        double tileLatitude = subFileParameter.projection.tileYToLatitude((subFileParameter.boundaryTileTop + row));
        double tileLongitude = subFileParameter.projection.tileXToLongitude((subFileParameter.boundaryTileLeft + column));

        PoiWayBundle poiWayBundle =
            _processBlock(queryParameters, subFileParameter, boundingBox, tileLatitude, tileLongitude, selector, Readbuffer.from(readbuffer));
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
    await _lateOpen();
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
  Future<DatastoreReadResult> readLabels(Tile upperLeft, Tile lowerRight) async {
    await _lateOpen();
    return _readMapDataComplete(upperLeft, lowerRight, MapfileSelector.LABELS);
  }

  /// Reads all map data for the area covered by the given tile at the tile zoom level.
  ///
  /// @param tile defines area and zoom level of read map data.
  /// @return the read map data.
  @override
  Future<DatastoreReadResult> readMapDataSingle(Tile tile) async {
    await _lateOpen();
    DatastoreReadResult result = await _readMapDataComplete(tile, tile, MapfileSelector.ALL);
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
  Future<DatastoreReadResult> readMapData(Tile upperLeft, Tile lowerRight) async {
    await _lateOpen();
    return _readMapDataComplete(upperLeft, lowerRight, MapfileSelector.ALL);
  }

  Future<void> _lateOpen() async {
    if (_fileSize > 0) return;
    return _queue.add(() async {
      if (_fileSize > 0) return;
      // late reading of header. Necessary for isolates because we cannot transfer a non-null RandomAccessFile descriptor to the isolate.
      int fileSize = await readBufferSource.length();
      assert(fileSize > 0);
      MapfileInfoBuilder mapfileInfoBuilder = MapfileInfoBuilder();
      await mapfileInfoBuilder.readHeader(readBufferSource, fileSize);
      this._mapFileInfo = mapfileInfoBuilder.build();
      _helper = MapfileHelper(_mapFileInfo, preferredLanguage);
      zoomlevelRange = _mapFileInfo.zoomlevelRange;
      this._fileSize = fileSize;
    });
  }

  Future<DatastoreReadResult> _readMapDataComplete(Tile upperLeft, Tile lowerRight, MapfileSelector selector) async {
    Projection projection = MercatorProjection.fromZoomlevel(upperLeft.zoomLevel);
    // may happen that upperLeft and lowerRight does not support the tiles but inbetween do
    //assert(supportsTile(upperLeft, projection));
    //assert(supportsTile(lowerRight, projection));
    assert(upperLeft.zoomLevel == lowerRight.zoomLevel);
    Timing timing = Timing(log: _log, active: true, prefix: "${upperLeft}-${lowerRight} ");
    if (upperLeft.tileX > lowerRight.tileX || upperLeft.tileY > lowerRight.tileY) {
      throw Exception("upperLeft tile must be above and left of lowerRight tile");
    }
    QueryParameters queryParameters = new QueryParameters();
    queryParameters.queryZoomLevel = this._mapFileInfo.getQueryZoomLevel(upperLeft.zoomLevel);

    // get and check the sub-file for the query zoom level
    SubFileParameter? subFileParameter = this._mapFileInfo.getSubFileParameter(queryParameters.queryZoomLevel);
    if (subFileParameter == null) {
      throw Exception("no sub-file for zoom level: ${queryParameters.queryZoomLevel}");
    }
    queryParameters.calculateBaseTiles(upperLeft, lowerRight, subFileParameter);
    queryParameters.calculateBlocks(subFileParameter);
    timing.lap(100, "readMapDataComplete for query $queryParameters");
    DatastoreReadResult? result =
        await processBlocks(readBufferSource, queryParameters, subFileParameter, projection.boundingBoxOfTiles(upperLeft, lowerRight), selector);
    timing.done(100, "readMapDataComplete for $queryParameters");
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
    await _lateOpen();
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
  Future<DatastoreReadResult?> readPoiData(Tile upperLeft, Tile lowerRight) async {
    await _lateOpen();
    return _readMapDataComplete(upperLeft, lowerRight, MapfileSelector.POIS);
  }

  List<List<int>> _readZoomTable(SubFileParameter subFileParameter, Readbuffer readBuffer) {
    int rows = subFileParameter.zoomLevelMax - subFileParameter.zoomLevelMin + 1;
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
    this.zoomlevelRange = ZoomlevelRange(minZoom, maxZoom);
  }

  /**
   * @return the default start position for the current map file. Make sure [lateOpen] is
   * already executed
   */
  @override
  Future<LatLong?> getStartPosition() async {
    await _lateOpen();
    if (null != getMapHeaderInfo().startPosition) {
      return getMapHeaderInfo().startPosition;
    }
    return getMapHeaderInfo().boundingBox.getCenterPoint();
  }

  @override
  Future<int?> getStartZoomLevel() async {
    await _lateOpen();
    if (null != getMapHeaderInfo().startZoomLevel) {
      return getMapHeaderInfo().startZoomLevel;
    }
    return DEFAULT_START_ZOOM_LEVEL;
  }

  @override
  Future<bool> supportsTile(Tile tile) async {
    await _lateOpen();
    if (!zoomlevelRange.matches(tile.zoomLevel)) return false;
    return tile.getBoundingBox().intersects(getMapHeaderInfo().boundingBox);
  }

  @override
  Future<BoundingBox> getBoundingBox() async {
    await _lateOpen();
    return getMapHeaderInfo().boundingBox;
  }

  /// For debugging purposes only
  //@visibleForTesting
  MapfileHelper getMapfileHelper() {
    return _helper;
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
