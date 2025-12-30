import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:mapfile_converter/modifiers/cachefile.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class WayholderFileCollection {
  final Map<int, Wayholder> _collection = HashMap();

  final Map<int, _Temp> _tempCollection = HashMap();

  String filename;

  SinkWithCounter? _sinkWithCounter;

  ReadbufferSource? _readbufferFile;

  final CacheFile cacheFile = CacheFile();

  int _count = 0;

  final Set<int> wayNotFound = {};

  WayholderFileCollection({required this.filename});

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
    _count = 0;
  }

  int get length => _count;

  Future<void> forEach(void Function(int key, Wayholder value) action) async {
    _collection.forEach((key, wayholder) {
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
    _toFile(id, wayholder);
  }

  void change(int id, Wayholder wayholder) {
    if (_collection.containsKey(id)) {
      _collection[id] = wayholder;
    } else {
      _tempCollection.remove(id);
      --_count;
      add(id, wayholder);
    }
  }

  void remove(int id) {
    _collection.remove(id);
    _tempCollection.remove(id);
    --_count;
  }

  Future<Wayholder?> tryGet(int id) {
    Wayholder? wayholder = _collection[id];
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
    return _fromFile(id);
  }

  Future<List<Wayholder>> getAll() async {
    List<Wayholder> result = [];
    result.addAll(_collection.values);
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
    for (var entry in _tempCollection.entries) {
      if (entry.value.mergedWithOtherWay) result[entry.key] = await get(entry.key);
    }
    return result;
  }

  void _toFile(int id, Wayholder wayholder) {
    bool coastLine = false;
    if (wayholder.hasTagValue("natural", "coastline")) {
      coastLine = true;
    }
    Uint8List uint8list = cacheFile.toFile(wayholder);
    _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite());
    int pos = _sinkWithCounter!.written;
    _sinkWithCounter!.add(uint8list);
    _Temp temp = _Temp(pos: pos, length: uint8list.length, coastLine: coastLine, mergedWithOtherWay: wayholder.mergedWithOtherWay);
    _tempCollection[id] = temp;
    ++_count;
  }

  Future<Wayholder> _fromFile(int id) async {
    _Temp temp = _tempCollection[id]!;
    _readbufferFile ??= createReadbufferSource(filename);
    await _sinkWithCounter!.flush();
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
