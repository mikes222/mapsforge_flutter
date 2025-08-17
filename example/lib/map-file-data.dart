/// A container to store map files and handle their information.
class MapFileData {
  final String url;
  final String fileName;
  final String displayedName;
  final String theme;
  final double initialPositionLat;
  final double initialPositionLong;
  final int initialZoomLevel;
  final String? relativePathPrefix;
  final MAPTYPE mapType;

  /// Sets the level overlay for indoor maps.
  /// Requires the [indoorLevels] parameter.
  final bool indoorZoomOverlay;

  /// Defines the levels and their names of an indoor map.
  /// Requires the [indoorZoomOverlay] parameter.
  final Map<int, String>? indoorLevels;

  const MapFileData({
    required this.url,
    required this.fileName,
    required this.displayedName,
    required this.initialPositionLat,
    required this.initialPositionLong,
    this.theme = "assets/render_themes/custom.xml",
    this.relativePathPrefix,
    this.initialZoomLevel = 16,
    this.indoorZoomOverlay = false,
    this.indoorLevels,
  }) : mapType = MAPTYPE.OFFLINE;

  MapFileData.online({
    required this.displayedName,
    required this.initialPositionLat,
    required this.initialPositionLong,
    this.initialZoomLevel = 14,
    this.indoorZoomOverlay = false,
    this.indoorLevels,
  })  : url = "unused",
        fileName = "unused",
        theme = "online",
        relativePathPrefix = null,
        mapType = MAPTYPE.OSM;

  MapFileData.onlineSatellite({
    required this.displayedName,
    required this.initialPositionLat,
    required this.initialPositionLong,
    this.initialZoomLevel = 14,
    this.indoorZoomOverlay = false,
    this.indoorLevels,
  })  : url = "unused",
        fileName = "unused",
        theme = "unused",
        relativePathPrefix = null,
        mapType = MAPTYPE.ARCGIS;
}

/////////////////////////////////////////////////////////////////////////////

enum MAPTYPE {
  // No Onlinemap --> We use offline-maps
  OFFLINE,
  // OpenStreetMap
  OSM,
  // ArcGis Map
  ARCGIS,
}
