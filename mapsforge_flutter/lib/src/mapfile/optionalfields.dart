import 'mapfileinfobuilder.dart';
import 'readbuffer.dart';
import '../model/latlong.dart';
import '../utils/latlongutils.dart';

class OptionalFields {
  /**
   * Bitmask for the comment field in the file header.
   */
  static final int HEADER_BITMASK_COMMENT = 0x08;

  /**
   * Bitmask for the created by field in the file header.
   */
  static final int HEADER_BITMASK_CREATED_BY = 0x04;

  /**
   * Bitmask for the debug flag in the file header.
   */
  static final int HEADER_BITMASK_DEBUG = 0x80;

  /**
   * Bitmask for the language(s) preference field in the file header.
   */
  static final int HEADER_BITMASK_LANGUAGES_PREFERENCE = 0x10;

  /**
   * Bitmask for the start position field in the file header.
   */
  static final int HEADER_BITMASK_START_POSITION = 0x40;

  /**
   * Bitmask for the start zoom level field in the file header.
   */
  static final int HEADER_BITMASK_START_ZOOM_LEVEL = 0x20;

  /**
   * Maximum valid start zoom level.
   */
  static final int START_ZOOM_LEVEL_MAX = 22;

  static void readOptionalFieldsStatic(
      Readbuffer readBuffer, MapFileInfoBuilder mapFileInfoBuilder) {
    OptionalFields optionalFields = new OptionalFields(readBuffer.readByte());
    mapFileInfoBuilder.optionalFields = optionalFields;

    optionalFields.readOptionalFields(readBuffer);
  }

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

  OptionalFields(int flags) {
    this.isDebugFile = (flags & HEADER_BITMASK_DEBUG) != 0;
    this.hasStartPosition = (flags & HEADER_BITMASK_START_POSITION) != 0;
    this.hasStartZoomLevel = (flags & HEADER_BITMASK_START_ZOOM_LEVEL) != 0;
    this.hasLanguagesPreference =
        (flags & HEADER_BITMASK_LANGUAGES_PREFERENCE) != 0;
    this.hasComment = (flags & HEADER_BITMASK_COMMENT) != 0;
    this.hasCreatedBy = (flags & HEADER_BITMASK_CREATED_BY) != 0;
  }

  void readLanguagesPreference(Readbuffer readBuffer) {
    if (this.hasLanguagesPreference) {
      this.languagesPreference = readBuffer.readUTF8EncodedString();
    }
  }

  void readMapStartPosition(Readbuffer readBuffer) {
    if (this.hasStartPosition) {
      double mapStartLatitude =
          LatLongUtils.microdegreesToDegrees(readBuffer.readInt());
      double mapStartLongitude =
          LatLongUtils.microdegreesToDegrees(readBuffer.readInt());
      this.startPosition = new LatLong(mapStartLatitude, mapStartLongitude);
    }
  }

  void readMapStartZoomLevel(Readbuffer readBuffer) {
    if (this.hasStartZoomLevel) {
      // get and check the start zoom level (1 byte)
      int mapStartZoomLevel = readBuffer.readByte();
      if (mapStartZoomLevel < 0 || mapStartZoomLevel > START_ZOOM_LEVEL_MAX) {
        throw new Exception("invalid map start zoom level: $mapStartZoomLevel");
      }

      this.startZoomLevel = mapStartZoomLevel;
    }
  }

  void readOptionalFields(Readbuffer readBuffer) {
    readMapStartPosition(readBuffer);

    readMapStartZoomLevel(readBuffer);

    readLanguagesPreference(readBuffer);

    if (this.hasComment) {
      this.comment = readBuffer.readUTF8EncodedString();
    }

    if (this.hasCreatedBy) {
      this.createdBy = readBuffer.readUTF8EncodedString();
    }
  }
}
