import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:mapfile_converter/modifiers/cachefile.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class WayholderIdFileCollection {
  final Map<int, Wayholder> _collection = HashMap();

  final Map<int, _Temp> _fileCollection = HashMap();

  static const int _spillBatchSize = 100000;

  String filename;

  SinkWithCounter? _sinkWithCounter;

  ReadbufferSource? _readbufferFile;

  final CacheFile cacheFile = CacheFile();

  final Set<int> wayNotFound = {};

  WayholderIdFileCollection({required this.filename});

  Future<void> mergeFrom(WayholderIdFileCollection other) async {
    if (identical(this, other)) return;

    await other._sinkWithCounter?.flush();

    // Add all in-memory items.
    for (final entry in other._collection.entries) {
      final id = entry.key;
      remove(id);
      add(id, entry.value);
    }

    // Copy already spilled items by copying raw bytes.
    if (other._fileCollection.isNotEmpty) {
      ReadbufferSource? otherReadbufferFile = other._readbufferFile;

      otherReadbufferFile ??= createReadbufferSource(other.filename);

      _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite(mode: FileMode.writeOnly));

      for (final entry in other._fileCollection.entries) {
        final id = entry.key;
        final temp = entry.value;

        remove(id);

        final readbuffer = await otherReadbufferFile.readFromFileAt(temp.pos, temp.length);
        final bytes = readbuffer.getBuffer(0, temp.length);
        assert(bytes.length == temp.length);

        final destPos = _sinkWithCounter!.written;
        _sinkWithCounter!.add(bytes);

        _fileCollection[id] = _Temp(pos: destPos, length: temp.length, coastLine: temp.coastLine, mergedWithOtherWay: temp.mergedWithOtherWay);
      }

      other._readbufferFile = otherReadbufferFile;
    }
  }

  void dispose() {
    _readbufferFile?.dispose();
    _readbufferFile = null;
    _sinkWithCounter?.close().then((a) {
      try {
        File(filename).deleteSync();
      } catch (_) {
        // do nothing
      } finally {}
    });
    _sinkWithCounter = null;
    _collection.clear();
    _fileCollection.clear();
  }

  int get length => _collection.length + _fileCollection.length;

  Future<void> forEach(void Function(int key, Wayholder value) action) async {
    _collection.forEach((key, wayholder) {
      action(key, wayholder);
    });
    await _sinkWithCounter?.flush();
    for (int key in _fileCollection.keys) {
      Wayholder wayholder = await _fromFile(key);
      action(key, wayholder);
    }
  }

  Future<Iterable<Wayholder>> getAllOnline() async {
    return _collection.values;
  }

  Future<void> forEachOffline(void Function(Uint8List content) action) async {
    if (_fileCollection.isEmpty) return;
    await _sinkWithCounter?.flush();
    _readbufferFile ??= createReadbufferSource(filename);
    Readbuffer? readbuffer;
    final int bufferLength = 1000000;
    List<_Temp> temps = _fileCollection.values.toList();
    temps.sort((a, b) => a.pos.compareTo(b.pos));
    for (var temp in temps) {
      if (readbuffer == null || readbuffer.offset > temp.pos || readbuffer.offset + readbuffer.getBufferSize() < temp.pos + temp.length) {
        //print("Way readFromFileAtMax ${temp.pos} ${temp.length}");
        readbuffer = await _readbufferFile!.readFromFileAtMax(temp.pos, bufferLength);
      }
      Uint8List uint8list = readbuffer.getBuffer(temp.pos - readbuffer.offset, temp.length);
      assert(uint8list.length == temp.length);
      action(uint8list);
    }
  }

  void add(int id, Wayholder wayholder) {
    // keep small ways in memory
    _collection[id] = wayholder;
    _flushPendingToDiskIfNeeded();
  }

  void change(int id, Wayholder wayholder) {
    if (_collection.containsKey(id)) {
      _collection[id] = wayholder;
    } else {
      _fileCollection.remove(id);
      add(id, wayholder);
    }
  }

  void remove(int id) {
    if (_collection.remove(id) != null) {}

    if (_fileCollection.remove(id) != null) {}
  }

  Future<Wayholder?> tryGet(int id) {
    Wayholder? wayholder = _collection[id];
    if (wayholder != null) return Future.value(wayholder);

    _Temp? temp = _fileCollection[id];
    if (temp == null) {
      if (wayNotFound.contains(id)) {
        return Future.value(null);
      }
      wayNotFound.add(id);
      return Future.value(null);
    }
    return _fromFile(id);
  }

  Future<Wayholder> get(int id) {
    Wayholder? wayholder = _collection[id];
    if (wayholder != null) return Future.value(wayholder);

    return _fromFile(id);
  }

  Future<List<Wayholder>> getAll() async {
    List<Wayholder> result = [];
    result.addAll(_collection.values);
    for (int key in _fileCollection.keys) {
      result.add(await get(key));
    }
    return result;
  }

  Future<Map<int, Wayholder>> getAllCoastline() async {
    HashMap<int, Wayholder> result = HashMap();
    _collection.forEach((key, value) {
      if (value.hasTagValue("natural", "coastline")) result[key] = value;
    });
    for (var entry in _fileCollection.entries) {
      if (entry.value.coastLine) result[entry.key] = await get(entry.key);
    }
    return result;
  }

  Future<Map<int, Wayholder>> getAllMergedWithOtherWay() async {
    HashMap<int, Wayholder> result = HashMap();
    _collection.forEach((key, value) {
      if (value.mergedWithOtherWay) result[key] = value;
    });
    for (var entry in _fileCollection.entries) {
      if (entry.value.mergedWithOtherWay) result[entry.key] = await get(entry.key);
    }
    return result;
  }

  void _flushPendingToDiskIfNeeded() {
    if (_collection.length < _spillBatchSize) return;

    _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite(mode: FileMode.writeOnly));

    final batchBytes = BytesBuilder(copy: false);
    final batchLengths = <int>[];
    final batchIds = <int>[];
    final batchCoastline = <bool>[];
    final batchMerged = <bool>[];

    for (int i = 0; i < _spillBatchSize; i++) {
      int id = _collection.keys.first;
      final wayholder = _collection.remove(id);
      if (wayholder == null) continue;

      final bytes = cacheFile.toFile(wayholder);
      batchBytes.add(bytes);
      batchLengths.add(bytes.length);
      batchIds.add(id);
      batchCoastline.add(wayholder.hasTagValue("natural", "coastline"));
      batchMerged.add(wayholder.mergedWithOtherWay);
    }

    final batchStartPos = _sinkWithCounter!.written;
    _sinkWithCounter!.add(batchBytes.toBytes());

    int offset = 0;
    for (int i = 0; i < batchIds.length; i++) {
      final len = batchLengths[i];
      _fileCollection[batchIds[i]] = _Temp(pos: batchStartPos + offset, length: len, coastLine: batchCoastline[i], mergedWithOtherWay: batchMerged[i]);
      offset += len;
    }
  }

  Future<Wayholder> _fromFile(int id) async {
    _Temp temp = _fileCollection[id]!;
    _readbufferFile ??= createReadbufferSource(filename);
    if (_sinkWithCounter != null) {
      await _sinkWithCounter!.flush();
    }
    Readbuffer readbuffer = await _readbufferFile!.readFromFileAt(temp.pos, temp.length);
    Uint8List uint8list = readbuffer.getBuffer(0, temp.length);
    assert(uint8list.length == temp.length);
    Wayholder wayholder = cacheFile.fromFile(uint8list);
    return wayholder;
  }
}

//////////////////////////////////////////////////////////////////////////////

/// Reference to a way in the tempfile
class _Temp {
  final int pos;

  final int length;

  bool coastLine;

  bool mergedWithOtherWay;

  //BoundingBox? wayBoundingBox;

  _Temp({required this.pos, required this.length, required this.coastLine, required this.mergedWithOtherWay});
}
