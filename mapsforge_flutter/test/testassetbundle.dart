import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) {
    File file = File('test_resources/$key');
    Uint8List content = file.readAsBytesSync();
    if (content == null) throw Exception("Ressource $key not found in folder 'test_resources'");
    return Future.value(ByteData.view(content.buffer));
  }
}
