import 'package:dart_common/model.dart';
import 'package:dart_mapfile/mapfile.dart';
import 'package:dart_mapfile/src/model/subfile_parameter.dart';
import 'package:logging/logging.dart';

/// Reads and validates the header data from a binary map file.
class MapfileInfo {
  static final _log = new Logger('MapFileHeader');

  /**
   * A single whitespace character.
   */
  static final String SPACE = ' ';

  final MapHeaderInfo mapHeaderInfo;

  final Map<int, SubFileParameter> subFileParameters;

  final ZoomlevelRange zoomlevelRange;

  MapfileInfo(this.mapHeaderInfo, this.subFileParameters, this.zoomlevelRange);

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
  int getQueryZoomLevel(int zoomlevel) {
    return zoomlevelRange.ensureBounds(zoomlevel);
  }

  /// @param queryZoomLevel the zoom level for which the sub-file parameters are needed.
  /// @return the sub-file parameters for the given zoom level.
  SubFileParameter? getSubFileParameter(int queryZoomLevel) {
    return this.subFileParameters[queryZoomLevel];
  }

  void debug() {
    _log.info(
      "mapfile is version ${mapHeaderInfo.fileVersion} from " + DateTime.fromMillisecondsSinceEpoch(mapHeaderInfo.mapDate!, isUtc: true).toIso8601String(),
    );
    _log.info(mapHeaderInfo.toString());
    _log.info("zoomLevel: $zoomlevelRange");
  }

  @override
  String toString() {
    return 'MapFileHeader{mapFileInfo: $mapHeaderInfo, subFileParameters: $subFileParameters, zoomlevelRange: $zoomlevelRange}';
  }
}
