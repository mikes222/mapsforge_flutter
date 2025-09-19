import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_debug.dart';

/// A data holder for the complete, parsed metadata of a map file.
///
/// This class combines the high-level [MapHeaderInfo] with the detailed
/// parameters of each [SubFileParameter], providing a complete overview of the
/// map file's structure and contents.
class MapfileInfo {
  static final _log = Logger('MapFileHeader');

  /// A single whitespace character.
  static final String SPACE = ' ';

  final MapHeaderInfo mapHeaderInfo;

  final Map<int, SubFileParameter> subFileParameters;

  final ZoomlevelRange zoomlevelRange;

  MapfileInfo(this.mapHeaderInfo, this.subFileParameters, this.zoomlevelRange);

    /// Returns the high-level metadata for this map file.
  MapHeaderInfo getMapHeaderInfo() {
    // execute the init() method before using mapfiles
    return mapHeaderInfo;
  }

    /// Returns the closest zoom level that is actually available in the map file
  /// for a given requested [zoomlevel].
  int getQueryZoomLevel(int zoomlevel) {
    return zoomlevelRange.ensureBounds(zoomlevel);
  }

    /// Returns the [SubFileParameter] for a given [queryZoomLevel].
  ///
  /// The [queryZoomLevel] should be a value that is supported by the map file
  /// (i.e., a value returned by [getQueryZoomLevel]).
  SubFileParameter? getSubFileParameter(int queryZoomLevel) {
    return subFileParameters[queryZoomLevel];
  }

  void debug() {
    _log.info(
      "mapfile is version ${mapHeaderInfo.fileVersion} from ${DateTime.fromMillisecondsSinceEpoch(mapHeaderInfo.mapDate!, isUtc: true).toIso8601String()}",
    );
    _log.info(mapHeaderInfo.toString());
    _log.info("zoomLevel: $zoomlevelRange");
  }

  @override
  String toString() {
    return 'MapFileHeader{mapFileInfo: $mapHeaderInfo, subFileParameters: $subFileParameters, zoomlevelRange: $zoomlevelRange}';
  }
}
