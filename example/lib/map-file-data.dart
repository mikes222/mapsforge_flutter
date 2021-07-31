import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  final bool indoorZoomOverlay;

  MapFileData({
    required this.url,
    required this.fileName,
    required this.displayedName,
    required this.initialPositionLat,
    required this.initialPositionLong,
    this.theme = "assets/custom.xml",
    this.relativePathPrefix,
    this.initialZoomLevel = 16,
    this.indoorZoomOverlay = true,
  }) : isOnlineMap = false;

  MapFileData.online({
    required this.displayedName,
    required this.initialPositionLat,
    required this.initialPositionLong,
    this.initialZoomLevel = 14,
    this.indoorZoomOverlay = true,
  })  : url = "online",
        fileName = "online",
        theme = "online",
        relativePathPrefix = null,
        isOnlineMap = true;

  Future<String> getLocalFilePath() async {
    Directory dir = await getApplicationDocumentsDirectory();
    return dir.path + "/" + fileName;
  }

  Future<bool> fileExists() async {
    String filePath = await getLocalFilePath();
    return await File(filePath).exists();
  }
}
