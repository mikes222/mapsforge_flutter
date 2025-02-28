import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/mapfile_info.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';
import 'package:mapsforge_flutter/src/mapfile/subfileparameter.dart';
import 'package:mapsforge_flutter/src/mapfile/subfileparameterbuilder.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';

import 'map_header_info_builder.dart';

class MapfileInfoBuilder {
  /// Magic byte at the beginning of a valid binary map file.
  static final String BINARY_OSM_MAGIC_BYTE = "mapsforge binary OSM";

  /// Minimum size of the file header in bytes.
  static final int HEADER_SIZE_MIN = 70;

  /// Maximum size of the file header in bytes.
  static final int HEADER_SIZE_MAX = 1000000;

  int zoomLevelMinimum = 65536;

  int zoomLevelMaximum = -65536;

  final Map<int, SubFileParameter> subFileParameters = {};

  MapHeaderInfo? mapHeaderInfo;

  MapfileInfo build() {
    return MapfileInfo(mapHeaderInfo!, subFileParameters,
        ZoomlevelRange(zoomLevelMinimum, zoomLevelMaximum));
  }

  /// Reads and validates the header block from the map file.
  ///
  /// @param readBuffer the ReadBuffer for the file data.
  /// @param fileSize   the size of the map file in bytes.
  /// @throws IOException if an error occurs while reading the file.
  Future<void> readHeader(
      ReadbufferSource readBufferSource, int fileSize) async {
    Readbuffer? readBuffer = await _readMagicByte(readBufferSource);

    // get and check the size of the remaining file header (4 bytes)
    int remainingHeaderSize = readBuffer.readInt();
    if (remainingHeaderSize < HEADER_SIZE_MIN ||
        remainingHeaderSize > HEADER_SIZE_MAX) {
      throw new Exception(
          "invalid remaining header size: $remainingHeaderSize");
    }

// read the header data into the buffer
    readBuffer = await readBufferSource.readFromFile(remainingHeaderSize);

    MapHeaderInfoBuilder mapHeaderInfoBuilder = MapHeaderInfoBuilder();
    mapHeaderInfoBuilder.read(readBuffer, fileSize);

    _readSubFileParameters(readBuffer, fileSize, mapHeaderInfoBuilder);

    this.mapHeaderInfo = mapHeaderInfoBuilder.build();
  }

  /// Reads the macic bytes of the mapfile. This is the very first part of the file.
  Future<Readbuffer> _readMagicByte(ReadbufferSource readBufferSource) async {
    // read the the magic byte and the file header size into the buffer
    int magicByteLength = BINARY_OSM_MAGIC_BYTE.length;

    // length of magic byte + 4 bytes for the file header size
    Readbuffer readBuffer =
        await (readBufferSource.readFromFile(magicByteLength + 4));

    // get and check the magic byte
    String magicByte = readBuffer.readUTF8EncodedString2(magicByteLength);

    if (BINARY_OSM_MAGIC_BYTE != (magicByte)) {
      throw new Exception("invalid magic byte: $magicByte");
    }
    return readBuffer;
  }

  void _readSubFileParameters(Readbuffer readbuffer, int fileSize,
      MapHeaderInfoBuilder mapHeaderInfoBuilder) {
    // get and check the number of sub-files (1 byte)
    int numberOfSubFiles = readbuffer.readByte();
    if (numberOfSubFiles < 1) {
      throw new Exception("invalid number of sub-files: $numberOfSubFiles");
    }
    mapHeaderInfoBuilder.numberOfSubFiles = numberOfSubFiles;

    List<SubFileParameter> tempSubFileParameters = [];
    this.zoomLevelMinimum = 65536;
    this.zoomLevelMaximum = -65536;

    // get and check the information for each sub-file
    for (int currentSubFile = 0;
        currentSubFile < numberOfSubFiles;
        ++currentSubFile) {
      SubFileParameterBuilder subFileParameterBuilder =
          SubFileParameterBuilder();
      subFileParameterBuilder.read(
          readbuffer,
          fileSize,
          mapHeaderInfoBuilder.optionalFields?.isDebugFile ?? false,
          mapHeaderInfoBuilder.boundingBox!);

      // add the current sub-file to the list of sub-files
      SubFileParameter subFileParameter = subFileParameterBuilder.build();
      tempSubFileParameters.add(subFileParameter);

      // update the global minimum and maximum zoom level information
      if (this.zoomLevelMinimum > subFileParameter.zoomLevelMin) {
        this.zoomLevelMinimum = subFileParameter.zoomLevelMin;
        mapHeaderInfoBuilder.zoomlevelMin = this.zoomLevelMinimum;
      }
      if (this.zoomLevelMaximum < subFileParameter.zoomLevelMax) {
        this.zoomLevelMaximum = subFileParameter.zoomLevelMax;
        mapHeaderInfoBuilder.zoomlevelMax = this.zoomLevelMaximum;
      }
    }

    // create and fill the lookup table for the sub-files
    for (int currentMapFile = 0;
        currentMapFile < numberOfSubFiles;
        ++currentMapFile) {
      SubFileParameter subFileParameter =
          tempSubFileParameters.elementAt(currentMapFile);
      for (int zoomLevel = subFileParameter.zoomLevelMin;
          zoomLevel <= subFileParameter.zoomLevelMax;
          ++zoomLevel) {
        this.subFileParameters[zoomLevel] = subFileParameter;
      }
    }
  }
}
