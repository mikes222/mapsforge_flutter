import 'package:mapsforge_flutter/src/mapfile/mapfile_info_builder.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';

import '../../../core.dart';
import '../map_header_info.dart';
import '../map_header_info_builder.dart';
import '../map_header_optional_fields.dart';

class MapfileHeaderWriter {
  final MapHeaderInfo mapHeaderInfo;

  MapfileHeaderWriter(this.mapHeaderInfo);

  Writebuffer write(int tagSubfileSize) {
    Writebuffer writebuffer = Writebuffer();
    _writeFileVersion(writebuffer);
    int fileSize = 0;
    // Placeholder for file size, will be set in close() method via RandomAccessFile
    writebuffer.appendInt8(fileSize);
    _writeMapDate(writebuffer);
    _writeBoundingBox(writebuffer);
    _writeTilePixelSize(writebuffer);
    _writeProjectionName(writebuffer);

    _writeOptionalFlag(writebuffer);
    // optional fields:
    _writeOptionalStartposition(writebuffer);
    _writeOptionalStartzoomlevel(writebuffer);
    _writeOptionalLanguagesPreference(writebuffer);
    _writeOptionalComment(writebuffer);
    _writeOptionalCreatedBy(writebuffer);

    Writebuffer writebuffer2 = Writebuffer();
    _writeMagicByte(writebuffer2);
    // 4 byte header size
    writebuffer2.appendInt4(tagSubfileSize + writebuffer.length + 4);

    writebuffer2.appendWritebuffer(writebuffer);
    return writebuffer2;
  }

  void _writeMagicByte(Writebuffer writebuffer) {
    writebuffer
        .appendStringWithoutLength(MapfileInfoBuilder.BINARY_OSM_MAGIC_BYTE);
  }

  void _writeFileVersion(Writebuffer writebuffer) {
    writebuffer.appendInt4(5);
  }

  void _writeMapDate(Writebuffer writebuffer) {
    writebuffer.appendInt8(
        mapHeaderInfo.mapDate ?? DateTime.now().millisecondsSinceEpoch);
  }

  void _writeBoundingBox(Writebuffer writebuffer) {
    writebuffer.appendInt4(LatLongUtils.degreesToMicrodegrees(
        mapHeaderInfo.boundingBox.minLatitude));
    writebuffer.appendInt4(LatLongUtils.degreesToMicrodegrees(
        mapHeaderInfo.boundingBox.minLongitude));
    writebuffer.appendInt4(LatLongUtils.degreesToMicrodegrees(
        mapHeaderInfo.boundingBox.maxLatitude));
    writebuffer.appendInt4(LatLongUtils.degreesToMicrodegrees(
        mapHeaderInfo.boundingBox.maxLongitude));
  }

  void _writeTilePixelSize(Writebuffer writebuffer) {
    writebuffer.appendInt2(mapHeaderInfo.tilePixelSize);
  }

  void _writeProjectionName(Writebuffer writebuffer) {
    writebuffer.appendString(MapHeaderInfoBuilder.MERCATOR);
  }

  void _writeOptionalFlag(Writebuffer writebuffer) {
    int flag = 0;
    if (mapHeaderInfo.debugFile)
      flag |= MapHeaderOptionalFields.HEADER_BITMASK_DEBUG;
    if (mapHeaderInfo.startPosition != null)
      flag |= MapHeaderOptionalFields.HEADER_BITMASK_START_POSITION;
    if (mapHeaderInfo.startZoomLevel != null)
      flag |= MapHeaderOptionalFields.HEADER_BITMASK_START_ZOOM_LEVEL;
    if (mapHeaderInfo.languagesPreference != null)
      flag |= MapHeaderOptionalFields.HEADER_BITMASK_LANGUAGES_PREFERENCE;
    if (mapHeaderInfo.comment != null)
      flag |= MapHeaderOptionalFields.HEADER_BITMASK_COMMENT;
    if (mapHeaderInfo.createdBy != null)
      flag |= MapHeaderOptionalFields.HEADER_BITMASK_CREATED_BY;
    writebuffer.appendInt1(flag);
  }

  void _writeOptionalStartposition(Writebuffer writebuffer) {
    if (mapHeaderInfo.startPosition != null) {
      writebuffer.appendInt4(LatLongUtils.degreesToMicrodegrees(
          mapHeaderInfo.startPosition!.latitude));
      writebuffer.appendInt4(LatLongUtils.degreesToMicrodegrees(
          mapHeaderInfo.startPosition!.longitude));
    }
  }

  void _writeOptionalStartzoomlevel(Writebuffer writebuffer) {
    if (mapHeaderInfo.startZoomLevel != null) {
      writebuffer.appendInt1(mapHeaderInfo.startZoomLevel!);
    }
  }

  void _writeOptionalLanguagesPreference(Writebuffer writebuffer) {
    if (mapHeaderInfo.languagesPreference != null) {
      writebuffer.appendString(mapHeaderInfo.languagesPreference!);
    }
  }

  void _writeOptionalComment(Writebuffer writebuffer) {
    if (mapHeaderInfo.comment != null) {
      writebuffer.appendString(mapHeaderInfo.comment!);
    }
  }

  void _writeOptionalCreatedBy(Writebuffer writebuffer) {
    if (mapHeaderInfo.createdBy != null) {
      writebuffer.appendString(mapHeaderInfo.createdBy!);
    }
  }
}
