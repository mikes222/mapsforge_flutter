import 'dart:typed_data';

import 'package:mapsforge_flutter_core/src/buffer/deserializer.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  final Pattern splitPattern = ("|");

  test('Should read 8-byte integer from buffer', () {
    Uint8List content = Uint8List.fromList([0x0, 0x0, 0x1, 0x73, 0x3a, 0x46, 0x78, 0x8a]);
    int result = Deserializer.getLong(content, 0);
    expect(result, 0x1733a46788a);
    expect(result, 1594410563722);
  });
}
