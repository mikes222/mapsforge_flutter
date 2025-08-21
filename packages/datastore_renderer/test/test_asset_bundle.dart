import 'dart:io';

import 'package:flutter/services.dart';

class TestAssetBundle extends PlatformAssetBundle {
  final String prefix;

  TestAssetBundle(this.prefix);

  @override
  Future<ByteData> load(String key) async {
    print("Loading $key");
    File file = File('$prefix/$key');
    Uint8List content = file.readAsBytesSync();
    return ByteData.view(content.buffer);

    // Unrecognized key, default to normal loading behavior.
    return super.load(key);
  }
}
