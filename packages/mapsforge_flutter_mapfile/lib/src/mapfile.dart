import 'dart:typed_data';

import 'package:ecache/ecache.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/dart_isolate.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/task_queue.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_debug.dart';
import 'package:mapsforge_flutter_mapfile/src/cache/index_cache.dart';
import 'package:mapsforge_flutter_mapfile/src/exceptions/mapfile_exception.dart';
import 'package:mapsforge_flutter_mapfile/src/helper/mapfile_helper.dart';
import 'package:mapsforge_flutter_mapfile/src/map_datastore.dart';
import 'package:mapsforge_flutter_mapfile/src/model/mapfile_info.dart';
import 'package:mapsforge_flutter_mapfile/src/reader/mapfile_info_builder.dart';

/// An implementation of `Datastore` that runs a `Mapfile` instance in a separate
/// isolate.
///
/// This is crucial for performance, as it offloads the heavy file I/O and parsing
/// operations from the main UI thread, preventing jank and keeping the application
/// responsive. It communicates with the `Mapfile` isolate using message passing.
@pragma("vm:entry-point")
class IsolateMapfile implements Datastore {
  /// The instance of the mapfile in the isolate
  static Mapfile? mapFile;

  /// The parameter needed to create a mapfile in the isolate
  static late final String filename;

  static late final String? preferredLanguage;

  /// a long-running instance of an isolate
  late final FlutterIsolateInstance _isolateInstance = FlutterIsolateInstance();

  IsolateMapfile._();

  /// Creates a new `IsolateMapfile` instance.
  ///
  /// This will spawn a new isolate and initialize a `Mapfile` within it using
  /// the provided [filename] and [preferredLanguage].
  static Future<IsolateMapfile> createFromFile({required String filename, String? preferredLanguage}) async {
    IsolateMapfile instance = IsolateMapfile._();
    await instance._isolateInstance.spawn(_createInstanceStatic, _MapfileInstanceRequest(filename, preferredLanguage));
    return instance;
  }

  @override
  void dispose() {
    _isolateInstance.dispose();
  }

  @pragma('vm:entry-point')
  static Future<void> _createInstanceStatic(IsolateInitInstanceParams request) async {
    filename = (request.initObject as _MapfileInstanceRequest).filename;
    preferredLanguage = request.initObject.preferredLanguage;
    mapFile ??= await Mapfile.createFromFile(filename: filename, preferredLanguage: preferredLanguage);
    await FlutterIsolateInstance.isolateInit(request, _acceptRequestsStatic);
  }

  @pragma('vm:entry-point')
  static Future _acceptRequestsStatic(Object request) async {
    if (request is _MapfileReadSingleRequest) return mapFile!.readLabelsSingle(request.tile);
    if (request is _MapfileReadRequest) return mapFile!.readLabels(request.upperLeft, request.lowerRight);
    if (request is _MapfileReadDataSingleRequest) return mapFile!.readMapDataSingle(request.tile);
    if (request is _MapfileSupportsTileRequest) return mapFile!.supportsTile(request.tile);
    if (request is _MapfileBoundingBoxRequest) return mapFile!.getBoundingBox();
  }

  @override
  Future<DatastoreBundle?> readLabels(Tile upperLeft, Tile lowerRight) async {
    DatastoreBundle? result = await _isolateInstance.compute(_MapfileReadRequest(upperLeft, lowerRight));
    return result;
  }

  @override
  Future<DatastoreBundle?> readLabelsSingle(Tile tile) async {
    DatastoreBundle? result = await _isolateInstance.compute(_MapfileReadSingleRequest(tile));
    return result;
  }

  @override
  Future<DatastoreBundle> readMapData(Tile upperLeft, Tile lowerRight) {
    // TODO: implement readMapData
    throw UnimplementedError();
  }

  @override
  Future<DatastoreBundle?> readMapDataSingle(Tile tile) async {
    DatastoreBundle? result = await _isolateInstance.compute(_MapfileReadDataSingleRequest(tile));
    return result;
  }

  @override
  Future<DatastoreBundle?> readPoiData(Tile upperLeft, Tile lowerRight) {
    // TODO: implement readPoiData
    throw UnimplementedError();
  }

  @override
  Future<DatastoreBundle?> readPoiDataSingle(Tile tile) {
    // TODO: implement readPoiDataSingle
    throw UnimplementedError();
  }

  @override
  Future<bool> supportsTile(Tile tile) async {
    bool result = await _isolateInstance.compute(_MapfileSupportsTileRequest(tile));
    return result;
  }

  @override
  Future<BoundingBox> getBoundingBox() async {
    BoundingBox result = await _isolateInstance.compute(_MapfileBoundingBoxRequest());
    return result;
  }
}

//////////////////////////////////////////////////////////////////////////////

/// A message to initialize the Mapfile instance in the isolate.
class _MapfileInstanceRequest {
  final String filename;

  final String? preferredLanguage;

  _MapfileInstanceRequest(this.filename, this.preferredLanguage);
}

//////////////////////////////////////////////////////////////////////////////

/// A message to request the bounding box from the Mapfile instance.
class _MapfileBoundingBoxRequest {
  _MapfileBoundingBoxRequest();
}

//////////////////////////////////////////////////////////////////////////////

/// A message to request label data for a single tile.
class _MapfileReadSingleRequest {
  final Tile tile;

  _MapfileReadSingleRequest(this.tile);
}

//////////////////////////////////////////////////////////////////////////////

/// A message to request map data for a single tile.
class _MapfileReadDataSingleRequest {
  final Tile tile;

  _MapfileReadDataSingleRequest(this.tile);
}

//////////////////////////////////////////////////////////////////////////////

/// A message to request label data for a tile range.
class _MapfileReadRequest {
  final Tile upperLeft;

  final Tile lowerRight;

  _MapfileReadRequest(this.upperLeft, this.lowerRight);
}

//////////////////////////////////////////////////////////////////////////////

/// A message to check if a tile is supported by the Mapfile.
class _MapfileSupportsTileRequest {
  final Tile tile;

  _MapfileSupportsTileRequest(this.tile);
}

//////////////////////////////////////////////////////////////////////////////

/// The main class for reading and parsing Mapsforge binary map files (`.map`).
///
/// This class provides low-level access to the map file's contents, including
/// its header, index, and the tile data for ways and points of interest (POIs).
/// It handles the complexities of the binary format, such as variable byte
/// encoding, zoom level intervals, and data block caching.
///
/// For performance-critical applications, it is highly recommended to use the
/// [IsolateMapfile] wrapper, which runs all file operations in a separate
/// isolate to avoid blocking the main UI thread.
///
/// The `Mapfile` instance must be disposed via the `dispose()` method when it is
/// no longer needed to release file handles and clear caches.
class Mapfile extends MapDatastore {
  static final _log = Logger('MapFile');

  /// Bitmask to extract the block offset from an index entry.
  static final int BITMASK_INDEX_OFFSET = 0x7FFFFFFFFF;

  /// Bitmask to extract the water information from an index entry.
  static final int BITMASK_INDEX_WATER = 0x8000000000;

  /// Default start zoom level.
  static final int DEFAULT_START_ZOOM_LEVEL = 12;

  /// Amount of cache blocks that the index cache should store.
  static final int INDEX_CACHE_SIZE = 256;

  /// Error message for an invalid first way offset.
  static final String INVALID_FIRST_WAY_OFFSET = "invalid first way offset: ";

  /// Length of the debug signature at the beginning of each block.
  static final int SIGNATURE_LENGTH_BLOCK = 32;

  /// for debugging purposes
  static final bool complete = true;

  late final IndexCache _databaseIndexCache;

  int _fileSize = -1;

  ZoomlevelRange zoomlevelRange = const ZoomlevelRange.standard();

  /// true if the zoomlevel is overridden manually. Normally the zoomlevel will be set when the map is opened. When overriding that value,
  /// we set this value to true and preventing setting it afterwards.
  bool _zoomlevelOverridden = false;

  late final MapfileInfo _mapFileInfo;

  late final MapfileHelper _helper;

  final TaskQueue _queue = SimpleTaskQueue(name: "Mapfile.lateOpen");

  late final ReadbufferSource readBufferSource;

  final Cache<String, Readbuffer> _cache = LfuCache(capacity: 100);

  /// Creates a `Mapfile` instance from a file path.
  ///
  /// This is the standard way to open a .map file from the file system.
  /// [filename] is the path to the .map file.
  /// [preferredLanguage] can be used to select a specific language for labels.
  /// [source] is an optional override for the read buffer source, mainly for testing.
  static Future<Mapfile> createFromFile({required String filename, String? preferredLanguage, ReadbufferSource? source}) async {
    Mapfile mapFile = Mapfile._(preferredLanguage);
    await mapFile._init(source ?? createReadbufferSource(filename));
    return mapFile;
  }

  /// Creates a `Mapfile` instance from a byte array in memory.
  ///
  /// This is useful for loading map files that are not stored on the local file
  /// system, such as those downloaded from a network.
  /// [content] is the byte content of the .map file.
  /// [preferredLanguage] can be used to select a specific language for labels.
  static Future<Mapfile> createFromContent({required Uint8List content, String? preferredLanguage}) async {
    assert(content.isNotEmpty);
    Mapfile mapFile = Mapfile._(preferredLanguage);
    await mapFile._initContent(content);
    return mapFile;
  }

  /// Opens the given map file channel, reads its header data and validates them.
  ///
  /// @param filename the filename of the mapfile.
  /// @param language       the language to use (may be null).
  /// @throws MapFileException if the given map file channel is null or invalid.
  Mapfile._(String? preferredLanguage) : super((preferredLanguage?.trim().toLowerCase().isEmpty ?? true) ? null : preferredLanguage?.trim().toLowerCase());

  Future<Mapfile> _init(ReadbufferSource source) async {
    _databaseIndexCache = IndexCache(INDEX_CACHE_SIZE);
    readBufferSource = source;
    return this;
  }

  Future<Mapfile> _initContent(Uint8List content) async {
    _databaseIndexCache = IndexCache(INDEX_CACHE_SIZE);
    readBufferSource = ReadbufferMemory(content);
    return this;
  }

  @override
  String toString() {
    return 'MapFile{_fileSize: $_fileSize, _mapFileHeader: $_mapFileInfo, zoomlevelRange: $zoomlevelRange, readBufferSource: $readBufferSource}';
  }

  /// Closes the map file and releases all associated resources.
  ///
  /// This includes clearing the index cache, closing the file handle
  /// ([ReadbufferSource]), and clearing the block cache.
  @override
  void dispose() {
    _databaseIndexCache.dispose();
    readBufferSource.dispose();
    _cache.dispose();
    _queue.dispose();
  }

  /// Returns the low-level header and sub-file information for this map file.
  ///
  /// This is generally used for internal or debugging purposes. For high-level
  /// metadata, use [getMapHeaderInfo].
  /// Requires [_lateOpen] to have been completed.
  MapfileInfo getMapFileInfo() {
    return _mapFileInfo;
  }

  /// Returns the high-level metadata for this map file, such as its bounding
  /// box, start position, and available languages.
  ///
  /// Requires [_lateOpen] to have been completed.
  MapHeaderInfo getMapHeaderInfo() {
    return _mapFileInfo.getMapHeaderInfo();
  }

  /// Returns a list of all languages available in this map file.
  ///
  /// This is parsed from the languages preference string in the map file header.
  /// Returns `null` if no language information is available.
  List<String>? getMapLanguages() {
    String? languagesPreference = getMapHeaderInfo().languagesPreference;
    if (languagesPreference != null && languagesPreference.trim().isNotEmpty) {
      return languagesPreference.split(",");
    }
    return null;
  }

  DatastoreBundle _processBlock(
    QueryParameters queryParameters,
    SubFileParameter subFileParameter,
    BoundingBox boundingBox,
    double tileLatitude,
    double tileLongitude,
    MapfileSelector selector,
    Readbuffer readBuffer,
  ) {
    if (!_processBlockSignature(readBuffer)) {
      throw MapFileException("ProcessblockSignature mismatch");
    }

    List<List<int>> zoomTable = _readZoomTable(subFileParameter, readBuffer);
    int zoomTableRow = queryParameters.queryZoomLevel - subFileParameter.zoomLevelMin;
    int poisOnQueryZoomLevel = zoomTable[zoomTableRow][0];
    int waysOnQueryZoomLevel = zoomTable[zoomTableRow][1];

    // get the relative offset to the first stored way in the block
    int firstWayOffset = readBuffer.readUnsignedInt();
    if (firstWayOffset < 0) {
      throw MapFileException("$INVALID_FIRST_WAY_OFFSET$firstWayOffset");
    }

    // add the current buffer position to the relative first way offset
    firstWayOffset += readBuffer.getBufferPosition();
    if (firstWayOffset > readBuffer.getBufferSize()) {
      throw MapFileException("$INVALID_FIRST_WAY_OFFSET$firstWayOffset");
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

    return DatastoreBundle(pointOfInterests: pois, ways: ways);
  }

  /// Processes the block signature, if present.
  ///
  /// @return true if the block signature could be processed successfully, false otherwise.
  bool _processBlockSignature(Readbuffer readBuffer) {
    if (_mapFileInfo.getMapHeaderInfo().debugFile) {
      // get and check the block signature
      String signatureBlock = readBuffer.readUTF8EncodedString2(SIGNATURE_LENGTH_BLOCK);
      if (!signatureBlock.startsWith("###TileStart")) {
        _log.warning("invalid block signature: $signatureBlock");
        return false;
      }
    }
    return true;
  }

  ///
  /// don't make this method private since we are using it in the example APP to analyze mapfiles
  ///
  Future<DatastoreBundle> processBlocks(
    ReadbufferSource readBufferSource,
    QueryParameters queryParameters,
    SubFileParameter subFileParameter,
    BoundingBox boundingBox,
    MapfileSelector selector,
  ) async {
    bool queryIsWater = true;
    bool queryReadWaterInfo = false;

    DatastoreBundle datastoreBundle = DatastoreBundle(pointOfInterests: [], ways: []);

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
        int currentBlockIndexEntry = await _databaseIndexCache.getIndexEntry(subFileParameter, blockNumber, readBufferSource);

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
            "invalid current block pointer: 0x${currentBlockPointer.toRadixString(16)} with subFileSize: 0x${subFileParameter.subFileSize.toRadixString(16)} for blocknumber $blockNumber",
          );
          return datastoreBundle;
        }

        int? nextBlockPointer;
        // check if the current block is the last block in the file
        if (blockNumber + 1 == subFileParameter.numberOfBlocks) {
          // set the next block pointer to the end of the file
          nextBlockPointer = subFileParameter.subFileSize;
        } else {
          // get and check the next block pointer
          nextBlockPointer = (await _databaseIndexCache.getIndexEntry(subFileParameter, blockNumber + 1, readBufferSource)) & BITMASK_INDEX_OFFSET;
          if (nextBlockPointer > subFileParameter.subFileSize) {
            _log.warning("invalid next block pointer: $nextBlockPointer");
            _log.warning("sub-file size: ${subFileParameter.subFileSize}");
            return datastoreBundle;
          }
        }

        // calculate the size of the current block
        int currentBlockSize = (nextBlockPointer - currentBlockPointer);
        if (currentBlockSize < 0) {
          _log.warning("current block size must not be negative: $currentBlockSize");
          return datastoreBundle;
        } else if (currentBlockSize == 0) {
          // the current block is empty, continue with the next block
          continue;
        } else if (currentBlockSize > MapfileHelper.MAXIMUM_BUFFER_SIZE) {
          // the current block is too large, continue with the next block
          _log.warning("current block size too large: $currentBlockSize");
          continue;
        } else if (currentBlockPointer + currentBlockSize > _fileSize) {
          _log.warning("current block larger than file size: $currentBlockSize");
          return datastoreBundle;
        }

        String key = "${subFileParameter.startAddress + currentBlockPointer}-$currentBlockSize";
        Readbuffer readbuffer = await _cache.getOrProduce(key, (key) async {
          Readbuffer readBuffer = await readBufferSource.readFromFileAt(subFileParameter.startAddress + currentBlockPointer, currentBlockSize);
          return readBuffer;
        });

        // calculate the top-left coordinates of the underlying tile
        double tileLatitude = subFileParameter.projection.tileYToLatitude((subFileParameter.boundaryTileTop + row));
        double tileLongitude = subFileParameter.projection.tileXToLongitude((subFileParameter.boundaryTileLeft + column));

        DatastoreBundle poiWayBundle = _processBlock(
          queryParameters,
          subFileParameter,
          boundingBox,
          tileLatitude,
          tileLongitude,
          selector,
          Readbuffer.from(readbuffer),
        );
        //_blockCache.set(cacheKey, poiWayBundle);
        datastoreBundle.add(poiWayBundle);
      }
    }

    // the query is finished, was the water flag set for all blocks?
    if (queryIsWater && queryReadWaterInfo) {
      // Deprecate water tiles rendering
      datastoreBundle.isWater = true;
    }

    return datastoreBundle;
  }

  /// Reads only label data (POIs and named ways) for a single [tile].
  @override
  Future<DatastoreBundle> readLabelsSingle(Tile tile) async {
    await _lateOpen();
    return _readMapDataComplete(tile, tile, MapfileSelector.LABELS);
  }

  /// Reads label data for a rectangular area of tiles.
  ///
  /// Precondition: `upperLeft.tileX <= lowerRight.tileX` and `upperLeft.tileY <= lowerRight.tileY`.
  @override
  Future<DatastoreBundle> readLabels(Tile upperLeft, Tile lowerRight) async {
    await _lateOpen();
    return _readMapDataComplete(upperLeft, lowerRight, MapfileSelector.LABELS);
  }

  /// Reads all map data (ways and POIs) for a single [tile].
  @override
  Future<DatastoreBundle> readMapDataSingle(Tile tile) async {
    await _lateOpen();
    DatastoreBundle result = await _readMapDataComplete(tile, tile, MapfileSelector.ALL);
    return result;
  }

  /// Reads all map data for a rectangular area of tiles.
  ///
  /// Precondition: `upperLeft.tileX <= lowerRight.tileX` and `upperLeft.tileY <= lowerRight.tileY`.
  @override
  Future<DatastoreBundle> readMapData(Tile upperLeft, Tile lowerRight) async {
    await _lateOpen();
    return _readMapDataComplete(upperLeft, lowerRight, MapfileSelector.ALL);
  }

  /// Reads only Point of Interest (POI) data for a single [tile].
  @override
  Future<DatastoreBundle?> readPoiDataSingle(Tile tile) async {
    await _lateOpen();
    return _readMapDataComplete(tile, tile, MapfileSelector.POIS);
  }

  /// Reads POI data for a rectangular area of tiles.
  ///
  /// Precondition: `upperLeft.tileX <= lowerRight.tileX` and `upperLeft.tileY <= lowerRight.tileY`.
  @override
  Future<DatastoreBundle?> readPoiData(Tile upperLeft, Tile lowerRight) async {
    await _lateOpen();
    return _readMapDataComplete(upperLeft, lowerRight, MapfileSelector.POIS);
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
      _mapFileInfo = mapfileInfoBuilder.build();
      _helper = MapfileHelper(_mapFileInfo, preferredLanguage);
      if (!_zoomlevelOverridden) zoomlevelRange = _mapFileInfo.zoomlevelRange;
      _fileSize = fileSize;
    });
  }

  Future<DatastoreBundle> _readMapDataComplete(Tile upperLeft, Tile lowerRight, MapfileSelector selector) async {
    MercatorProjection projection = MercatorProjection.fromZoomlevel(upperLeft.zoomLevel);
    // may happen that upperLeft and lowerRight does not support the tiles but inbetween do
    //assert(supportsTile(upperLeft, projection));
    //assert(supportsTile(lowerRight, projection));
    assert(upperLeft.zoomLevel == lowerRight.zoomLevel);
    var session = PerformanceProfiler().startSession(category: "Mapfile._readMapDataComplete");

    if (upperLeft.tileX > lowerRight.tileX || upperLeft.tileY > lowerRight.tileY) {
      throw MapFileException("upperLeft tile must be above and left of lowerRight tile");
    }
    QueryParameters queryParameters = QueryParameters();
    queryParameters.queryZoomLevel = _mapFileInfo.getQueryZoomLevel(upperLeft.zoomLevel);

    // get and check the sub-file for the query zoom level
    SubFileParameter? subFileParameter = _mapFileInfo.getSubFileParameter(queryParameters.queryZoomLevel);
    if (subFileParameter == null) {
      throw MapFileException("no sub-file for zoom level: ${queryParameters.queryZoomLevel}");
    }
    queryParameters.calculateBaseTiles(upperLeft, lowerRight, subFileParameter);
    queryParameters.calculateBlocks(subFileParameter);
    session.checkpoint("queryParameters calculated");
    DatastoreBundle? result = await processBlocks(
      readBufferSource,
      queryParameters,
      subFileParameter,
      projection.boundingBoxOfTiles(upperLeft, lowerRight),
      selector,
    );
    session.complete();
    //readBufferMaster.close();
    return result;
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

  /// Restricts the zoom levels for which this datastore will provide data.
  ///
  /// This is useful when combining multiple map files in a `MultiMapDatabase`
  /// to ensure that each map is only used for its intended zoom range.
  void restrictToZoomRange(int minZoom, int maxZoom) {
    zoomlevelRange = ZoomlevelRange(minZoom, maxZoom);
    _zoomlevelOverridden = true;
  }

  /// Returns the recommended start position for this map file.
  ///
  /// If a start position is defined in the map header, it is returned.
  /// Otherwise, the center of the map's bounding box is returned.
  /// Requires [_lateOpen] to have been completed.
  @override
  Future<LatLong?> getStartPosition() async {
    await _lateOpen();
    if (null != getMapHeaderInfo().startPosition) {
      return getMapHeaderInfo().startPosition;
    }
    return getMapHeaderInfo().boundingBox.getCenterPoint();
  }

  /// Returns the recommended start zoom level for this map file.
  ///
  /// If a start zoom level is defined in the map header, it is returned.
  /// Otherwise, [DEFAULT_START_ZOOM_LEVEL] is returned.
  /// Requires [_lateOpen] to have been completed.
  @override
  Future<int?> getStartZoomLevel() async {
    await _lateOpen();
    if (null != getMapHeaderInfo().startZoomLevel) {
      return getMapHeaderInfo().startZoomLevel;
    }
    return DEFAULT_START_ZOOM_LEVEL;
  }

  /// Checks if this map file contains data for the given [tile].
  ///
  /// This is determined by checking if the tile's zoom level is within the
  /// map's zoom range and if the tile's bounding box intersects with the map's
  /// bounding box.
  /// Requires [_lateOpen] to have been completed.
  @override
  Future<bool> supportsTile(Tile tile) async {
    await _lateOpen();
    if (!zoomlevelRange.matches(tile.zoomLevel)) return false;
    return tile.getBoundingBox().intersects(getMapHeaderInfo().boundingBox);
  }

  /// Returns the geographical bounding box that this map file covers.
  ///
  /// Requires [_lateOpen] to have been completed.
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

/// An enum to specify which subset of data to retrieve from a `Mapfile`.
///
/// This allows for optimized queries that only read the necessary data from the
/// file, improving performance.
enum MapfileSelector {
  /// ALL: all data (as in version 0.6.0)
  ALL,

  /// POIS: only poi data, no ways (new after 0.6.0)
  POIS,

  /// LABELS: poi data and ways that have a name (new after 0.6.0)
  LABELS,
}
