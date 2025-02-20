import 'package:logging/logging.dart';

import 'map_header_info.dart';
import 'subfileparameter.dart';

/// Reads and validates the header data from a binary map file.
class MapfileInfo {
  static final _log = new Logger('MapFileHeader');

  /**
   * A single whitespace character.
   */
  static final String SPACE = ' ';

  final MapHeaderInfo mapHeaderInfo;

  final Map<int, SubFileParameter> subFileParameters;

  final int zoomLevelMinimum;

  final int zoomLevelMaximum;

  MapfileInfo(this.mapHeaderInfo, this.subFileParameters, this.zoomLevelMinimum,
      this.zoomLevelMaximum);

  /**
   * @return a MapFileInfo containing the header data. [readHeader] must be
   * executed first
   */
  MapHeaderInfo getMapHeaderInfo() {
    // execute the init() method before using mapfiles
    return this.mapHeaderInfo;
  }

  /// @param zoomLevel the originally requested zoom level.
  /// @return the closest possible zoom level which is covered by a sub-file.
  int getQueryZoomLevel(int zoomLevel) {
    if (zoomLevel > this.zoomLevelMaximum) {
      return this.zoomLevelMaximum;
    } else if (zoomLevel < this.zoomLevelMinimum) {
      return this.zoomLevelMinimum;
    }
    return zoomLevel;
  }

  /// @param queryZoomLevel the zoom level for which the sub-file parameters are needed.
  /// @return the sub-file parameters for the given zoom level.
  SubFileParameter? getSubFileParameter(int queryZoomLevel) {
    return this.subFileParameters[queryZoomLevel];
  }

  void debug() {
    _log.info("mapfile is version ${mapHeaderInfo.fileVersion} from " +
        DateTime.fromMillisecondsSinceEpoch(mapHeaderInfo.mapDate!, isUtc: true)
            .toIso8601String());
    _log.info(mapHeaderInfo.toString());
    _log.info("zoomLevel: $zoomLevelMinimum - $zoomLevelMaximum");
  }

  @override
  String toString() {
    return 'MapFileHeader{mapFileInfo: $mapHeaderInfo, subFileParameters: $subFileParameters, zoomLevelMinimum: $zoomLevelMinimum, zoomLevelMaximum: $zoomLevelMaximum}';
  }
}
