import 'dart:typed_data';

import 'package:mapsforge_flutter/src/mapfile/readbuffer.dart';
import 'package:mapsforge_flutter/src/mapfile/readbuffersource.dart';

class ReadbufferMemory extends ReadbufferSource {
  final Uint8List content;

  int _lastOffset = 0;

  ReadbufferMemory(this.content);

  @override
  void dispose() {
    content.clear();
  }

  @override
  Future<int> length() {
    return Future.value(content.length);
  }

  @override
  Future<Readbuffer> readFromFileAt(int indexBlockPosition, int indexBlockSize) {
    Uint8List c = content.sublist(indexBlockPosition, indexBlockPosition + indexBlockSize);
    return Future.value(Readbuffer(c, indexBlockPosition));
  }

  @override
  Future<Readbuffer> readFromFile(int length) {
    Uint8List cont = content.sublist(_lastOffset, _lastOffset + length);
    assert(cont.length == length);
    Readbuffer result = Readbuffer(cont, _lastOffset);
    _lastOffset += length;
    return Future.value(result);
  }

  int getPosition() {
    return _lastOffset;
  }

  @override
  Future<void> setPosition(int position) {
    _lastOffset = position;
    return Future.value();
  }

  @override
  Stream<List<int>> get inputStream {
    return Stream.value(content);
  }

  @override
  void freeRessources() {}
}
