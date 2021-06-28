import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MapFileData {
  final String url;
  final String fileName;
  final String name;
  final String theme;
  final double initialPositionLat;
  final double initialPositionLong;
  final int initialZoomLevel;
  final String? relativePathPrefix;
  final bool onlinemap;

  MapFileData(this.url, this.fileName, this.name, this.theme, this.relativePathPrefix, this.initialPositionLat, this.initialPositionLong,
      this.initialZoomLevel)
      : onlinemap = false;

  MapFileData.online(this.name, this.initialPositionLat, this.initialPositionLong, this.initialZoomLevel)
      : url = "online",
        fileName = "online",
        theme = "online",
        relativePathPrefix = null,
        onlinemap = true;

  Future<String> getLocalFilePath() async {
    Directory dir = await getApplicationDocumentsDirectory();
    return dir.path + "/" + fileName;
  }

  Future<bool> fileExists() async {
    String filePath = await getLocalFilePath();
    return await File(filePath).exists();
  }
}
