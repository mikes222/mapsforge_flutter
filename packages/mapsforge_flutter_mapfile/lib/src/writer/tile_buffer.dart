import 'dart:io';
import 'dart:typed_data';

import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/writebuffer.dart';

class TileBuffer {
  final Map<Tile, Uint8List> _writebufferForTiles = {};

  final Map<Tile, _TempfileIndex> _indexes = {};

  final Map<Tile, int> _sizes = {};

  SinkWithCounter? _ioSink;

  ReadbufferSource? _readbufferFile;

  late final String _filename;

  int _length = 0;

  TileBuffer(int baseZoomlevel) {
    _filename = "tiles_${DateTime.now().millisecondsSinceEpoch}_$baseZoomlevel.tmp";
  }

  void dispose() {
    _ioSink?.close();
    _readbufferFile?.dispose();
    try {
      File(_filename).deleteSync();
    } catch (_) {
      // do nothing
    }
    _writebufferForTiles.clear();
    _indexes.clear();
    _sizes.clear();
    _length = 0;
  }

  void set(Tile tile, Uint8List content) {
    _writebufferForTiles[tile] = content;
    _sizes[tile] = content.length;
    _length += content.length;
  }

  /// Returns the content of the tile. Assumes that the order of retrieval is exactly
  /// the same as the order of storage.
  Future<Uint8List> get(Tile tile) async {
    Uint8List? result = _writebufferForTiles[tile];
    if (result != null) return result;

    await writeComplete();
    if (_readbufferFile != null) {
      _TempfileIndex tempfileIndex = _indexes[tile]!;
      Readbuffer readbuffer = await _readbufferFile!.readFromFileAt(tempfileIndex.position, tempfileIndex.length);
      return readbuffer.getBuffer(0, tempfileIndex.length);
    }
    return _writebufferForTiles[tile]!;
  }

  Future<Uint8List> getAndRemove(Tile tile) async {
    Uint8List? result = _writebufferForTiles.remove(tile);
    if (result != null) {
      _sizes.remove(tile);
      return result;
    }
    assert(_ioSink != null || _readbufferFile != null);
    await writeComplete();
    assert(_readbufferFile != null);
    _TempfileIndex? tempfileIndex = _indexes[tile];
    assert(tempfileIndex != null, "indexes for $tile not found");
    Readbuffer readbuffer = await _readbufferFile!.readFromFileAt(tempfileIndex!.position, tempfileIndex.length);
    result = readbuffer.getBuffer(0, tempfileIndex.length);
    _sizes.remove(tile);
    _indexes.remove(tile);
    //if (_indexes.isEmpty) dispose();
    return result;
  }

  int getLength(Tile tile) {
    return _sizes[tile]!;
  }

  void cacheToDisk(int processedTiles, int sumTiles) {
    if (_writebufferForTiles.isEmpty) return;
    // less than 10MB? keep in memory
    if (_length < 10000000) return;
    _ioSink ??= SinkWithCounter(File(_filename).openWrite());
    _writebufferForTiles.forEach((tile, content) {
      _TempfileIndex tempfileIndex = _TempfileIndex(_ioSink!.written, content.length);
      _indexes[tile] = tempfileIndex;
      _ioSink!.add(content);
    });
    _writebufferForTiles.clear();
    _length = 0;
  }

  Future<void> writeComplete() async {
    if (_ioSink != null) {
      // close the writing and start reading
      await _ioSink?.close();
      _ioSink = null;
      _readbufferFile = createReadbufferSource(_filename);
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class _TempfileIndex {
  final int position;

  final int length;

  _TempfileIndex(this.position, this.length);
}
