import 'dart:typed_data';

import 'package:mapsforge_flutter_core/src/buffer/readbuffer.dart';
import 'package:mapsforge_flutter_core/src/buffer/readbuffer_source.dart';

/// A `ReadbufferSource` that reads from an in-memory `Uint8List`.
class ReadbufferMemory extends ReadbufferSource {
  final Uint8List content;

  int _lastOffset = 0;

  /// Creates a new `ReadbufferMemory` with the given [content].
  ReadbufferMemory(this.content);

  /// Clears the content of the buffer.
  @override
  void dispose() {
    content.clear();
  }

  /// Returns the total length of the buffer.
  @override
  Future<int> length() {
    return Future.value(content.length);
  }

  /// Reads a block of data from the buffer at a specific position.
  @override
  Future<Readbuffer> readFromFileAt(int indexBlockPosition, int indexBlockSize) {
    Uint8List c = content.sublist(indexBlockPosition, indexBlockPosition + indexBlockSize);
    return Future.value(Readbuffer(c, indexBlockPosition));
  }

  @override
  Future<Readbuffer> readFromFileAtMax(int indexBlockPosition, int indexBlockSize) {
    Uint8List c = content.sublist(indexBlockPosition, indexBlockPosition + indexBlockSize);
    return Future.value(Readbuffer(c, indexBlockPosition));
  }

  /// Reads a block of data of the given [length] from the current position.
  @override
  Future<Readbuffer> readFromFile(int length) {
    Uint8List cont = content.sublist(_lastOffset, _lastOffset + length);
    assert(cont.length == length);
    Readbuffer result = Readbuffer(cont, _lastOffset);
    _lastOffset += length;
    return Future.value(result);
  }

  /// Returns the current read position in the buffer.
  @override
  int getPosition() {
    return _lastOffset;
  }

  /// Sets the current read position in the buffer.
  @override
  Future<void> setPosition(int position) {
    _lastOffset = position;
    return Future.value();
  }

  /// Returns the content of the buffer as a stream.
  @override
  Stream<List<int>> get inputStream {
    return Stream.value(content);
  }

  /// This implementation has no resources to free.
  @override
  Future<void> freeRessources() async {}
}
