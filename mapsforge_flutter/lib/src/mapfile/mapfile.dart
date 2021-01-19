import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfileinfo.dart';
import 'package:mapsforge_flutter/src/mapfile/subfileparameter.dart';
import 'package:mapsforge_flutter/src/parameters.dart';

import '../datastore/mapdatastore.dart';
import '../datastore/mapreadresult.dart';
import '../datastore/pointofinterest.dart';
import '../datastore/poiwaybundle.dart';
import '../datastore/way.dart';
import '../model/boundingbox.dart';
import '../model/latlong.dart';
import '../model/tag.dart';
import '../model/tile.dart';
import '../projection/mercatorprojectionimpl.dart';
import '../reader/queryparameters.dart';
import '../utils/latlongutils.dart';
import 'indexcache.dart';
import 'mapfileheader.dart';
import 'readbuffer.dart';

/// A class for reading binary map files.
/// <p/>
/// The readMapData method is now thread safe, but care should be taken that not too much data is
/// read at the same time (keep simultaneous requests to minimum)
///
/// @see <a href="https://github.com/mapsforge/mapsforge/blob/master/docs/Specification-Binary-Map-File.md">Specification</a>
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

  /**
   * Amount of cache blocks that the index cache should store.
   */
  static final int INDEX_CACHE_SIZE = 64;

  /**
   * Error message for an invalid first way offset.
   */
  static final String INVALID_FIRST_WAY_OFFSET = "invalid first way offset: ";

  /**
   * Bitmask for the optional POI feature "elevation".
   */
  static final int POI_FEATURE_ELEVATION = 0x20;

  /**
   * Bitmask for the optional POI feature "house number".
   */
  static final int POI_FEATURE_HOUSE_NUMBER = 0x40;

  /**
   * Bitmask for the optional POI feature "name".
   */
  static final int POI_FEATURE_NAME = 0x80;

  /**
   * Bitmask for the POI layer.
   */
  static final int POI_LAYER_BITMASK = 0xf0;

  /**
   * Bit shift for calculating the POI layer.
   */
  static final int POI_LAYER_SHIFT = 4;

  /**
   * Bitmask for the number of POI tags.
   */
  static final int POI_NUMBER_OF_TAGS_BITMASK = 0x0f;

  /**
   * Length of the debug signature at the beginning of each block.
   */
  static final int SIGNATURE_LENGTH_BLOCK = 32;

  /**
   * Length of the debug signature at the beginning of each POI.
   */
  static final int SIGNATURE_LENGTH_POI = 32;

  /**
   * Length of the debug signature at the beginning of each way.
   */
  static final int SIGNATURE_LENGTH_WAY = 32;

  /**
   * The key of the elevation OpenStreetMap tag.
   */
  static final String TAG_KEY_ELE = "ele";

  /**
   * The key of the house number OpenStreetMap tag.
   */
  static final String TAG_KEY_HOUSE_NUMBER = "addr:housenumber";

  /**
   * The key of the name OpenStreetMap tag.
   */
  static final String TAG_KEY_NAME = "name";

  /**
   * The key of the reference OpenStreetMap tag.
   */
  static final String TAG_KEY_REF = "ref";

  /**
   * Bitmask for the optional way data blocks byte.
   */
  static final int WAY_FEATURE_DATA_BLOCKS_BYTE = 0x08;

  /**
   * Bitmask for the optional way double delta encoding.
   */
  static final int WAY_FEATURE_DOUBLE_DELTA_ENCODING = 0x04;

  /**
   * Bitmask for the optional way feature "house number".
   */
  static final int WAY_FEATURE_HOUSE_NUMBER = 0x40;

  /**
   * Bitmask for the optional way feature "label position".
   */
  static final int WAY_FEATURE_LABEL_POSITION = 0x10;

  /**
   * Bitmask for the optional way feature "name".
   */
  static final int WAY_FEATURE_NAME = 0x80;

  /**
   * Bitmask for the optional way feature "reference".
   */
  static final int WAY_FEATURE_REF = 0x20;

  /**
   * Bitmask for the way layer.
   */
  static final int WAY_LAYER_BITMASK = 0xf0;

  /**
   * Bit shift for calculating the way layer.
   */
  static final int WAY_LAYER_SHIFT = 4;

  /**
   * Bitmask for the number of way tags.
   */
  static final int WAY_NUMBER_OF_TAGS_BITMASK = 0x0f;

  /// for debugging purposes
  static final bool complete = true;

  /**
   * Way filtering reduces the number of ways returned to only those that are
   * relevant for the tile requested, leading to performance gains, but can
   * cause line clipping artifacts (particularly at higher zoom levels). The
   * risk of clipping can be reduced by either turning way filtering off or by
   * increasing the wayFilterDistance which governs how large an area surrounding
   * the requested tile will be returned.
   * For most use cases the standard settings should be sufficient.
   */
  static bool wayFilterEnabled = true;

  static int wayFilterDistance = 20;

  IndexCache _databaseIndexCache;

  int _fileSize;

  MapFileHeader _mapFileHeader;
  final int timestamp;

  int zoomLevelMin = 0;
  int zoomLevelMax = 65536;

  final String filename;

  ///
  /// Only used for tests
  ///
  MapFile.empty()
      : _fileSize = 0,
        timestamp = DateTime.now().millisecondsSinceEpoch,
        filename = null,
        super(null);

  /// Opens the given map file channel, reads its header data and validates them.
  ///
  /// @param filename the filename of the mapfile.
  /// @param language       the language to use (may be null).
  /// @throws MapFileException if the given map file channel is null or invalid.
  MapFile(this.filename, this.timestamp, String language)
      : assert(filename != null),
        super(language);

  Future<void> init() async {
    _databaseIndexCache = new IndexCache(filename, INDEX_CACHE_SIZE);
    ReadBufferMaster readBufferMaster = ReadBufferMaster(filename);
    this._fileSize = await readBufferMaster.length();
    _mapFileHeader = MapFileHeader();
    await this._mapFileHeader.readHeader(readBufferMaster, this._fileSize);
    readBufferMaster.close();
  }

  void dispose() {
    close();
  }

  /**
   * Opens the given map file, reads its header data and validates them. Uses default language.
   *
   * @param mapPath the path of the map file.
   * @throws MapFileException if the given map file is null or invalid.
   */
//  MapFile(String mapPath) {
//    this(mapPath, null);
//  }

  /**
   * Opens the given map file, reads its header data and validates them.
   *
   * @param mapPath  the path of the map file.
   * @param language the language to use (may be null).
   * @throws MapFileException if the given map file is null or invalid or IOException if the file
   *                          cannot be opened.
   */
//  MapFile(String mapPath, String language) {
//    this(new File(mapPath), language);
//  }

  @override
  BoundingBox get boundingBox {
    return getMapFileInfo().boundingBox;
  }

  @override
  void close() {
    closeFileChannel();
  }

  /**
   * Closes the map file channel and destroys all internal caches.
   * Has no effect if no map file channel is currently opened.
   */
  void closeFileChannel() {
    if (this._databaseIndexCache != null) {
      this._databaseIndexCache.destroy();
    }
  }

  void _decodeWayNodesDoubleDelta(List<LatLong> waySegment, double tileLatitude, double tileLongitude, ReadBuffer readBuffer) {
    // get the first way node latitude offset (VBE-S)
    double wayNodeLatitude = tileLatitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

    // get the first way node longitude offset (VBE-S)
    double wayNodeLongitude = tileLongitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

    // store the first way node
    waySegment[0] = (new LatLong(wayNodeLatitude, wayNodeLongitude));

    double previousSingleDeltaLatitude = 0;
    double previousSingleDeltaLongitude = 0;

    for (int wayNodesIndex = 1; wayNodesIndex < waySegment.length; ++wayNodesIndex) {
      // get the way node latitude double-delta offset (VBE-S)
      double doubleDeltaLatitude = LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

      // get the way node longitude double-delta offset (VBE-S)
      double doubleDeltaLongitude = LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

      double singleDeltaLatitude = doubleDeltaLatitude + previousSingleDeltaLatitude;
      double singleDeltaLongitude = doubleDeltaLongitude + previousSingleDeltaLongitude;

      wayNodeLatitude = wayNodeLatitude + singleDeltaLatitude;
      wayNodeLongitude = wayNodeLongitude + singleDeltaLongitude;

      // Decoding near international date line can return values slightly outside valid [-180°, 180°] due to calculation precision
      if (wayNodeLongitude < LatLongUtils.LONGITUDE_MIN) {
        wayNodeLongitude = LatLongUtils.LONGITUDE_MIN;
      } else if (wayNodeLongitude > LatLongUtils.LONGITUDE_MAX) {
        wayNodeLongitude = LatLongUtils.LONGITUDE_MAX;
      }
      if (wayNodeLatitude < LatLongUtils.LATITUDE_MIN) {
        wayNodeLatitude = LatLongUtils.LATITUDE_MIN;
      } else if (wayNodeLatitude > LatLongUtils.LATITUDE_MAX) {
        wayNodeLatitude = LatLongUtils.LATITUDE_MAX;
      }

      waySegment[wayNodesIndex] = (new LatLong(wayNodeLatitude, wayNodeLongitude));

      previousSingleDeltaLatitude = singleDeltaLatitude;
      previousSingleDeltaLongitude = singleDeltaLongitude;
    }
  }

  void _decodeWayNodesSingleDelta(List<LatLong> waySegment, double tileLatitude, double tileLongitude, ReadBuffer readBuffer) {
    // get the first way node latitude single-delta offset (VBE-S)
    double wayNodeLatitude = tileLatitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

    // get the first way node longitude single-delta offset (VBE-S)
    double wayNodeLongitude = tileLongitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

    // store the first way node
    waySegment[0] = (new LatLong(wayNodeLatitude, wayNodeLongitude));

    for (int wayNodesIndex = 1; wayNodesIndex < waySegment.length; ++wayNodesIndex) {
      // get the way node latitude offset (VBE-S)
      wayNodeLatitude = wayNodeLatitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());
      // get the way node longitude offset (VBE-S)
      wayNodeLongitude = wayNodeLongitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

      // Decoding near international date line can return values slightly outside valid [-180°, 180°] due to calculation precision
      if (wayNodeLongitude < LatLongUtils.LONGITUDE_MIN) {
        wayNodeLongitude = LatLongUtils.LONGITUDE_MIN;
      } else if (wayNodeLongitude > LatLongUtils.LONGITUDE_MAX) {
        wayNodeLongitude = LatLongUtils.LONGITUDE_MAX;
      }
      if (wayNodeLatitude < LatLongUtils.LATITUDE_MIN) {
        wayNodeLatitude = LatLongUtils.LATITUDE_MIN;
      } else if (wayNodeLatitude > LatLongUtils.LATITUDE_MAX) {
        wayNodeLatitude = LatLongUtils.LATITUDE_MAX;
      }

      waySegment[wayNodesIndex] = (new LatLong(wayNodeLatitude, wayNodeLongitude));
    }
  }

  /**
   * Returns the creation timestamp of the map file.
   *
   * @param tile not used, as all tiles will shared the same creation date.
   * @return the creation timestamp inside the map file.
   */
  @override
  int getDataTimestamp(Tile tile) {
    return this.timestamp;
  }

  /**
   * @return the header data for the current map file.
   */
  MapFileHeader getMapFileHeader() {
    return this._mapFileHeader;
  }

  /**
   * @return the metadata for the current map file.
   */
  MapFileInfo getMapFileInfo() {
    return this._mapFileHeader.getMapFileInfo();
  }

  /**
   * @return the map file supported languages (may be null).
   */
  List<String> getMapLanguages() {
    String languagesPreference = getMapFileInfo().languagesPreference;
    if (languagesPreference != null && !languagesPreference.trim().isEmpty) {
      return languagesPreference.split(",");
    }
    return null;
  }

  PoiWayBundle _processBlock(QueryParameters queryParameters, SubFileParameter subFileParameter, BoundingBox boundingBox,
      double tileLatitude, double tileLongitude, Selector selector, ReadBuffer readBuffer) {
    assert(queryParameters.queryZoomLevel != null);
    if (!_processBlockSignature(readBuffer)) {
      _log.warning("ProcessblockSignature mismatch");
      return null;
    }

    List<List<int>> zoomTable = _readZoomTable(subFileParameter, readBuffer);
    int zoomTableRow = queryParameters.queryZoomLevel - subFileParameter.zoomLevelMin;
    int poisOnQueryZoomLevel = zoomTable[zoomTableRow][0];
    int waysOnQueryZoomLevel = zoomTable[zoomTableRow][1];

    // get the relative offset to the first stored way in the block
    int firstWayOffset = readBuffer.readUnsignedInt();
    if (firstWayOffset < 0) {
      _log.warning(INVALID_FIRST_WAY_OFFSET + "$firstWayOffset");
      return null;
    }

    // add the current buffer position to the relative first way offset
    firstWayOffset += readBuffer.bufferPosition;
    if (firstWayOffset > readBuffer.getBufferSize()) {
      _log.warning(INVALID_FIRST_WAY_OFFSET + "$firstWayOffset");
      return null;
    }

    bool filterRequired = queryParameters.queryZoomLevel > subFileParameter.baseZoomLevel;

    List<PointOfInterest> pois = processPOIs(tileLatitude, tileLongitude, poisOnQueryZoomLevel, boundingBox, filterRequired, readBuffer);
    if (pois == null) {
      _log.warning("No Pois");
      return null;
    }

    List<Way> ways;
    if (Selector.POIS == selector) {
      ways = List<Way>();
    } else {
      // finished reading POIs, check if the current buffer position is valid
      if (readBuffer.getBufferPosition() > firstWayOffset) {
        _log.warning("invalid buffer position: ${readBuffer.getBufferPosition()}");
        return null;
      }
      if (firstWayOffset == readBuffer.getBufferSize()) {
        // no ways in this block
        ways = List<Way>();
      } else {
        // move the pointer to the first way
        readBuffer.setBufferPosition(firstWayOffset);

        ways = _processWays(
            queryParameters, waysOnQueryZoomLevel, boundingBox, filterRequired, tileLatitude, tileLongitude, selector, readBuffer);
        if (ways == null) {
          _log.warning("No Ways");
          ways = List<Way>();
          //return null;
        }
      }
    }

    return new PoiWayBundle(pois, ways);
  }

  /**
   * Processes the block signature, if present.
   *
   * @return true if the block signature could be processed successfully, false otherwise.
   */
  bool _processBlockSignature(ReadBuffer readBuffer) {
    if (this._mapFileHeader.getMapFileInfo().debugFile) {
      // get and check the block signature
      String signatureBlock = readBuffer.readUTF8EncodedString2(SIGNATURE_LENGTH_BLOCK);
      if (!signatureBlock.startsWith("###TileStart")) {
        _log.warning("invalid block signature: " + signatureBlock);
        return false;
      }
    }
    return true;
  }

  Future<MapReadResult> processBlocks(ReadBufferMaster readBufferMaster, QueryParameters queryParameters, SubFileParameter subFileParameter,
      BoundingBox boundingBox, Selector selector) async {
    assert(_fileSize != null);
    assert(queryParameters.fromBlockX != null);
    assert(queryParameters.fromBlockY != null);
    bool queryIsWater = true;
    bool queryReadWaterInfo = false;
    MercatorProjectionImpl mercatorProjectionImpl = MercatorProjectionImpl(500, subFileParameter.baseZoomLevel);

    MapReadResult mapFileReadResult = new MapReadResult();

    // read and process all blocks from top to bottom and from left to right
    for (int row = queryParameters.fromBlockY; row <= queryParameters.toBlockY; ++row) {
      for (int column = queryParameters.fromBlockX; column <= queryParameters.toBlockX; ++column) {
        // calculate the actual block number of the needed block in the file
        int blockNumber = row * subFileParameter.blocksWidth + column;

        // get the current index entry
        int currentBlockIndexEntry = await this._databaseIndexCache.getIndexEntry(subFileParameter, blockNumber, readBufferMaster);

        // check if the current query would still return a water tile
        if (queryIsWater) {
          // check the water flag of the current block in its index entry
          queryIsWater &= (currentBlockIndexEntry & BITMASK_INDEX_WATER) != 0;
          queryReadWaterInfo = true;
        }

        // get and check the current block pointer
        int currentBlockPointer = currentBlockIndexEntry & BITMASK_INDEX_OFFSET;
        if (currentBlockPointer < 1 || currentBlockPointer > subFileParameter.subFileSize) {
          _log.warning("invalid current block pointer: $currentBlockPointer");
          _log.warning("subFileSize: ${subFileParameter.subFileSize}");
          return null;
        }

        int nextBlockPointer;
        // check if the current block is the last block in the file
        if (blockNumber + 1 == subFileParameter.numberOfBlocks) {
          // set the next block pointer to the end of the file
          nextBlockPointer = subFileParameter.subFileSize;
        } else {
          // get and check the next block pointer
          nextBlockPointer =
              (await this._databaseIndexCache.getIndexEntry(subFileParameter, blockNumber + 1, readBufferMaster)) & BITMASK_INDEX_OFFSET;
          if (nextBlockPointer > subFileParameter.subFileSize) {
            _log.warning("invalid next block pointer: $nextBlockPointer");
            _log.warning("sub-file size: ${subFileParameter.subFileSize}");
            return null;
          }
        }

        // calculate the size of the current block
        int currentBlockSize = (nextBlockPointer - currentBlockPointer);
        if (currentBlockSize < 0) {
          _log.warning("current block size must not be negative: $currentBlockSize");
          return null;
        } else if (currentBlockSize == 0) {
          // the current block is empty, continue with the next block
          continue;
        } else if (currentBlockSize > Parameters.MAXIMUM_BUFFER_SIZE) {
          // the current block is too large, continue with the next block
          _log.warning("current block size too large: $currentBlockSize");
          continue;
        } else if (currentBlockPointer + currentBlockSize > this._fileSize) {
          _log.warning("current block larger than file size: $currentBlockSize");
          return null;
        }

        // _log.info(
        //     "Processing block $row/$column from currentBlockPointer ${subFileParameter.startAddress + currentBlockPointer} to nextBlockPointer ${subFileParameter.startAddress + nextBlockPointer} ($currentBlockSize byte)");

        // seek to the current block in the map file
        // read the current block into the buffer
        //ReadBuffer readBuffer = new ReadBuffer(inputChannel);
        ReadBuffer readBuffer =
            await readBufferMaster.readFromFile(length: currentBlockSize, offset: subFileParameter.startAddress + currentBlockPointer);

        // calculate the top-left coordinates of the underlying tile
        double tileLatitude = mercatorProjectionImpl.tileYToLatitude((subFileParameter.boundaryTileTop + row));
        double tileLongitude = mercatorProjectionImpl.tileXToLongitude((subFileParameter.boundaryTileLeft + column));
        LatLongUtils.validateLatitude(tileLatitude);
        LatLongUtils.validateLongitude(tileLongitude);

        PoiWayBundle poiWayBundle =
            _processBlock(queryParameters, subFileParameter, boundingBox, tileLatitude, tileLongitude, selector, readBuffer);
        if (poiWayBundle != null) {
          mapFileReadResult.add(poiWayBundle);
        }
      }
    }

    // the query is finished, was the water flag set for all blocks?
    if (queryIsWater && queryReadWaterInfo) {
      // Deprecate water tiles rendering
      mapFileReadResult.isWater = true;
    }

    return mapFileReadResult;
  }

  List<PointOfInterest> processPOIs(
      double tileLatitude, double tileLongitude, int numberOfPois, BoundingBox boundingBox, bool filterRequired, ReadBuffer readBuffer) {
    List<PointOfInterest> pois = new List();
    List<Tag> poiTags = this._mapFileHeader.getMapFileInfo().poiTags;

    for (int elementCounter = numberOfPois; elementCounter != 0; --elementCounter) {
      if (this._mapFileHeader.getMapFileInfo().debugFile) {
        // get and check the POI signature
        String signaturePoi = readBuffer.readUTF8EncodedString2(SIGNATURE_LENGTH_POI);
        if (!signaturePoi.startsWith("***POIStart")) {
          _log.warning("invalid POI signature: " + signaturePoi);
          return null;
        }
      }

      // get the POI latitude offset (VBE-S)
      double latitude = tileLatitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

      // get the POI longitude offset (VBE-S)
      double longitude = tileLongitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

      // get the special int which encodes multiple flags
      int specialByte = readBuffer.readByte();

      // bit 1-4 represent the layer
      int layer = ((specialByte & POI_LAYER_BITMASK) >> POI_LAYER_SHIFT);
      // bit 5-8 represent the number of tag IDs
      int numberOfTags = (specialByte & POI_NUMBER_OF_TAGS_BITMASK);

      // get the tags from IDs (VBE-U)
      List<Tag> tags = readBuffer.readTags(poiTags, numberOfTags);
      if (tags == null) {
        return null;
      }

      // get the feature bitmask (1 byte)
      int featureByte = readBuffer.readByte();

      // bit 1-3 enable optional features
      bool featureName = (featureByte & POI_FEATURE_NAME) != 0;
      bool featureHouseNumber = (featureByte & POI_FEATURE_HOUSE_NUMBER) != 0;
      bool featureElevation = (featureByte & POI_FEATURE_ELEVATION) != 0;

      // check if the POI has a name
      if (featureName) {
        tags.add(new Tag(TAG_KEY_NAME, extractLocalized(readBuffer.readUTF8EncodedString())));
      }

      // check if the POI has a house number
      if (featureHouseNumber) {
        tags.add(new Tag(TAG_KEY_HOUSE_NUMBER, readBuffer.readUTF8EncodedString()));
      }

      // check if the POI has an elevation
      if (featureElevation) {
        tags.add(new Tag(TAG_KEY_ELE, readBuffer.readSignedInt().toString()));
      }

      LatLong position = new LatLong(latitude, longitude);
      // depending on the zoom level configuration the poi can lie outside
      // the tile requested, we filter them out here
      if (!filterRequired || boundingBox.containsLatLong(position)) {
        pois.add(new PointOfInterest(layer, tags, position));
      }
    }

    return pois;
  }

  List<List<LatLong>> _processWayDataBlock(double tileLatitude, double tileLongitude, bool doubleDeltaEncoding, ReadBuffer readBuffer) {
    // get and check the number of way coordinate blocks (VBE-U)
    int numberOfWayCoordinateBlocks = readBuffer.readUnsignedInt();
    if (numberOfWayCoordinateBlocks < 1 || numberOfWayCoordinateBlocks > 32767) {
      _log.warning("invalid number of way coordinate blocks: $numberOfWayCoordinateBlocks");
      return null;
    }

    // create the array which will store the different way coordinate blocks
    List<List<LatLong>> wayCoordinates = new List<List<LatLong>>(numberOfWayCoordinateBlocks);

    // read the way coordinate blocks
    for (int coordinateBlock = 0; coordinateBlock < numberOfWayCoordinateBlocks; ++coordinateBlock) {
      // get and check the number of way nodes (VBE-U)
      int numberOfWayNodes = readBuffer.readUnsignedInt();
      if (numberOfWayNodes < 2 || numberOfWayNodes > 32767) {
        _log.warning("invalid number of way nodes: $numberOfWayNodes");
        // returning null here will actually leave the tile blank as the
        // position on the ReadBuffer will not be advanced correctly. However,
        // it will not crash the app.
        return null;
      }

      // create the array which will store the current way segment
      List<LatLong> waySegment = new List<LatLong>(numberOfWayNodes);

      if (doubleDeltaEncoding) {
        _decodeWayNodesDoubleDelta(waySegment, tileLatitude, tileLongitude, readBuffer);
      } else {
        _decodeWayNodesSingleDelta(waySegment, tileLatitude, tileLongitude, readBuffer);
      }

      wayCoordinates[coordinateBlock] = waySegment;
    }

    return wayCoordinates;
  }

  List<Way> _processWays(QueryParameters queryParameters, int numberOfWays, BoundingBox boundingBox, bool filterRequired,
      double tileLatitude, double tileLongitude, Selector selector, ReadBuffer readBuffer) {
    List<Way> ways = new List();
    List<Tag> wayTags = this._mapFileHeader.getMapFileInfo().wayTags;

    BoundingBox wayFilterBbox = boundingBox.extendMeters(wayFilterDistance);

    for (int elementCounter = numberOfWays; elementCounter != 0; --elementCounter) {
      if (this._mapFileHeader.getMapFileInfo().debugFile) {
        // get and check the way signature
        String signatureWay = readBuffer.readUTF8EncodedString2(SIGNATURE_LENGTH_WAY);
        if (!signatureWay.startsWith("---WayStart")) {
          _log.warning("invalid way signature: " + signatureWay);
          return null;
        }
      }

      int wayDataSize;
      try {
        // get the size of the way (VBE-U)
        wayDataSize = readBuffer.readUnsignedInt();
        if (wayDataSize < 0) {
          _log.warning("invalid way data size: $wayDataSize");
          return null;
        }
      } catch (e) {
        Error error = e;
        print(e.toString());
        print(error.stackTrace);
        // reset position to next way
        break;
      }
      int pos = readBuffer.bufferPosition;
      try {
        if (queryParameters.useTileBitmask) {
          // get the way tile bitmask (2 bytes)
          int tileBitmask = readBuffer.readShort();
          // check if the way is inside the requested tile
          if ((queryParameters.queryTileBitmask & tileBitmask) == 0) {
            // skip the rest of the way and continue with the next way
            readBuffer.skipBytes(wayDataSize - 2);
            continue;
          }
        } else {
          // ignore the way tile bitmask (2 bytes)
          readBuffer.skipBytes(2);
        }

        // get the special int which encodes multiple flags
        int specialByte = readBuffer.readByte();

        // bit 1-4 represent the layer
        int layer = ((specialByte & WAY_LAYER_BITMASK) >> WAY_LAYER_SHIFT);
        // bit 5-8 represent the number of tag IDs
        int numberOfTags = (specialByte & WAY_NUMBER_OF_TAGS_BITMASK);

        // get the tags from IDs (VBE-U)
        List<Tag> tags = readBuffer.readTags(wayTags, numberOfTags);
        if (tags == null) {
          return null;
        }
//      _log.info(
//          "processWays for ${wayTags.toString()} and numberofTags: $numberOfTags returned ${tags.length} items");

        // get the feature bitmask (1 byte)
        int featureByte = readBuffer.readByte();

        // bit 1-6 enable optional features
        bool featureName = (featureByte & WAY_FEATURE_NAME) != 0;
        bool featureHouseNumber = (featureByte & WAY_FEATURE_HOUSE_NUMBER) != 0;
        bool featureRef = (featureByte & WAY_FEATURE_REF) != 0;
        bool featureLabelPosition = (featureByte & WAY_FEATURE_LABEL_POSITION) != 0;
        bool featureWayDataBlocksByte = (featureByte & WAY_FEATURE_DATA_BLOCKS_BYTE) != 0;
        bool featureWayDoubleDeltaEncoding = (featureByte & WAY_FEATURE_DOUBLE_DELTA_ENCODING) != 0;

        // check if the way has a name
        if (featureName) {
          try {
            tags.add(new Tag(TAG_KEY_NAME, extractLocalized(readBuffer.readUTF8EncodedString())));
          } catch (e) {
            _log.warning(e.toString());
            //tags.add(Tag(TAG_KEY_NAME, "unknown"));
          }
        }

        // check if the way has a house number
        if (featureHouseNumber) {
          try {
            tags.add(new Tag(TAG_KEY_HOUSE_NUMBER, readBuffer.readUTF8EncodedString()));
          } catch (e) {
            _log.warning(e.toString());
            //tags.add(Tag(TAG_KEY_NAME, "unknown"));
          }
        }

        // check if the way has a reference
        if (featureRef) {
          try {
            tags.add(new Tag(TAG_KEY_REF, readBuffer.readUTF8EncodedString()));
          } catch (e) {
            _log.warning(e.toString());
            //tags.add(Tag(TAG_KEY_NAME, "unknown"));
          }
        }

        List<int> labelPosition;
        if (featureLabelPosition) {
          labelPosition = _readOptionalLabelPosition(readBuffer);
        }

        int wayDataBlocks = _readOptionalWayDataBlocksByte(featureWayDataBlocksByte, readBuffer);
        if (wayDataBlocks < 1) {
          _log.warning("invalid number of way data blocks: $wayDataBlocks");
          return null;
        }

        for (int wayDataBlock = 0; wayDataBlock < wayDataBlocks; ++wayDataBlock) {
          List<List<LatLong>> wayNodes = _processWayDataBlock(tileLatitude, tileLongitude, featureWayDoubleDeltaEncoding, readBuffer);
          if (wayNodes != null) {
            if (filterRequired && wayFilterEnabled && !wayFilterBbox.intersectsArea(wayNodes)) {
              continue;
            }
            if (Selector.ALL == selector || featureName || featureHouseNumber || featureRef || wayAsLabelTagFilter(tags)) {
              LatLong labelLatLong = null;
              if (labelPosition != null) {
                labelLatLong = new LatLong(wayNodes[0][0].latitude + LatLongUtils.microdegreesToDegrees(labelPosition[1]),
                    wayNodes[0][0].longitude + LatLongUtils.microdegreesToDegrees(labelPosition[0]));
              }
              ways.add(new Way(layer, tags, wayNodes, labelLatLong));
            }
          }
        }
      } catch (e) {
        Error error = e;
        print(e.toString());
        print(error.stackTrace);
        // reset position to next way
        readBuffer.bufferPosition = pos + wayDataSize;
      }
    }

    return ways;
  }

  /**
   * Reads only labels for tile.
   *
   * @param tile tile for which data is requested.
   * @return label data for the tile.
   */
  @override
  Future<MapReadResult> readLabelsSingle(Tile tile) async {
    return _readMapDataComplete(tile, tile, Selector.LABELS);
  }

  /**
   * Reads data for an area defined by the tile in the upper left and the tile in
   * the lower right corner.
   * Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
   *
   * @param upperLeft  tile that defines the upper left corner of the requested area.
   * @param lowerRight tile that defines the lower right corner of the requested area.
   * @return map data for the tile.
   */
  @override
  Future<MapReadResult> readLabels(Tile upperLeft, Tile lowerRight) async {
    return _readMapDataComplete(upperLeft, lowerRight, Selector.LABELS);
  }

  /**
   * Reads all map data for the area covered by the given tile at the tile zoom level.
   *
   * @param tile defines area and zoom level of read map data.
   * @return the read map data.
   */
  @override
  Future<MapReadResult> readMapDataSingle(Tile tile) async {
    return _readMapDataComplete(tile, tile, Selector.ALL);
  }

  /**
   * Reads data for an area defined by the tile in the upper left and the tile in
   * the lower right corner.
   * Precondition: upperLeft.tileX <= lowerRight.tileX && upperLeft.tileY <= lowerRight.tileY
   *
   * @param upperLeft  tile that defines the upper left corner of the requested area.
   * @param lowerRight tile that defines the lower right corner of the requested area.
   * @return map data for the tile.
   */
  @override
  Future<MapReadResult> readMapData(Tile upperLeft, Tile lowerRight) async {
    return _readMapDataComplete(upperLeft, lowerRight, Selector.ALL);
  }

  Future<MapReadResult> _readMapDataComplete(Tile upperLeft, Tile lowerRight, Selector selector) async {
    int timer = DateTime.now().millisecondsSinceEpoch;
    if (upperLeft.tileX > lowerRight.tileX || upperLeft.tileY > lowerRight.tileY) {
      new Exception("upperLeft tile must be above and left of lowerRight tile");
    }

    QueryParameters queryParameters = new QueryParameters();
    queryParameters.queryZoomLevel = this._mapFileHeader.getQueryZoomLevel(upperLeft.zoomLevel);

    // get and check the sub-file for the query zoom level
    SubFileParameter subFileParameter = this._mapFileHeader.getSubFileParameter(queryParameters.queryZoomLevel);
    if (subFileParameter == null) {
      _log.warning("no sub-file for zoom level: ${queryParameters.queryZoomLevel}");
      return null;
    }

    queryParameters.calculateBaseTiles(upperLeft, lowerRight, subFileParameter);
    queryParameters.calculateBlocks(subFileParameter);
    int diff = DateTime.now().millisecondsSinceEpoch - timer;
    if (diff > 100) _log.info("  readMapDataComplete took $diff ms up to query subfileparams");

    // we enlarge the bounding box for the tile slightly in order to retain any data that
    // lies right on the border, some of this data needs to be drawn as the graphics will
    // overlap onto this tile.
    ReadBufferMaster readBufferMaster = ReadBufferMaster(filename);
    MapReadResult result = await processBlocks(
        readBufferMaster, queryParameters, subFileParameter, Tile.getBoundingBoxStatic(upperLeft, lowerRight), selector);
    diff = DateTime.now().millisecondsSinceEpoch - timer;
    if (diff > 100) _log.info("readMapDataComplete took $diff ms");
    readBufferMaster.close();
    return result;
  }

  List<int> _readOptionalLabelPosition(ReadBuffer readBuffer) {
    List<int> labelPosition = new List<int>(2);

    // get the label position latitude offset (VBE-S)
    labelPosition[1] = readBuffer.readSignedInt();

    // get the label position longitude offset (VBE-S)
    labelPosition[0] = readBuffer.readSignedInt();

    return labelPosition;
  }

  int _readOptionalWayDataBlocksByte(bool featureWayDataBlocksByte, ReadBuffer readBuffer) {
    if (featureWayDataBlocksByte) {
      // get and check the number of way data blocks (VBE-U)
      return readBuffer.readUnsignedInt();
    }
    // only one way data block exists
    return 1;
  }

  /**
   * Reads only POI data for tile.
   *
   * @param tile tile for which data is requested.
   * @return POI data for the tile.
   */
  @override
  Future<MapReadResult> readPoiDataSingle(Tile tile) async {
    return _readMapDataComplete(tile, tile, Selector.POIS);
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
  Future<MapReadResult> readPoiData(Tile upperLeft, Tile lowerRight) async {
    return _readMapDataComplete(upperLeft, lowerRight, Selector.POIS);
  }

  List<List<int>> _readZoomTable(SubFileParameter subFileParameter, ReadBuffer readBuffer) {
    int rows = subFileParameter.zoomLevelMax - subFileParameter.zoomLevelMin + 1;
    List<List<int>> zoomTable = new List<List<int>>(rows);

    int cumulatedNumberOfPois = 0;
    int cumulatedNumberOfWays = 0;

    for (int row = 0; row < rows; ++row) {
      cumulatedNumberOfPois += readBuffer.readUnsignedInt();
      cumulatedNumberOfWays += readBuffer.readUnsignedInt();
      List<int> inner = List();
      inner.add(cumulatedNumberOfPois);
      inner.add(cumulatedNumberOfWays);
      zoomTable[row] = inner;
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
  LatLong get startPosition {
    if (null != getMapFileInfo().startPosition) {
      return getMapFileInfo().startPosition;
    }
    return getMapFileInfo().boundingBox.getCenterPoint();
  }

  @override
  int get startZoomLevel {
    if (null != getMapFileInfo().startZoomLevel) {
      return getMapFileInfo().startZoomLevel;
    }
    return DEFAULT_START_ZOOM_LEVEL;
  }

  @override
  bool supportsTile(Tile tile) {
    return tile.getBoundingBox().intersects(getMapFileInfo().boundingBox) &&
        (tile.zoomLevel >= this.zoomLevelMin && tile.zoomLevel <= this.zoomLevelMax);
  }
}

/////////////////////////////////////////////////////////////////////////////

/**
 * The Selector enum is used to specify which data subset is to be retrieved from a MapFile:
 * ALL: all data (as in version 0.6.0)
 * POIS: only poi data, no ways (new after 0.6.0)
 * LABELS: poi data and ways that have a name (new after 0.6.0)
 */
enum Selector { ALL, POIS, LABELS }
