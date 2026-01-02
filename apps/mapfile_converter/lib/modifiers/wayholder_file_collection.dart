import 'dart:io';
import 'dart:typed_data';

import 'package:mapfile_converter/modifiers/cachefile.dart';
import 'package:mapfile_converter/modifiers/wayholder_id_file_collection.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class WayholderFileCollection implements IWayholderCollection {
  static const int _spillBatchSize = 100000;

  final List<Object> _entries = [];

  final List<int> _pendingSpillIndexes = [];

  final CacheFile cacheFile = CacheFile();

  String filename;

  SinkWithCounter? _sinkWithCounter;

  ReadbufferSource? _readbufferFile;

  WayholderFileCollection({required this.filename});

  Future<void> mergeFrom(WayholderIdFileCollection other) async {
    int expected = _entries.length + other.length;

    final batch = <Wayholder>[];

    await other.forEach((_, wayholder) {
      batch.add(wayholder);
      if (batch.length >= _spillBatchSize) {
        addAll(batch);
        batch.clear();
      }
    });

    if (batch.isNotEmpty) {
      addAll(batch);
    }
    assert(_entries.length == expected);
  }

  @override
  int get length => _entries.length;

  @override
  bool get isEmpty => _entries.isEmpty;

  Future<void> _closeFiles() async {
    await _readbufferFile?.freeRessources();
    _readbufferFile = null;

    await _sinkWithCounter?.close();
    _sinkWithCounter = null;
    _pendingSpillIndexes.clear();
    try {
      // delete even if _sink was already closed
      File(filename).deleteSync();
    } on PathNotFoundException catch (_) {
      // do nothing
    } catch (error) {
      print("Cannot delete $filename: $error");
    }
  }

  @override
  Future<void> dispose() async {
    await _closeFiles();
    _entries.clear();
    _pendingSpillIndexes.clear();
  }

  @override
  int add(Wayholder wayholder) {
    _entries.add(wayholder);
    final idx = _entries.length - 1;

    // if (wayholder.nodeCount() <= 5) {
    //   return idx;
    // }

    _pendingSpillIndexes.add(idx);
    _flushPendingToDiskIfNeeded();
    return idx;
  }

  @override
  void addAll(Iterable<Wayholder> wayholders) {
    if (wayholders.isEmpty) return;

    for (final w in wayholders) {
      add(w);
    }
  }

  Future<Wayholder> get(int index) async {
    final entry = _entries[index];
    if (entry is Wayholder) return entry;
    return _fromFile(entry as _Temp);
  }

  @override
  Future<List<Wayholder>> getAll() async {
    final result = <Wayholder>[];
    for (int i = 0; i < _entries.length; i++) {
      result.add(await get(i));
    }
    return result;
  }

  Future<void> _loadIntoMemory() async {
    for (int index = 0; index < _entries.length; index++) {
      final entry = _entries[index];
      if (entry is Wayholder) continue;
      Wayholder wayholder = await _fromFile(entry as _Temp);
      _entries[index] = wayholder;
    }
    await _closeFiles();
  }

  @override
  Future<void> forEach(void Function(Wayholder wayholder) action) async {
    for (int i = 0; i < _entries.length; i++) {
      action(await get(i));
    }
  }

  @override
  Future<void> removeWhere(bool Function(Wayholder wayholder) test) async {
    for (int i = 0; i < _entries.length; i++) {
      Wayholder entry = await get(i);
      if (test(entry)) {
        _entries.removeAt(i);
        i--;
      }
    }
  }

  void _flushPendingToDiskIfNeeded() {
    if (_pendingSpillIndexes.length < _spillBatchSize) return;
    _flushPendingToDisk();
  }

  void _flushPendingToDisk() {
    if (_pendingSpillIndexes.isEmpty) return;

    _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite(mode: FileMode.writeOnly));

    final batchBytes = BytesBuilder(copy: false);
    final batchLengths = <int>[];
    final batchIndexes = <int>[];

    for (int i = 0; i < _spillBatchSize && _pendingSpillIndexes.isNotEmpty; i++) {
      final idx = _pendingSpillIndexes.removeAt(0);
      final entry = _entries[idx];
      if (entry is! Wayholder) {
        continue;
      }

      final bytes = cacheFile.toFile(entry);
      batchBytes.add(bytes);
      batchLengths.add(bytes.length);
      batchIndexes.add(idx);
    }

    if (batchIndexes.isEmpty) return;

    final batchStartPos = _sinkWithCounter!.written;
    _sinkWithCounter!.add(batchBytes.toBytes());

    int offset = 0;
    for (int i = 0; i < batchIndexes.length; i++) {
      final len = batchLengths[i];
      _entries[batchIndexes[i]] = _Temp(pos: batchStartPos + offset, length: len);
      offset += len;
    }
  }

  Future<Wayholder> _fromFile(_Temp temp) async {
    _readbufferFile ??= createReadbufferSource(filename);
    await _sinkWithCounter?.flush();

    final readbuffer = await _readbufferFile!.readFromFileAt(temp.pos, temp.length);
    final uint8list = readbuffer.getBuffer(0, temp.length);
    assert(uint8list.length == temp.length);

    return cacheFile.fromFile(uint8list);
  }

  @override
  Future<void> countTags(TagholderModel model) async {
    for (int index = 0; index < _entries.length; index++) {
      Wayholder wayholder = await get(index);
      wayholder.tagholderCollection.reconnectWayTags(model);
      wayholder.tagholderCollection.countTags();
    }
  }

  @override
  Future<int> nodeCount() async {
    int result = 0;
    await forEach((action) {
      result += action.nodeCount();
    });
    return result;
  }

  @override
  Future<int> pathCount() async {
    int result = 0;
    await forEach((action) {
      result += action.pathCount();
    });
    return result;
  }

  @override
  void writeWaydata(Writebuffer writebuffer, bool debugFile, Tile tile, double tileLatitude, double tileLongitude, List<String> languagesPreferences) {
    throw UnimplementedError();
  }

  /// Frees resources that cannot be transferred to an isolate.
  ///
  /// This is typically called before sending the `ReadbufferSource` to another isolate.
  @override
  Future<void> freeRessources() async {
    await _readbufferFile?.freeRessources();
    _readbufferFile = null;
    await _sinkWithCounter?.close();
    _sinkWithCounter = null;
  }
}

//////////////////////////////////////////////////////////////////////////////

class _Temp {
  final int pos;
  final int length;

  _Temp({required this.pos, required this.length});
}
