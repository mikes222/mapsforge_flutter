import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';

/// A data holder for the optional fields that can be present in a map file header.
///
/// The presence of each optional field is determined by a single byte flag in the
/// header. This class parses that flag and provides methods to read the fields
/// from the read buffer if they exist.
class MapHeaderOptionalFields {
  /// Bitmask for the comment field in the file header.
  static final int HEADER_BITMASK_COMMENT = 0x08;

  /// Bitmask for the created by field in the file header.
  static final int HEADER_BITMASK_CREATED_BY = 0x04;

  /// Bitmask for the debug flag in the file header.
  static final int HEADER_BITMASK_DEBUG = 0x80;

  /// Bitmask for the language(s) preference field in the file header.
  static final int HEADER_BITMASK_LANGUAGES_PREFERENCE = 0x10;

  /// Bitmask for the start position field in the file header.
  static final int HEADER_BITMASK_START_POSITION = 0x40;

  /// Bitmask for the start zoom level field in the file header.
  static final int HEADER_BITMASK_START_ZOOM_LEVEL = 0x20;

  /// Maximum valid start zoom level.
  final int START_ZOOM_LEVEL_MAX = 22;

  String? comment;
  String? createdBy;
  late bool hasComment;
  late bool hasCreatedBy;
  late bool hasLanguagesPreference;
  late bool hasStartPosition;
  late bool hasStartZoomLevel;
  late bool isDebugFile;
  String? languagesPreference;
  LatLong? startPosition;
  int? startZoomLevel;

  MapHeaderOptionalFields(int flags) {
    isDebugFile = (flags & HEADER_BITMASK_DEBUG) != 0;
    hasStartPosition = (flags & HEADER_BITMASK_START_POSITION) != 0;
    hasStartZoomLevel = (flags & HEADER_BITMASK_START_ZOOM_LEVEL) != 0;
    hasLanguagesPreference = (flags & HEADER_BITMASK_LANGUAGES_PREFERENCE) != 0;
    hasComment = (flags & HEADER_BITMASK_COMMENT) != 0;
    hasCreatedBy = (flags & HEADER_BITMASK_CREATED_BY) != 0;
  }

    /// Reads the languages preference string from the buffer, if present.
  void readLanguagesPreference(Readbuffer readBuffer) {
    if (hasLanguagesPreference) {
      languagesPreference = readBuffer.readUTF8EncodedString();
    }
  }

    /// Reads the map start position from the buffer, if present.
  void readMapStartPosition(Readbuffer readBuffer) {
    if (hasStartPosition) {
      double mapStartLatitude = LatLongUtils.microdegreesToDegrees(readBuffer.readInt());
      double mapStartLongitude = LatLongUtils.microdegreesToDegrees(readBuffer.readInt());
      startPosition = LatLong(mapStartLatitude, mapStartLongitude);
    }
  }

    /// Reads the map start zoom level from the buffer, if present.
  void readMapStartZoomLevel(Readbuffer readBuffer) {
    if (hasStartZoomLevel) {
      // get and check the start zoom level (1 byte)
      int mapStartZoomLevel = readBuffer.readByte();
      if (mapStartZoomLevel < 0 || mapStartZoomLevel > START_ZOOM_LEVEL_MAX) {
        throw Exception("invalid map start zoom level: $mapStartZoomLevel");
      }

      startZoomLevel = mapStartZoomLevel;
    }
  }

    /// Reads all optional fields from the buffer based on the flags set in the constructor.
  void readOptionalFields(Readbuffer readBuffer) {
    readMapStartPosition(readBuffer);

    readMapStartZoomLevel(readBuffer);

    readLanguagesPreference(readBuffer);

    if (hasComment) {
      comment = readBuffer.readUTF8EncodedString();
    }

    if (hasCreatedBy) {
      createdBy = readBuffer.readUTF8EncodedString();
    }
  }
}
