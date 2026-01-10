import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:mapfile_converter/modifiers/cachefile.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class WayholderIdFileCollection {
  final Map<int, Wayholder> _collection = HashMap();

  final Map<int, _WayIdTemp> _fileCollection = HashMap();

  final int spillBatchSize;

  String filename;

  SinkWithCounter? _sinkWithCounter;

  ReadbufferSource? _readbufferFile;

  final CacheFile cacheFile = CacheFile();

  final Set<int> wayNotFound = {};

  Readbuffer? readbuffer;

  final int bufferLength = 1000000;

  WayholderIdFileCollection({required this.filename, this.spillBatchSize = 100000});

  Future<void> dispose() async {
    _readbufferFile?.dispose();
    _readbufferFile = null;
    await _sinkWithCounter?.close().then((a) {
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

      Readbuffer? readbuffer;
      List<_WayIdTemp> temps = other._fileCollection.values.toList();
      temps.sort((a, b) => a.pos.compareTo(b.pos));
      for (final temp in temps) {
        remove(temp.id);

        if (readbuffer == null || readbuffer.offset > temp.pos || readbuffer.offset + readbuffer.getBufferSize() < temp.pos + temp.length) {
          //print("Way readFromFileAtMax ${temp.pos} ${temp.length}");
          readbuffer = await otherReadbufferFile.readFromFileAtMax(temp.pos, max(bufferLength, temp.length));
        }
        Uint8List uint8list = readbuffer.getBuffer(temp.pos - readbuffer.offset, temp.length);
        assert(uint8list.length == temp.length);

        final destPos = _sinkWithCounter!.written;
        _sinkWithCounter!.add(uint8list);

        _fileCollection[temp.id] = _WayIdTemp(
          id: temp.id,
          pos: destPos,
          length: temp.length,
          coastLine: temp.coastLine,
          mergedWithOtherWay: temp.mergedWithOtherWay,
        );
      }

      other._readbufferFile = otherReadbufferFile;
    }
  }

  Future<void> forEach(void Function(int key, Wayholder value) action) async {
    _collection.forEach((key, wayholder) {
      action(key, wayholder);
    });

    // await forEachOffline((uint8list) {
    //   Wayholder wayholder = cacheFile.fromFile(uint8list);
    //   action(key, wayholder);
    // });

    /// the keys are not sorted and therefore it may be slow
    List<_WayIdTemp> temps = _fileCollection.values.toList();
    temps.sort((a, b) => a.pos.compareTo(b.pos));
    for (var temp in temps) {
      Wayholder wayholder = await _fromFile(temp.id);
      action(temp.id, wayholder);
    }
  }

  Future<Iterable<Wayholder>> getAllOnline() async {
    return _collection.values;
  }

  Future<void> forEachOffline(void Function(Uint8List content) action) async {
    if (_fileCollection.isEmpty) return;
    _readbufferFile ??= createReadbufferSource(filename);
    Readbuffer? readbuffer;
    List<_WayIdTemp> temps = _fileCollection.values.toList();
    temps.sort((a, b) => a.pos.compareTo(b.pos));
    for (var temp in temps) {
      if (readbuffer == null || readbuffer.offset > temp.pos || readbuffer.offset + readbuffer.getBufferSize() < temp.pos + temp.length) {
        readbuffer = await _readbufferFile!.readFromFileAtMax(temp.pos, max(bufferLength, temp.length));
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
    if (_collection.remove(id) != null) {
      return;
    }

    if (_fileCollection.remove(id) != null) {
      return;
    }
  }

  Future<Wayholder?> tryGet(int id) async {
    Wayholder? wayholder = _collection[id];
    if (wayholder != null) return wayholder;

    _WayIdTemp? temp = _fileCollection[id];
    if (temp == null) {
      if (wayNotFound.contains(id)) {
        return null;
      }
      wayNotFound.add(id);
      return null;
    }
    await _sinkWithCounter?.flush();
    return _fromFile(id);
  }

  // Future<Wayholder> get(int id) async {
  //   Wayholder? wayholder = _collection[id];
  //   if (wayholder != null) return wayholder;
  //
  //   await _sinkWithCounter?.flush();
  //   return _fromFile(id);
  // }

  Future<List<Wayholder>> getAll() async {
    List<Wayholder> result = [];
    result.addAll(_collection.values);

    await _sinkWithCounter?.flush();

    List<_WayIdTemp> temps = _fileCollection.values.toList();
    temps.sort((a, b) => a.pos.compareTo(b.pos));
    for (var temp in temps) {
      Wayholder wayholder = await _fromFile(temp.id);
      result.add(wayholder);
    }
    return result;
  }

  Future<Map<int, Wayholder>> getAllCoastline() async {
    HashMap<int, Wayholder> result = HashMap();
    _collection.forEach((key, value) {
      if (value.hasTagValue("natural", "coastline")) result[key] = value;
    });

    await _sinkWithCounter?.flush();

    Readbuffer? readbuffer;
    List<_WayIdTemp> temps = _fileCollection.values.where((test) => test.coastLine).toList();
    temps.sort((a, b) => a.pos.compareTo(b.pos));
    for (var temp in temps) {
      if (readbuffer == null || readbuffer.offset > temp.pos || readbuffer.offset + readbuffer.getBufferSize() < temp.pos + temp.length) {
        readbuffer = await _readbufferFile!.readFromFileAtMax(temp.pos, max(bufferLength, temp.length));
      }
      Uint8List uint8list = readbuffer.getBuffer(temp.pos - readbuffer.offset, temp.length);
      assert(uint8list.length == temp.length);
      Wayholder wayholder = cacheFile.fromFile(uint8list);
      result[temp.id] = wayholder;
    }
    return result;
  }

  Future<void> removeAllMergedWithOtherWay() async {
    _collection.removeWhere((key, test) => test.mergedWithOtherWay);
    _fileCollection.removeWhere((key, value) => value.mergedWithOtherWay);
  }

  void _flushPendingToDiskIfNeeded() {
    if (_collection.length < spillBatchSize) return;

    _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite(mode: FileMode.writeOnly));

    final batchBytes = BytesBuilder(copy: false);
    final batchLengths = <int>[];
    final batchIds = <int>[];
    final batchCoastline = <bool>[];
    final batchMerged = <bool>[];

    for (var entry in _collection.entries) {
      int id = entry.key;
      final wayholder = entry.value;

      final bytes = cacheFile.toFile(wayholder);
      batchBytes.add(bytes);
      batchLengths.add(bytes.length);
      batchIds.add(id);
      batchCoastline.add(wayholder.hasTagValue("natural", "coastline"));
      batchMerged.add(wayholder.mergedWithOtherWay);
    }
    _collection.clear();
    //_collection.removeWhere((key, test) => batchIds.contains(key));

    final batchStartPos = _sinkWithCounter!.written;
    _sinkWithCounter!.add(batchBytes.toBytes());
    //_sinkWithCounter!.flush();

    int offset = 0;
    for (int i = 0; i < batchIds.length; i++) {
      final len = batchLengths[i];
      final id = batchIds[i];
      _fileCollection[id] = _WayIdTemp(id: id, pos: batchStartPos + offset, length: len, coastLine: batchCoastline[i], mergedWithOtherWay: batchMerged[i]);
      offset += len;
    }
  }

  Future<Wayholder> _fromFile(int id) async {
    _WayIdTemp temp = _fileCollection[id]!;
    _readbufferFile ??= createReadbufferSource(filename);

    if (readbuffer == null || readbuffer!.offset > temp.pos || readbuffer!.offset + readbuffer!.getBufferSize() < temp.pos + temp.length) {
      readbuffer = await _readbufferFile!.readFromFileAtMax(temp.pos, max(bufferLength, temp.length));
    }
    Uint8List uint8list = readbuffer!.getBuffer(temp.pos - readbuffer!.offset, temp.length);
    assert(uint8list.length == temp.length);

    return cacheFile.fromFile(uint8list);
  }
}

//////////////////////////////////////////////////////////////////////////////

/// Reference to a way in the tempfile
class _WayIdTemp {
  final int id;

  final int pos;

  final int length;

  bool coastLine;

  bool mergedWithOtherWay;

  //BoundingBox? wayBoundingBox;

  _WayIdTemp({required this.id, required this.pos, required this.length, required this.coastLine, required this.mergedWithOtherWay});
}
