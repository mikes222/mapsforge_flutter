import 'dart:io';
import 'dart:typed_data';

import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class PoiholderFileCollection implements IPoiholderCollection {
  final List<Object> _entries = [];

  final List<int> _pendingSpillIndexes = [];

  final int spillBatchSize;

  final String filename;

  SinkWithCounter? _sinkWithCounter;

  ReadbufferSource? _readbufferFile;

  final _PoiCacheFile _cacheFile = _PoiCacheFile();

  PoiholderFileCollection({required this.filename, this.spillBatchSize = 100000});

  @override
  int get length => _entries.length;

  bool get isEmpty => _entries.isEmpty;

  Stream<Poiholder> get iterator async* {
    for (int i = 0; i < _entries.length; i++) {
      yield await get(i);
    }
  }

  @override
  Future<List<Poiholder>> getAll() async {
    final result = <Poiholder>[];
    for (int i = 0; i < _entries.length; i++) {
      result.add(await get(i));
    }
    return result;
  }

  Future<void> mergeFrom(PoiholderFileCollection other) async {
    if (identical(this, other)) return;
    if (other._entries.isEmpty) return;

    if (other._sinkWithCounter != null) {
      await other._sinkWithCounter!.flush();
    }
    int expected = _entries.length + other._entries.length;

    ReadbufferSource? otherReadbufferFile = other._readbufferFile;

    for (final entry in other._entries) {
      if (entry is Poiholder) {
        add(entry);
        continue;
      }

      final temp = entry as _Temp;

      otherReadbufferFile ??= createReadbufferSource(other.filename);

      _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite(mode: FileMode.append));
      final destPos = _sinkWithCounter!.written;

      final readbuffer = await otherReadbufferFile.readFromFileAt(temp.pos, temp.length);
      final bytes = readbuffer.getBuffer(0, temp.length);
      assert(bytes.length == temp.length);

      _sinkWithCounter!.add(bytes);
      _entries.add(_Temp(pos: destPos, length: temp.length));
    }

    other._readbufferFile = otherReadbufferFile;
    assert(_entries.length == expected);
  }

  @override
  Future<void> removeWhere(bool Function(Poiholder poiholder) test) async {
    if (_entries.isEmpty) return;

    final List<Object> retained = [];
    for (int i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      final Poiholder poiholder;
      if (entry is Poiholder) {
        poiholder = entry;
      } else {
        poiholder = await _fromFile(entry as _Temp);
      }

      if (!test(poiholder)) {
        retained.add(entry);
      }
    }

    _entries
      ..clear()
      ..addAll(retained);

    _pendingSpillIndexes.clear();
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i] is Poiholder) {
        _pendingSpillIndexes.add(i);
      }
    }
    _flushPendingToDiskIfNeeded();
  }

  Future<void> _closeFiles() async {
    await _readbufferFile?.freeRessources();
    _readbufferFile = null;

    await _sinkWithCounter?.close();
    _sinkWithCounter = null;
    _pendingSpillIndexes.clear();

    try {
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
  }

  /// Adds a [poiholder] to the end of the collection.
  ///
  /// Returns the index at which it was inserted.
  @override
  int add(Poiholder poiholder) {
    _entries.add(poiholder);
    _pendingSpillIndexes.add(_entries.length - 1);
    _flushPendingToDiskIfNeeded();
    return _entries.length - 1;
  }

  /// Adds all [poiholders] to the collection.
  ///
  /// When the in-memory limit is reached, POIs are written to disk in batches
  /// to reduce I/O overhead.
  ///
  /// Order is not guaranteed.
  @override
  void addAll(Iterable<Poiholder> poiholders) {
    for (final poiholder in poiholders) {
      add(poiholder);
    }
  }

  void _flushPendingToDiskIfNeeded() {
    if (_pendingSpillIndexes.length < spillBatchSize) return;
    _flushPendingToDisk();
  }

  void _flushPendingToDisk() {
    if (_pendingSpillIndexes.isEmpty) return;

    _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite(mode: FileMode.append));

    final batchBytes = BytesBuilder(copy: false);
    final batchLengths = <int>[];
    final batchIndexes = <int>[];

    for (int i = 0; i < spillBatchSize && _pendingSpillIndexes.isNotEmpty; i++) {
      final idx = _pendingSpillIndexes.removeAt(0);
      final entry = _entries[idx];
      if (entry is! Poiholder) {
        continue;
      }
      final bytes = _cacheFile.toFile(entry);
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

  Future<Poiholder> get(int index) async {
    Object entry = _entries[index];
    if (entry is Poiholder) return entry;

    _Temp temp = entry as _Temp;
    return _fromFile(temp);
  }

  Future<void> _loadIntoMemory() async {
    for (int index = 0; index < _entries.length; index++) {
      final entry = _entries[index];
      if (entry is Poiholder) continue;
      Poiholder poiholder = await _fromFile(entry as _Temp);
      _entries[index] = poiholder;
    }
    await _closeFiles();
  }

  @override
  Future<void> forEach(void Function(Poiholder poiholder) action) async {
    for (int i = 0; i < _entries.length; i++) {
      action(await get(i));
    }
  }

  Future<Poiholder> _fromFile(_Temp temp) async {
    _readbufferFile ??= createReadbufferSource(filename);
    if (_sinkWithCounter != null) {
      await _sinkWithCounter!.flush();
    }

    Readbuffer readbuffer = await _readbufferFile!.readFromFileAt(temp.pos, temp.length);
    Uint8List uint8list = readbuffer.getBuffer(0, temp.length);
    assert(uint8list.length == temp.length);

    return _cacheFile.fromFile(uint8list);
  }

  @override
  Future<void> countTags(TagholderModel model) async {
    for (int index = 0; index < _entries.length; index++) {
      Poiholder poiholder = await get(index);
      poiholder.tagholderCollection.reconnectPoiTags(model);
      poiholder.tagholderCollection.countTags();
    }
  }

  @override
  void writePoidata(Writebuffer writebuffer, bool debugFile, double tileLatitude, double tileLongitude, List<String> languagesPreferences) {
    throw UnimplementedError();
  }
}

//////////////////////////////////////////////////////////////////////////////

class _Temp {
  final int pos;
  final int length;

  _Temp({required this.pos, required this.length});
}

//////////////////////////////////////////////////////////////////////////////

class _PoiCacheFile {
  Uint8List toFile(Poiholder poiholder) {
    Writebuffer wb = Writebuffer();

    wb.appendSignedInt(LatLongUtils.degreesToMicrodegrees(poiholder.position.latitude));
    wb.appendSignedInt(LatLongUtils.degreesToMicrodegrees(poiholder.position.longitude));

    // tags
    final tags = poiholder.tagholderCollection.tagholders;
    wb.appendUnsignedInt(tags.length);
    for (final tag in tags) {
      wb.appendString(tag.key);
      wb.appendString(tag.value);
    }

    return wb.getUint8List();
  }

  Poiholder fromFile(Uint8List file) {
    Readbuffer rb = Readbuffer(file, 0);

    double lat = LatLongUtils.microdegreesToDegrees(rb.readSignedInt());
    double lon = LatLongUtils.microdegreesToDegrees(rb.readSignedInt());

    int tagCount = rb.readUnsignedInt();
    Map<String, String> tags = {};
    for (int i = 0; i < tagCount; i++) {
      final key = _readStringAllowEmpty(rb);
      final value = _readStringAllowEmpty(rb);
      tags[key] = value;
    }

    TagholderCollection tagholderCollection = TagholderCollection.fromPoi(tags);
    return Poiholder(position: LatLong(lat, lon), tagholderCollection: tagholderCollection);
  }

  String _readStringAllowEmpty(Readbuffer rb) {
    final len = rb.readUnsignedInt();
    if (len == 0) return '';
    return rb.readUTF8EncodedString2(len);
  }
}
