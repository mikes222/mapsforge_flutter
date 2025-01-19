import 'dart:typed_data';

import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';

class ReadbufferMemory extends ReadbufferSource {
  final Uint8List content;

  int _lastOffset = 0;

  ReadbufferMemory(this.content);

  @override
  void close() {}

  @override
  Future<int> length() {
    return Future.value(content.length);
  }

  @override
  Future<Uint8List> readDirect(int indexBlockPosition, int indexBlockSize) {
    return Future.value(content.sublist(
        indexBlockPosition, indexBlockPosition + indexBlockSize));
  }

  @override
  Future<Readbuffer> readFromFile({int? offset, required int length}) {
    Uint8List cont = content.sublist(
        offset ?? _lastOffset, (offset ?? _lastOffset) + length);
    assert(cont.length == length);
    Readbuffer result = Readbuffer(cont, offset ?? _lastOffset);
    _lastOffset = (offset ?? _lastOffset) + length;
    return Future.value(result);
  }
}
