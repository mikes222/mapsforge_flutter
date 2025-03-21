import 'dart:io';

import 'package:flutter/services.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    if (key.contains("packages/mapsforge_flutter/assets/"))
      key = key.replaceAll("packages/mapsforge_flutter/assets/", "");
    if (key.startsWith("jar:")) key = key.replaceAll("jar:", "/");
    String prefix = "test_resources";
    if (!File("$prefix/arrow.png").existsSync()) {
      prefix = "../test_resources";
    }
    File file = File('$prefix/$key');
    Uint8List content = file.readAsBytesSync();
    return Future.value(ByteData.view(content.buffer));
  }

  String correctFilename(String key) {
    String prefix = "test_resources";
    if (!File("$prefix/arrow.png").existsSync()) {
      prefix = "../test_resources";
    }
    return prefix + "/$key";
  }

  void delete(String key) {
    String prefix = "test_resources";
    if (!File("$prefix/arrow.png").existsSync()) {
      prefix = "../test_resources";
    }
    File file = File('$prefix/$key');
    file.deleteSync();
  }
}
