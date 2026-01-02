import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:mapfile_converter/modifiers/cachefile.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class WayholderIdFileCollection {
  final Map<int, Wayholder> _collection = HashMap();

  final Map<int, _Temp> _tempCollection = HashMap();

  final Map<int, Wayholder> _pendingTempCollection = HashMap();

  final List<int> _pendingTempOrder = [];

  static const int _spillBatchSize = 1000;

  String filename;

  SinkWithCounter? _sinkWithCounter;

  ReadbufferSource? _readbufferFile;

  final CacheFile cacheFile = CacheFile();

  int _count = 0;

  final Set<int> wayNotFound = {};

  WayholderIdFileCollection({required this.filename});

  Future<void> mergeFrom(WayholderIdFileCollection other) async {
    if (identical(this, other)) return;

    if (other._sinkWithCounter != null) {
      await other._sinkWithCounter!.flush();
    }

    // Add all in-memory items.
    for (final entry in other._collection.entries) {
      final id = entry.key;
      remove(id);
      add(id, entry.value);
    }

    // Add all pending (not yet flushed) items.
    for (final entry in other._pendingTempCollection.entries) {
      final id = entry.key;
      remove(id);
      add(id, entry.value);
    }

    // Copy already spilled items by copying raw bytes.
    if (other._tempCollection.isNotEmpty) {
      ReadbufferSource? otherReadbufferFile = other._readbufferFile;

      otherReadbufferFile ??= createReadbufferSource(other.filename);

      _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite(mode: FileMode.append));

      for (final entry in other._tempCollection.entries) {
        final id = entry.key;
        final temp = entry.value;

        remove(id);

        final readbuffer = await otherReadbufferFile.readFromFileAt(temp.pos, temp.length);
        final bytes = readbuffer.getBuffer(0, temp.length);
        assert(bytes.length == temp.length);

        final destPos = _sinkWithCounter!.written;
        _sinkWithCounter!.add(bytes);

        _tempCollection[id] = _Temp(pos: destPos, length: temp.length, coastLine: temp.coastLine, mergedWithOtherWay: temp.mergedWithOtherWay);
        ++_count;
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
    _pendingTempCollection.clear();
    _pendingTempOrder.clear();
    _count = 0;
  }

  int get length => _count;

  Future<void> forEach(void Function(int key, Wayholder value) action) async {
    _collection.forEach((key, wayholder) {
      action(key, wayholder);
    });
    _pendingTempCollection.forEach((key, wayholder) {
      action(key, wayholder);
    });
    for (int key in _tempCollection.keys) {
      action(key, await get(key));
    }
  }

  Future<void> forEachOnline(void Function(int key, Wayholder value) action) async {
    _collection.forEach((key, wayholder) {
      action(key, wayholder);
    });
    _pendingTempCollection.forEach((key, wayholder) {
      action(key, wayholder);
    });
  }

  // Future<void> forEachOffline(void Function(int key, BoundingBox boundingBox) action) async {
  //   for (var entry in _tempCollection.entries) {
  //     action(entry.key, entry.value.wayBoundingBox!);
  //   }
  // }

  void add(int id, Wayholder wayholder) {
    if (wayholder.nodeCount() <= 5) {
      // keep small ways in memory
      _collection[id] = wayholder;
      ++_count;
      return;
    }
    assert(!_tempCollection.containsKey(id));
    _toPending(id, wayholder);
  }

  void change(int id, Wayholder wayholder) {
    if (_collection.containsKey(id)) {
      _collection[id] = wayholder;
    } else if (_pendingTempCollection.containsKey(id)) {
      _pendingTempCollection[id] = wayholder;
    } else {
      _tempCollection.remove(id);
      --_count;
      add(id, wayholder);
    }
  }

  void remove(int id) {
    bool removed = false;

    if (_collection.remove(id) != null) {
      removed = true;
    }

    if (_pendingTempCollection.remove(id) != null) {
      _pendingTempOrder.remove(id);
      removed = true;
    }

    if (_tempCollection.remove(id) != null) {
      removed = true;
    }

    if (removed) {
      --_count;
    }
  }

  Future<Wayholder?> tryGet(int id) {
    Wayholder? wayholder = _collection[id];
    if (wayholder != null) return Future.value(wayholder);

    wayholder = _pendingTempCollection[id];
    if (wayholder != null) return Future.value(wayholder);

    _Temp? temp = _tempCollection[id];
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

    wayholder = _pendingTempCollection[id];
    if (wayholder != null) return Future.value(wayholder);

    return _fromFile(id);
  }

  Future<List<Wayholder>> getAll() async {
    List<Wayholder> result = [];
    result.addAll(_collection.values);
    result.addAll(_pendingTempCollection.values);
    for (int key in _tempCollection.keys) {
      result.add(await get(key));
    }
    return result;
  }

  Future<Map<int, Wayholder>> getAllCoastline() async {
    HashMap<int, Wayholder> result = HashMap();
    _collection.forEach((key, value) {
      if (value.hasTagValue("natural", "coastline")) result[key] = value;
    });
    _pendingTempCollection.forEach((key, value) {
      if (value.hasTagValue("natural", "coastline")) result[key] = value;
    });
    for (var entry in _tempCollection.entries) {
      if (entry.value.coastLine) result[entry.key] = await get(entry.key);
    }
    return result;
  }

  Future<Map<int, Wayholder>> getAllMergedWithOtherWay() async {
    HashMap<int, Wayholder> result = HashMap();
    _collection.forEach((key, value) {
      if (value.mergedWithOtherWay) result[key] = value;
    });
    _pendingTempCollection.forEach((key, value) {
      if (value.mergedWithOtherWay) result[key] = value;
    });
    for (var entry in _tempCollection.entries) {
      if (entry.value.mergedWithOtherWay) result[entry.key] = await get(entry.key);
    }
    return result;
  }

  void _toPending(int id, Wayholder wayholder) {
    assert(!_pendingTempCollection.containsKey(id));
    _pendingTempCollection[id] = wayholder;
    _pendingTempOrder.add(id);
    ++_count;
    _flushPendingToDiskIfNeeded();
  }

  void _flushPendingToDiskIfNeeded() {
    if (_pendingTempOrder.length < _spillBatchSize) return;
    _flushPendingToDisk();
  }

  void _flushPendingToDisk() {
    if (_pendingTempOrder.isEmpty) return;

    _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite(mode: FileMode.append));

    final batchBytes = BytesBuilder(copy: false);
    final batchLengths = <int>[];
    final batchIds = <int>[];
    final batchCoastline = <bool>[];
    final batchMerged = <bool>[];

    for (int i = 0; i < _spillBatchSize && _pendingTempOrder.isNotEmpty; i++) {
      final id = _pendingTempOrder.removeAt(0);
      final wayholder = _pendingTempCollection.remove(id);
      if (wayholder == null) continue;

      final bytes = cacheFile.toFile(wayholder);
      batchBytes.add(bytes);
      batchLengths.add(bytes.length);
      batchIds.add(id);
      batchCoastline.add(wayholder.hasTagValue("natural", "coastline"));
      batchMerged.add(wayholder.mergedWithOtherWay);
    }

    if (batchIds.isEmpty) return;

    final batchStartPos = _sinkWithCounter!.written;
    _sinkWithCounter!.add(batchBytes.toBytes());

    int offset = 0;
    for (int i = 0; i < batchIds.length; i++) {
      final len = batchLengths[i];
      _tempCollection[batchIds[i]] = _Temp(pos: batchStartPos + offset, length: len, coastLine: batchCoastline[i], mergedWithOtherWay: batchMerged[i]);
      offset += len;
    }
  }

  Future<Wayholder> _fromFile(int id) async {
    _Temp temp = _tempCollection[id]!;
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
