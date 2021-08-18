import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

class MapFileData {
  final String url;
  final String fileName;
  final String displayedName;
  final double initialPositionLat;
  final double initialPositionLong;
  final int initialZoomLevel;

  MapFileData({
    @required this.url,
    @required this.fileName,
    @required this.displayedName,
    @required this.initialPositionLat,
    @required this.initialPositionLong,
    this.initialZoomLevel = 18,
  });

  Future<String> getLocalFilePath() async {
    Directory dir = await getApplicationDocumentsDirectory();
    return dir.path + "/" + fileName;
  }

  Future<bool> fileExists() async {
    String filePath = await getLocalFilePath();
    return await File(filePath).exists();
  }
}
