import 'dart:io';
import 'dart:typed_data';

import 'package:mapsforge_flutter_core/src/buffer/readbuffer_file_io.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late String path;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('readbuffer_file_');
    path = '${tmp.path}/data.bin';
    await File(path).writeAsBytes(Uint8List.fromList(List.generate(64 * 1024, (i) => i & 0xff)));
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('freeRessources while reads are in flight does not throw', () async {
    final source = ReadbufferFile(path);
    // Warm the pool with concurrent positional reads: 6 resources pooled.
    await Future.wait([for (var i = 0; i < 6; i++) source.readFromFileAt(i * 1024, 512)]);

    // Two reads take resources out of the pool (4 remain) and are still
    // awaiting the file when dispose starts: freeRessources awaits the
    // close of the 4 pooled ones, the 2 reads return meanwhile and hand
    // theirs back. Iterating the live queue would throw
    // ConcurrentModificationError; the snapshot does not, and the late
    // resources are closed when the reads return, not re-queued.
    final inFlight = [for (var i = 0; i < 2; i++) source.readFromFileAt(i * 2048, 1024)];
    final freeing = source.freeRessources();
    final buffers = await Future.wait(inFlight);
    await freeing;

    for (var i = 0; i < buffers.length; i++) {
      expect(buffers[i].getBuffer(0, 1024).length, 1024);
    }
  });

  test('the source can still be read after freeRessources', () async {
    // freeRessources is also called before sending the source to another
    // isolate, which then keeps reading from it.
    final source = ReadbufferFile(path);
    await source.readFromFileAt(0, 16);
    await source.freeRessources();
    final again = await source.readFromFileAt(1000, 4);
    expect(again.getBuffer(0, 4), [1000 & 0xff, 1001 & 0xff, 1002 & 0xff, 1003 & 0xff]);
    await source.setPosition(10);
    expect((await source.readFromFile(2)).getBuffer(0, 2), [10, 11]);
    await source.freeRessources();
  });

  test('freeRessources twice is harmless', () async {
    final source = ReadbufferFile(path);
    await source.readFromFileAt(0, 16);
    await source.freeRessources();
    await source.freeRessources();
  });
}
