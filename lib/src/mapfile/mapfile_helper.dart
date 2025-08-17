import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/datastore.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfile_info.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/reader/queryparameters.dart';

class MapfileHelper {
  static final _log = new Logger('MapfileHelper');

  /// The key of the elevation OpenStreetMap tag.
  static final String TAG_KEY_ELE = "ele";

  /// The key of the house number OpenStreetMap tag.
  static final String TAG_KEY_HOUSE_NUMBER = "addr:housenumber";

  /// The key of the name OpenStreetMap tag.
  static final String TAG_KEY_NAME = "name";

  /// The key of the reference OpenStreetMap tag.
  static final String TAG_KEY_REF = "ref";

  /// Bitmask for the optional POI feature "elevation".
  static final int POI_FEATURE_ELEVATION = 0x20;

  /// Bitmask for the optional POI feature "house number".
  static final int POI_FEATURE_HOUSE_NUMBER = 0x40;

  /// Bitmask for the optional POI feature "name".
  static final int POI_FEATURE_NAME = 0x80;

  /// Bitmask for the POI layer.
  static final int POI_LAYER_BITMASK = 0xf0;

  /// Bit shift for calculating the POI layer.
  static final int POI_LAYER_SHIFT = 4;

  /// Bitmask for the number of POI tags.
  static final int POI_NUMBER_OF_TAGS_BITMASK = 0x0f;

  /// Bitmask for the way layer.
  static final int WAY_LAYER_BITMASK = 0xf0;

  /// Bit shift for calculating the way layer.
  static final int WAY_LAYER_SHIFT = 4;

  /// Bitmask for the optional way data blocks byte.
  static final int WAY_FEATURE_DATA_BLOCKS_BYTE = 0x08;

  /// Bitmask for the optional way double delta encoding.
  static final int WAY_FEATURE_DOUBLE_DELTA_ENCODING = 0x04;

  /// Bitmask for the optional way feature "house number".
  static final int WAY_FEATURE_HOUSE_NUMBER = 0x40;

  /// Bitmask for the optional way feature "label position".
  static final int WAY_FEATURE_LABEL_POSITION = 0x10;

  /// Bitmask for the optional way feature "name".
  static final int WAY_FEATURE_NAME = 0x80;

  /// Bitmask for the optional way feature "reference".
  static final int WAY_FEATURE_REF = 0x20;

  /// Bitmask for the number of way tags.
  static final int WAY_NUMBER_OF_TAGS_BITMASK = 0x0f;

  /// Length of the debug signature at the beginning of each POI.
  static final int SIGNATURE_LENGTH_POI = 32;

  /// Length of the debug signature at the beginning of each way.
  static final int SIGNATURE_LENGTH_WAY = 32;

  /// Way filtering reduces the number of ways returned to only those that are
  /// relevant for the tile requested, leading to performance gains, but can
  /// cause line clipping artifacts (particularly at higher zoom levels). The
  /// risk of clipping can be reduced by either turning way filtering off or by
  /// increasing the wayFilterDistance which governs how large an area surrounding
  /// the requested tile will be returned.
  /// For most use cases the standard settings should be sufficient.
  static bool wayFilterEnabled = true;

  static int wayFilterDistance = 20;

  final MapfileInfo _mapFileHeader;

  /// the preferred language when extracting labels from this data store. The actual
  /// implementation is up to the concrete implementation, which can also simply ignore
  /// this setting.
  final String? preferredLanguage;

  MapfileHelper(this._mapFileHeader, this.preferredLanguage);

  List<Way> processWays(QueryParameters queryParameters, int numberOfWays, BoundingBox boundingBox, bool filterRequired, double tileLatitude,
      double tileLongitude, MapfileSelector selector, Readbuffer readBuffer, MapDataStore mapDataStore) {
    List<Way> ways = [];
    List<Tag> wayTags = this._mapFileHeader.getMapHeaderInfo().wayTags;

    BoundingBox wayFilterBbox =
        filterRequired ? boundingBox.extendMeters(queryParameters.queryZoomLevel > 20 ? wayFilterDistance ~/ 4 : wayFilterDistance) : boundingBox;

    for (int elementCounter = numberOfWays; elementCounter != 0; --elementCounter) {
      try {
        ways.addAll(read1Way(readBuffer, queryParameters, tileLatitude, tileLongitude, mapDataStore, wayTags, filterRequired, wayFilterBbox, selector));
      } catch (error, stacktrace) {
        print(error);
        print(stacktrace);
        // reset position to next way
        //readBuffer.setBufferPosition(pos + wayDataSize);
      }
    }

    return ways;
  }

  List<Way> read1Way(Readbuffer readBuffer, QueryParameters queryParameters, double tileLatitude, double tileLongitude, MapDataStore mapDataStore,
      List<Tag> wayTags, bool filterRequired, BoundingBox wayFilterBbox, MapfileSelector selector) {
    List<Way> ways = [];
    if (this._mapFileHeader.getMapHeaderInfo().debugFile) {
      // get and check the way signature
      String signatureWay = readBuffer.readUTF8EncodedString2(SIGNATURE_LENGTH_WAY);
      if (!signatureWay.startsWith("---WayStart")) {
        throw Exception("invalid way signature: " + signatureWay);
      }
    }

    // get the size of the way (VBE-U)
    int wayDataSize = readBuffer.readUnsignedInt();
    if (wayDataSize < 0) {
      throw Exception("invalid way data size: $wayDataSize");
    }

    int pos = readBuffer.getBufferPosition();
    if (queryParameters.useTileBitmask) {
      // get the way tile bitmask (2 bytes)
      int tileBitmask = readBuffer.readShort();
      // check if the way is inside the requested tile

      if ((queryParameters.queryTileBitmask! & tileBitmask) == 0) {
        // skip the rest of the way and continue with the next way
        readBuffer.skipBytes(wayDataSize - 2);
        return ways;
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
    //_log.info("processWays for ${wayTags.toString()} and numberofTags: $numberOfTags returned ${tags.length} items");

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
        tags.add(new Tag(TAG_KEY_NAME, mapDataStore.extractLocalized(readBuffer.readUTF8EncodedString())));
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

    List<int>? labelPosition;
    if (featureLabelPosition) {
      labelPosition = _readOptionalLabelPosition(readBuffer);
    }

    int wayDataBlocks = _readOptionalWayDataBlocksByte(featureWayDataBlocksByte, readBuffer);
    if (wayDataBlocks < 1) {
      throw Exception("invalid number of way data blocks: $wayDataBlocks");
    }

    for (int wayDataBlock = 0; wayDataBlock < wayDataBlocks; ++wayDataBlock) {
      List<List<LatLong>> wayNodes = _processWayDataBlock(tileLatitude, tileLongitude, featureWayDoubleDeltaEncoding, readBuffer);
      if (filterRequired && wayFilterEnabled && !wayFilterBbox.intersectsArea(wayNodes)) {
        continue;
      }
      if (MapfileSelector.ALL == selector || featureName || featureHouseNumber || featureRef || wayAsLabelTagFilter(tags)) {
        LatLong? labelLatLong;
        if (labelPosition != null) {
          labelLatLong = LatLong(wayNodes[0][0].latitude + LatLongUtils.microdegreesToDegrees(labelPosition[1]),
              wayNodes[0][0].longitude + LatLongUtils.microdegreesToDegrees(labelPosition[0]));
        }
        ways.add(Way(layer, tags, wayNodes, labelLatLong));
      }
    }
    return ways;
  }

  /// reads all data blocks of a way. Each datablock consists of a number of way nodes
  /// which comprises one way, e.g. the outer way of a pond or one of several outer ways.
  /// See https://wiki.openstreetmap.org/wiki/Relation:multipolygon for a detailed
  /// explanation.
  List<List<LatLong>> _processWayDataBlock(double tileLatitude, double tileLongitude, bool doubleDeltaEncoding, Readbuffer readBuffer) {
    // get and check the number of way coordinate blocks (VBE-U)
    int numberOfWayCoordinateBlocks = readBuffer.readUnsignedInt();
    if (numberOfWayCoordinateBlocks < 1 || numberOfWayCoordinateBlocks > 32767) {
      throw Exception("invalid number of way coordinate blocks: $numberOfWayCoordinateBlocks");
    }

    // create the array which will store the different way coordinate blocks
    List<List<LatLong>> wayCoordinates = [];

    // read the way coordinate blocks
    for (int coordinateBlock = 0; coordinateBlock < numberOfWayCoordinateBlocks; ++coordinateBlock) {
      // get and check the number of way nodes (VBE-U)
      int numberOfWayNodes = readBuffer.readUnsignedInt();
      if (numberOfWayNodes < 2 || numberOfWayNodes > 32767) {
        throw Exception("invalid number of way nodes: $numberOfWayNodes");
        // returning null here will actually leave the tile blank as the
        // position on the ReadBuffer will not be advanced correctly. However,
        // it will not crash the app.
      }

      // create the array which will store the current way segment
      List<LatLong> waySegment = [];

      if (doubleDeltaEncoding) {
        waySegment = _decodeWayNodesDoubleDelta(numberOfWayNodes, tileLatitude, tileLongitude, readBuffer);
      } else {
        waySegment = _decodeWayNodesSingleDelta(numberOfWayNodes, tileLatitude, tileLongitude, readBuffer);
      }

      wayCoordinates.add(waySegment);
    }

    return wayCoordinates;
  }

  /// decodes the coordinates of a way which was encoded with double encoding algorithm
  List<LatLong> _decodeWayNodesDoubleDelta(int numberOfWayNodes, double tileLatitude, double tileLongitude, Readbuffer readBuffer) {
    // get the first way node latitude offset (VBE-S)
    double wayNodeLatitude = tileLatitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());
    // get the first way node longitude offset (VBE-S)
    double wayNodeLongitude = tileLongitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

    List<LatLong> waySegment = [];
    // store the first way node
    waySegment.add(LatLong(wayNodeLatitude, wayNodeLongitude));

    double previousSingleDeltaLatitude = 0;
    double previousSingleDeltaLongitude = 0;

    for (int wayNodesIndex = 0; wayNodesIndex < numberOfWayNodes - 1; ++wayNodesIndex) {
      // get the way node latitude double-delta offset (VBE-S)
      double doubleDeltaLatitude = LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());
      // get the way node longitude double-delta offset (VBE-S)
      double doubleDeltaLongitude = LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

      double singleDeltaLatitude = doubleDeltaLatitude + previousSingleDeltaLatitude;
      double singleDeltaLongitude = doubleDeltaLongitude + previousSingleDeltaLongitude;

      wayNodeLatitude = wayNodeLatitude + singleDeltaLatitude;
      wayNodeLongitude = wayNodeLongitude + singleDeltaLongitude;

      // Decoding near international date line can return values slightly outside valid [-180°, 180°] due to calculation precision
      if (wayNodeLongitude < Projection.LONGITUDE_MIN) {
        wayNodeLongitude = Projection.LONGITUDE_MIN;
      } else if (wayNodeLongitude > Projection.LONGITUDE_MAX) {
        wayNodeLongitude = Projection.LONGITUDE_MAX;
      }
      if (wayNodeLatitude < Projection.LATITUDE_MIN) {
        wayNodeLatitude = Projection.LATITUDE_MIN;
      } else if (wayNodeLatitude > Projection.LATITUDE_MAX) {
        wayNodeLatitude = Projection.LATITUDE_MAX;
      }

      waySegment.add(LatLong(wayNodeLatitude, wayNodeLongitude));

      previousSingleDeltaLatitude = singleDeltaLatitude;
      previousSingleDeltaLongitude = singleDeltaLongitude;
    }
    return waySegment;
  }

  /// decodes the coordinates of a way which was encoded with single encoding algorithm
  List<LatLong> _decodeWayNodesSingleDelta(int numberOfWayNodes, double tileLatitude, double tileLongitude, Readbuffer readBuffer) {
    // get the first way node latitude single-delta offset (VBE-S)
    double wayNodeLatitude = tileLatitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());
    // get the first way node longitude single-delta offset (VBE-S)
    double wayNodeLongitude = tileLongitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

    // store the first way node
    List<LatLong> waySegment = [];
    waySegment.add(LatLong(wayNodeLatitude, wayNodeLongitude));

    for (int wayNodesIndex = 0; wayNodesIndex < numberOfWayNodes - 1; ++wayNodesIndex) {
      // get the way node latitude offset (VBE-S)
      wayNodeLatitude = wayNodeLatitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());
      // get the way node longitude offset (VBE-S)
      wayNodeLongitude = wayNodeLongitude + LatLongUtils.microdegreesToDegrees(readBuffer.readSignedInt());

      // Decoding near international date line can return values slightly outside valid [-180°, 180°] due to calculation precision
      if (wayNodeLongitude < Projection.LONGITUDE_MIN) {
        wayNodeLongitude = Projection.LONGITUDE_MIN;
      } else if (wayNodeLongitude > Projection.LONGITUDE_MAX) {
        wayNodeLongitude = Projection.LONGITUDE_MAX;
      }
      if (wayNodeLatitude < Projection.LATITUDE_MIN) {
        wayNodeLatitude = Projection.LATITUDE_MIN;
      } else if (wayNodeLatitude > Projection.LATITUDE_MAX) {
        wayNodeLatitude = Projection.LATITUDE_MAX;
      }

      waySegment.add(LatLong(wayNodeLatitude, wayNodeLongitude));
    }
    return waySegment;
  }

  List<PointOfInterest> processPOIs(double tileLatitude, double tileLongitude, int numberOfPois, BoundingBox boundingBox, bool filterRequired,
      Readbuffer readBuffer, MapDataStore mapDataStore) {
    List<PointOfInterest> pois = [];
    List<Tag> poiTags = this._mapFileHeader.getMapHeaderInfo().poiTags;

    for (int elementCounter = numberOfPois; elementCounter != 0; --elementCounter) {
      PointOfInterest pointOfInterest = read1Poi(readBuffer, tileLatitude, tileLongitude, mapDataStore, poiTags);

      // depending on the zoom level configuration the poi can lie outside
      // the tile requested, we filter them out here
      if (!filterRequired || boundingBox.containsLatLong(pointOfInterest.position)) {
        pois.add(pointOfInterest);
      }
    }

    return pois;
  }

  PointOfInterest read1Poi(Readbuffer readBuffer, double tileLatitude, double tileLongitude, MapDataStore mapDataStore, List<Tag> poiTags) {
    if (this._mapFileHeader.getMapHeaderInfo().debugFile) {
      // get and check the POI signature
      String signaturePoi = readBuffer.readUTF8EncodedString2(SIGNATURE_LENGTH_POI);
      if (!signaturePoi.startsWith("***POIStart")) {
        throw Exception("invalid POI signature: " + signaturePoi);
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

    // get the feature bitmask (1 byte)
    int featureByte = readBuffer.readByte();

    // bit 1-3 enable optional features
    bool featureName = (featureByte & POI_FEATURE_NAME) != 0;
    bool featureHouseNumber = (featureByte & POI_FEATURE_HOUSE_NUMBER) != 0;
    bool featureElevation = (featureByte & POI_FEATURE_ELEVATION) != 0;

    // check if the POI has a name
    if (featureName) {
      tags.add(new Tag(TAG_KEY_NAME, mapDataStore.extractLocalized(readBuffer.readUTF8EncodedString())));
    }

    // check if the POI has a house number
    if (featureHouseNumber) {
      tags.add(new Tag(TAG_KEY_HOUSE_NUMBER, readBuffer.readUTF8EncodedString()));
    }

    // check if the POI has an elevation
    if (featureElevation) {
      tags.add(new Tag(TAG_KEY_ELE, readBuffer.readSignedInt().toString()));
    }

    LatLong position = LatLong(latitude, longitude);
    return PointOfInterest(layer, tags, position);
  }

  ///
  /// returns the position of a label in longitude/latitude (sic!) format
  List<int> _readOptionalLabelPosition(Readbuffer readBuffer) {
    List<int> labelPosition = [];

    // get the label position latitude offset (VBE-S)
    labelPosition.add(readBuffer.readSignedInt());

    // get the label position longitude offset (VBE-S)
    labelPosition.insert(0, readBuffer.readSignedInt());

    return labelPosition;
  }

  int _readOptionalWayDataBlocksByte(bool featureWayDataBlocksByte, Readbuffer readBuffer) {
    if (featureWayDataBlocksByte) {
      // get and check the number of way data blocks (VBE-U)
      return readBuffer.readUnsignedInt();
    }
    // only one way data block exists
    return 1;
  }

  /// Returns true if a way should be included in the result set for readLabels()
  /// By default only ways with names, house numbers or a ref are included in the result set
  /// of readLabels(). This is to reduce the set of ways as much as possible to save memory.
  /// @param tags the tags associated with the way
  /// @return true if the way should be included in the result set
  bool wayAsLabelTagFilter(List<Tag> tags) {
    return false;
  }
}
