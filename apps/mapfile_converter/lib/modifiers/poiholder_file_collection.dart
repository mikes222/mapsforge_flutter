import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class PoiholderFileCollection implements IPoiholderCollection {
  final Queue<Poiholder> _entries = Queue();

  final Queue<_PoiTemp> _fileEntries = Queue();

  final int spillBatchSize;

  final String filename;

  SinkWithCounter? _sinkWithCounter;

  ReadbufferSource? _readbufferFile;

  Readbuffer? readbuffer;

  final int bufferLength = 1000000;

  final _PoiCacheFile _cacheFile = _PoiCacheFile();

  PoiholderFileCollection({required this.filename, this.spillBatchSize = 100000});

  @override
  int get length => _entries.length + _fileEntries.length;

  bool get isEmpty => _entries.isEmpty && _fileEntries.isEmpty;

  @override
  Future<List<Poiholder>> getAll() async {
    final result = <Poiholder>[];
    result.addAll(_entries);
    await _sinkWithCounter?.flush();
    for (var temp in _fileEntries) {
      result.add(await _fromFile(temp));
    }
    return result;
  }

  @override
  Future<void> mergeFrom(IPoiholderCollection other) async {
    if (other is PoiholderFileCollection) {
      if (identical(this, other)) return;

      int expected = length + other.length;

      //      print("Merging from ${_entries.length}/${other._entries.length} ${_fileEntries.length}/${other._fileEntries.length}");
      for (final entry in other._entries) {
        add(entry);
      }

      // do not add the file if we do not have entries
      if (length == expected) return;

      ReadbufferSource? otherReadbufferFile = other._readbufferFile;

      otherReadbufferFile ??= createReadbufferSource(other.filename);
      _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite(mode: FileMode.writeOnly));
      Readbuffer? readbuffer;
      List<_PoiTemp> temps = other._fileEntries.toList();
      temps.sort((a, b) => a.pos.compareTo(b.pos));
      for (final temp in temps) {
        if (readbuffer == null || readbuffer.offset > temp.pos || readbuffer.offset + readbuffer.getBufferSize() < temp.pos + temp.length) {
          readbuffer = await otherReadbufferFile.readFromFileAtMax(temp.pos, max(bufferLength, temp.length));
          //print("POI readFromFileAtMax ${temp.pos} ${temp.length}");
        }
        Uint8List uint8list = readbuffer.getBuffer(temp.pos - readbuffer.offset, temp.length);
        assert(uint8list.length == temp.length);

        final destPos = _sinkWithCounter!.written;
        _sinkWithCounter!.add(uint8list);
        _fileEntries.add(_PoiTemp(pos: destPos, length: temp.length));
      }

      other._readbufferFile = otherReadbufferFile;
      assert(
        length == expected,
        "expected ${length} == $expected ${_entries.length}/${other._entries.length} ${_fileEntries.length}/${other._fileEntries.length}",
      );
    } else {
      addAll(await other.getAll());
    }
  }

  @override
  Future<void> removeWhere(bool Function(Poiholder poiholder) test) async {
    if (_entries.isEmpty) return;

    // Pass 1: process in-memory entries (cheap, no I/O).
    // removeWhere of Queue() needs 338 seconds for 1 mio entries
    {
      //_entries.removeWhere(test);
      Queue<Poiholder> newEntries = Queue();
      for (var poiholder in _entries) {
        bool toRemove = test(poiholder);
        if (!toRemove) {
          newEntries.add(poiholder);
        }
      }
      _entries.clear();
      _entries.addAll(newEntries);
    }

    // Pass 2: process spilled entries from disk.
    {
      await _sinkWithCounter?.flush();
      Queue<_PoiTemp> newEntries = Queue();
      for (var temp in _fileEntries) {
        final entry = await _fromFile(temp);
        bool toRemove = test(entry);
        if (!toRemove) {
          newEntries.add(temp);
        }
      }
      _fileEntries.clear();
      _fileEntries.addAll(newEntries);
    }
  }

  @override
  Future<void> freeRessources() async {
    await _readbufferFile?.freeRessources();
    _readbufferFile = null;

    await _sinkWithCounter?.close();
    _sinkWithCounter = null;
  }

  Future<void> _closeFiles() async {
    await freeRessources();

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
    _fileEntries.clear();
  }

  /// Adds a [poiholder] to the end of the collection.
  ///
  /// Returns the index at which it was inserted.
  @override
  void add(Poiholder poiholder) {
    _entries.add(poiholder);
    _flushPendingToDiskIfNeeded();
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
    if (_entries.length < spillBatchSize * 2) return;

    _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite(mode: FileMode.writeOnly));

    final batchBytes = BytesBuilder(copy: false);
    final batchLengths = <int>[];

    for (int i = 0; i < spillBatchSize; i++) {
      final entry = _entries.removeFirst();
      final bytes = _cacheFile.toFile(entry);
      batchBytes.add(bytes);
      batchLengths.add(bytes.length);
    }

    final batchStartPos = _sinkWithCounter!.written;
    _sinkWithCounter!.add(batchBytes.toBytes());
    // Ensure all spilled data is actually present on disk.
    //await _sinkWithCounter?.flush();

    int offset = 0;
    for (int i = 0; i < batchLengths.length; i++) {
      final len = batchLengths[i];
      _fileEntries.add(_PoiTemp(pos: batchStartPos + offset, length: len));
      offset += len;
    }
  }

  @override
  Future<void> forEach(void Function(Poiholder poiholder) action) async {
    // Pass 1: process in-memory entries first (cheap, no I/O).
    for (var entry in _entries) {
      action(entry);
    }

    // Pass 2: process spilled entries from disk in large sequential batches.
    await _sinkWithCounter?.flush();
    List<_PoiTemp> temps = _fileEntries.toList();
    temps.sort((a, b) => a.pos.compareTo(b.pos));
    for (var temp in temps) {
      final entry = await _fromFile(temp);
      action(entry);
    }
  }

  Future<Poiholder> _fromFile(_PoiTemp temp) async {
    _readbufferFile ??= createReadbufferSource(filename);

    if (readbuffer == null || readbuffer!.offset > temp.pos || readbuffer!.offset + readbuffer!.getBufferSize() < temp.pos + temp.length) {
      readbuffer = await _readbufferFile!.readFromFileAtMax(temp.pos, max(bufferLength, temp.length));
    }
    Uint8List uint8list = readbuffer!.getBuffer(temp.pos - readbuffer!.offset, temp.length);
    assert(uint8list.length == temp.length);

    return _cacheFile.fromFile(uint8list);
  }
}

//////////////////////////////////////////////////////////////////////////////

class _PoiTemp {
  final int pos;
  final int length;

  _PoiTemp({required this.pos, required this.length}) : assert(pos >= 0, "pos must be >= 0"), assert(length > 0, "length must be > 0");
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
      wb.appendInt4(tag.index ?? -1);
    }
    return wb.getUint8List();
  }

  Poiholder fromFile(Uint8List file) {
    Readbuffer rb = Readbuffer(file, 0);

    int lat = rb.readSignedInt();
    int lon = rb.readSignedInt();

    int tagCount = rb.readUnsignedInt();
    final tagholders = List<Tagholder>.generate(tagCount, (i) {
      final key = _readStringAllowEmpty(rb);
      final value = _readStringAllowEmpty(rb);
      final index = rb.readInt();
      final tagholder = Tagholder(key, value);
      if (index != -1) tagholder.index = index;
      return tagholder;
    }, growable: false);

    TagholderCollection tagholderCollection = TagholderCollection.fromCache(tagholders);
    return Poiholder(position: MicroLatLong(lat, lon), tagholderCollection: tagholderCollection);
  }

  String _readStringAllowEmpty(Readbuffer rb) {
    final len = rb.readUnsignedInt();
    if (len == 0) return '';
    return rb.readUTF8EncodedString2(len);
  }
}
