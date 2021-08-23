import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  final bool isOnlineMap;

  /// Sets the level overlay for indoor maps.
  /// Requires the [indoorLevels] parameter.
  final bool indoorZoomOverlay;
  /// Defines the levels and their names of an indoor map.
  /// Requires the [indoorZoomOverlay] parameter.
  final Map<int, String>? indoorLevels;

  MapFileData({
    required this.url,
    required this.fileName,
    required this.displayedName,
    required this.initialPositionLat,
    required this.initialPositionLong,
    this.theme = "assets/custom.xml",
    this.relativePathPrefix,
    this.initialZoomLevel = 16,
    this.indoorZoomOverlay = false,
    this.indoorLevels,
  }) : isOnlineMap = false;

  MapFileData.online({
    required this.displayedName,
    required this.initialPositionLat,
    required this.initialPositionLong,
    this.initialZoomLevel = 14,
    this.indoorZoomOverlay = false,
    this.indoorLevels,
  })  : url = "online",
        fileName = "online",
        theme = "online",
        relativePathPrefix = null,
        isOnlineMap = true;

  /// Finds the local directory of the stored map file.
  Future<String> getLocalFilePath() async {
    Directory dir = await getApplicationDocumentsDirectory();
    return dir.path + "/" + fileName;
  }

  /// Checks whether a map file already exists.
  Future<bool> fileExists() async {
    String filePath = await getLocalFilePath();
    return await File(filePath).exists();
  }
}
