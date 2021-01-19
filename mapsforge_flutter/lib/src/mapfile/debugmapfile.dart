import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/mapfile/subfileparameter.dart';
import 'package:mapsforge_flutter/src/utils/latlongutils.dart';

///
/// The intention is to create a class which allows some insight into the mapfile. In the meantime we have something similar in the
/// flutter_example APP wich provides graphical insight into the mapfile so this class seems not necessary anymore.
///
class DebugMapfile extends MapFile {
  static final _log = new Logger('DebugMapfile');

  DebugMapfile(String filename, int timestamp, String language) : super(filename, timestamp, language);

//   void debug() async {
//     _log.info(
//         "MapFile: wayfilter: ${MapFile.wayFilterEnabled}, ${MapFile.wayFilterDistance}, size of file: $_fileSize, zoomLevel $zoomLevelMin - $zoomLevelMax");
//     _log.info("Cache: " + _databaseIndexCache.toString());
//     this._mapFileHeader.debug();
//
//     this._mapFileHeader.getMapFileInfo().poiTags.forEach((Tag tag) {
//       _log.info("  PoiTag ${tag.toString()}");
//     });
//     this._mapFileHeader.getMapFileInfo().wayTags.forEach((Tag tag) {
//       _log.info("  WayTag ${tag.toString()}");
//     });
//     int zoomLevel = 0;
//     Set<int> readedSubFiles = Set();
//     for (SubFileParameter subFileParameter in _mapFileHeader.subFileParameters) {
//       if (subFileParameter == null) {
//         ++zoomLevel;
//         continue;
//       }
//       if (readedSubFiles.contains(subFileParameter.startAddress)) {
//         // already analyzed
//         ++zoomLevel;
//         continue;
//       }
//       _log.info("SubfileParameter for zoomLevel $zoomLevel: " + subFileParameter.toString());
//       ReadBufferMaster readBufferMaster = ReadBufferMaster(filename);
//       for (int block = 0; block < subFileParameter.blocksWidth * subFileParameter.blocksHeight; ++block) {
//         await _debugBlock(block, subFileParameter, readBufferMaster);
//       }
//       readedSubFiles.add(subFileParameter.startAddress);
//       ++zoomLevel;
//     }
//
// //    Tile tile = Tile(0, 0, zoomLevelMin, 256);
// //    MapReadResult result = await readMapDataSingle(tile);
// //    _log.info("Result: " + result.toString());
//   }
//
//   Future<void> _debugBlock(int block, SubFileParameter subFileParameter, ReadBufferMaster readBufferMaster) async {
//     int row = (block / subFileParameter.blocksWidth).floor();
//     int column = (block % subFileParameter.blocksWidth);
//     MercatorProjectionImpl mercatorProjectionImpl = MercatorProjectionImpl(500, subFileParameter.baseZoomLevel);
//     double tileLatitude = mercatorProjectionImpl.tileYToLatitude((subFileParameter.boundaryTileTop + row));
//     double tileLongitude = mercatorProjectionImpl.tileXToLongitude((subFileParameter.boundaryTileLeft + column));
//
//     int currentBlockIndexEntry = await this._databaseIndexCache.getIndexEntry(subFileParameter, block);
//     int currentBlockPointer = currentBlockIndexEntry & BITMASK_INDEX_OFFSET;
//     int nextBlockPointer;
//     // check if the current block is the last block in the file
//     if (block + 1 == subFileParameter.numberOfBlocks) {
//       // set the next block pointer to the end of the file
//       nextBlockPointer = subFileParameter.subFileSize;
//     } else {
//       // get and check the next block pointer
//       nextBlockPointer = (await this._databaseIndexCache.getIndexEntry(subFileParameter, block + 1)) & BITMASK_INDEX_OFFSET;
//     }
//
//     // calculate the size of the current block
//     int currentBlockSize = (nextBlockPointer - currentBlockPointer);
//     _log.info("  Block $block: starting at ${subFileParameter.startAddress + currentBlockSize}, length: $currentBlockSize");
//     if (currentBlockSize == 0) {
//       return;
//     }
//     ReadBuffer readBuffer =
//     await readBufferMaster.readFromFile(length: currentBlockSize, offset: subFileParameter.startAddress + currentBlockPointer);
//
//     _processBlockSignature(readBuffer);
//     List<List<int>> zoomTable = _readZoomTable(subFileParameter, readBuffer);
//     zoomTable.forEach((List<int> items) {
//       // zoomLevel = idx + subFileParameter.minZoom
//       _log.info("  Tile zoomTable cumulatedNumberOfPois: ${items.elementAt(0)}, cumulatedNumberOfWays: ${items.elementAt(1)}");
//     });
//     // get the relative offset to the first stored way in the block
//     int firstWayOffset = readBuffer.readUnsignedInt();
//     _log.info("  Offest to first way entry: $firstWayOffset");
//     // todo read pois
//     if (firstWayOffset > 0) {
//       readBuffer.skipBytes(firstWayOffset);
//     }
//     _debugWays(readBuffer, subFileParameter, zoomTable.last.last, tileLatitude, tileLongitude);
//   }
//
//   void _debugWays(
//       ReadBuffer readBuffer, SubFileParameter subFileParameter, int cumulatedNumberOfWays, double tileLatitude, double tileLongitude) {
//     _log.info("  CumulatedNumberOfWays is $cumulatedNumberOfWays");
//     for (int i = 0; i < cumulatedNumberOfWays; ++i) {
//       // read ways
//       if (this._mapFileHeader.getMapFileInfo().debugFile) {
//         // get and check the way signature
//         String signatureWay = readBuffer.readUTF8EncodedString2(SIGNATURE_LENGTH_WAY);
//         _log.info("    way signature: " + signatureWay);
//       }
//       int wayDataSize = readBuffer.readUnsignedInt();
//       int pos = readBuffer.bufferPosition;
//       int tileBitmask = readBuffer.readShort();
//       int specialByte = readBuffer.readByte();
//       // bit 1-4 represent the layer
//       int layer = ((specialByte & WAY_LAYER_BITMASK) >> WAY_LAYER_SHIFT);
//       // bit 5-8 represent the number of tag IDs
//       int numberOfTags = (specialByte & WAY_NUMBER_OF_TAGS_BITMASK);
//
//       _log.info(
//           "    Way $i: WaydataSize $wayDataSize, tileBitmask: ${tileBitmask.toRadixString(16)}, specialByte: ${specialByte.toRadixString(16)} - (layer: $layer, numberOfTags: $numberOfTags)");
//       // get the tags from IDs (VBE-U)
//       List<Tag> wayTags = this._mapFileHeader.getMapFileInfo().wayTags;
//       try {
//         _debugTags(readBuffer, wayTags, numberOfTags, tileLatitude, tileLongitude);
//       } catch (e) {
//         Error error = e;
//         print(e.toString());
//         print(error.stackTrace);
//         // reset position to next way
//         readBuffer.bufferPosition = pos + wayDataSize;
//       }
//
//       int size = readBuffer.bufferPosition - pos;
//       if (size != wayDataSize) {
//         String result = hex.encode(readBuffer.getBuffer(pos, wayDataSize));
//         _log.info("    WayDataSize mismatching, expected $wayDataSize vs read $size $result");
//       }
//     }
//   }
//
//   void _debugTags(ReadBuffer readBuffer, List<Tag> wayTags, int numberOfTags, double tileLatitude, double tileLongitude) {
//     String tagString = "";
//     List<Tag> tags = readBuffer.readTags(wayTags, numberOfTags);
// //    for (int tagIndex = 0; tagIndex < numberOfTags; ++tagIndex) {
// //      int tagId = readBuffer.readUnsignedInt();
// //      tagString += "$tagId";
// //      if (tagId < wayTags.length) {
// //        tagString += " (${wayTags[tagId].toString()})";
// //      }
// //      tagString += ", ";
// //    }
//
//     tags.forEach((tag) {
//       tagString += " " + tag.toString();
//     });
//
//     // get the feature bitmask (1 byte)
//     int featureByte = readBuffer.readByte();
//
//     // bit 1-6 enable optional features
//     bool featureName = (featureByte & WAY_FEATURE_NAME) != 0;
//     bool featureHouseNumber = (featureByte & WAY_FEATURE_HOUSE_NUMBER) != 0;
//     bool featureRef = (featureByte & WAY_FEATURE_REF) != 0;
//     bool featureLabelPosition = (featureByte & WAY_FEATURE_LABEL_POSITION) != 0;
//     bool featureWayDataBlocksByte = (featureByte & WAY_FEATURE_DATA_BLOCKS_BYTE) != 0;
//     bool featureWayDoubleDeltaEncoding = (featureByte & WAY_FEATURE_DOUBLE_DELTA_ENCODING) != 0;
//
//     tagString += "Feature " +
//         (featureName ? "Name," : "") +
//         (featureHouseNumber ? "Nbr," : "") +
//         (featureRef ? "Ref," : "") +
//         (featureLabelPosition ? "Label," : "") +
//         (featureWayDataBlocksByte ? "Data," : "") +
//         (featureWayDoubleDeltaEncoding ? "Double," : "") +
//         " ";
//     // check if the way has a name
//     if (featureName) {
//       try {
//         Tag tag = (new Tag(TAG_KEY_NAME, extractLocalized(readBuffer.readUTF8EncodedString())));
//         tagString += "${tag.toString()}, ";
//       } catch (e) {
//         _log.warning("Error reading featureName " + e.toString());
//         //tags.add(Tag(TAG_KEY_NAME, "unknown"));
//       }
//     }
//
//     // check if the way has a house number
//     if (featureHouseNumber) {
//       try {
//         Tag tag = (new Tag(TAG_KEY_HOUSE_NUMBER, readBuffer.readUTF8EncodedString()));
//         tagString += "${tag.toString()}, ";
//       } catch (e) {
//         _log.warning("Error reading featureHouseNumber " + e.toString());
//         //tags.add(Tag(TAG_KEY_NAME, "unknown"));
//       }
//     }
//
//     // check if the way has a reference
//     if (featureRef) {
//       try {
//         Tag tag = (new Tag(TAG_KEY_REF, readBuffer.readUTF8EncodedString()));
//         tagString += "${tag.toString()}, ";
//       } catch (e) {
//         _log.warning("Error reading featureRef " + e.toString());
//         //tags.add(Tag(TAG_KEY_NAME, "unknown"));
//       }
//     }
//
//     List<int> labelPosition;
//     if (featureLabelPosition) {
//       labelPosition = _readOptionalLabelPosition(readBuffer);
//       tagString += "lat/lon: ${labelPosition[0]}/${labelPosition[1]}, ";
//     }
//
//     int wayDataBlocks = _readOptionalWayDataBlocksByte(featureWayDataBlocksByte, readBuffer);
//     tagString += "// wayDataBlocks: $wayDataBlocks, ";
//
//     if (complete && tagString.length > 2) _log.info("      TagIds: $tagString");
//
//     for (int wayDataBlock = 0; wayDataBlock < wayDataBlocks; ++wayDataBlock) {
//       List<List<LatLong>> wayNodes = _processWayDataBlock(tileLatitude, tileLongitude, featureWayDoubleDeltaEncoding, readBuffer);
//       if (wayNodes != null) {
// //        if (Selector.ALL == selector ||
// //            featureName ||
// //            featureHouseNumber ||
// //            featureRef ||
// //            wayAsLabelTagFilter(tags)) {
//         LatLong labelLatLong;
//         if (labelPosition != null) {
//           labelLatLong = new LatLong(wayNodes[0][0].latitude + LatLongUtils.microdegreesToDegrees(labelPosition[1]),
//               wayNodes[0][0].longitude + LatLongUtils.microdegreesToDegrees(labelPosition[0]));
//         }
//         //ways.add(new Way(layer, tags, wayNodes, labelLatLong));
//         //}
//         if (complete) _log.info("      WayNodes: ${wayNodes.toString()}");
//       }
//     }
//   }

}
