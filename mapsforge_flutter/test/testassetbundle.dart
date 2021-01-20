import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    String prefix = "test_resources";
    if (!File("$prefix/arrow.png").existsSync()) {
      prefix = "../test_resources";
    }
    File file = File('$prefix/$key');
    Uint8List content = file.readAsBytesSync();
    if (content == null) throw Exception("Ressource $prefix / $key not found");
    return Future.value(ByteData.view(content.buffer));
  }

  String correctFilename(String key) {
    String prefix = "test_resources";
    if (!File("$prefix/arrow.png").existsSync()) {
      prefix = "../test_resources";
    }
    return prefix + "/$key";
  }
}
