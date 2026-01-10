import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:mapfile_converter/modifiers/cachefile.dart';
import 'package:mapfile_converter/modifiers/wayholder_id_file_collection.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';

class WayholderFileCollection implements IWayholderCollection {
  final _log = Logger('WayholderFileCollection');

  final int spillBatchSize;

  final Queue<Wayholder> _entries = Queue();

  final Queue<_WayTemp> _fileEntries = Queue();

  /// A cache for the file entries in sorted order by fileposition.
  List<_WayTemp>? _fileSorted;

  final CacheFile cacheFile = CacheFile();

  String filename;

  SinkWithCounter? _sinkWithCounter;

  ReadbufferSource? _readbufferFile;

  Readbuffer? readbuffer;

  final int bufferLength = 1000000;

  WayholderFileCollection({required this.filename, this.spillBatchSize = 100000});

  Future<void> mergeFrom(WayholderIdFileCollection other) async {
    int expected = length + other.length;

    addAll(await other.getAllOnline());

    // do not add the file if we do not have entries
    if (length == expected) return;
    _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite(mode: FileMode.writeOnly));
    await other.forEachOffline((uint8list) {
      final batchStartPos = _sinkWithCounter!.written;
      _sinkWithCounter!.add(uint8list);
      _fileEntries.add(_WayTemp(pos: batchStartPos, length: uint8list.length));
    });
    _fileSorted = null;
    assert(length == expected, "expected ${length} == $expected");
  }

  @override
  int get length => _entries.length + _fileEntries.length;

  @override
  bool get isEmpty => _entries.isEmpty && _fileEntries.isEmpty;

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

  Future<void> _closeFiles() async {
    await freeRessources();
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
    _fileEntries.clear();
    _fileSorted = null;
  }

  @override
  void add(Wayholder wayholder) {
    _entries.add(wayholder);
    _flushPendingToDiskIfNeeded();
  }

  @override
  void addAll(Iterable<Wayholder> wayholders) {
    for (final wayholder in wayholders) {
      _entries.add(wayholder);
    }
    int count = _entries.length;
    while (true) {
      _flushPendingToDiskIfNeeded();
      if (_entries.length >= count) break;
      count = _entries.length;
    }
  }

  @override
  Future<void> forEach(void Function(Wayholder wayholder) action) async {
    // Pass 1: process in-memory entries first (cheap, no I/O).
    for (var entry in _entries) {
      action(entry);
    }
    // Pass 2: process spilled entries from disk in large sequential batches.
    await _sinkWithCounter?.flush();
    if (_fileSorted == null) {
      _fileSorted = _fileEntries.toList();
      _fileSorted!.sort((a, b) => a.pos.compareTo(b.pos));
    }
    for (var temp in _fileSorted!) {
      action(await _fromFile(temp));
    }
  }

  @override
  Future<void> removeWhere(bool Function(Wayholder wayholder) test) async {
    if (_entries.isEmpty) return;

    // Pass 1: process in-memory entries (cheap, no I/O).
    // removeWhere of Queue() needs 338 seconds for 1 mio entries
    {
      //_entries.removeWhere(test);
      Queue<Wayholder> newEntries = Queue();
      for (var wayholder in _entries) {
        bool toRemove = test(wayholder);
        if (!toRemove) {
          newEntries.add(wayholder);
        }
      }
      _entries.clear();
      _entries.addAll(newEntries);
    }

    // Pass 2: process spilled entries from disk.
    {
      await _sinkWithCounter?.flush();
      if (_fileSorted == null) {
        _fileSorted = _fileEntries.toList();
        _fileSorted!.sort((a, b) => a.pos.compareTo(b.pos));
      }
      Queue<_WayTemp> newEntries = Queue();
      for (var temp in _fileSorted!) {
        final entry = await _fromFile(temp);
        bool toRemove = test(entry);
        if (!toRemove) {
          newEntries.add(temp);
        }
      }
      _fileEntries.clear();
      _fileEntries.addAll(newEntries);
      _fileSorted = null;
    }
  }

  void _flushPendingToDiskIfNeeded() {
    if (_entries.length < spillBatchSize * 2) return;

    _sinkWithCounter ??= SinkWithCounter(File(filename).openWrite(mode: FileMode.writeOnly));

    final batchBytes = BytesBuilder(copy: false);
    final batchLengths = <int>[];

    for (int i = 0; i < spillBatchSize; ++i) {
      final entry = _entries.removeFirst();

      final bytes = cacheFile.toFile(entry);
      batchBytes.add(bytes);
      batchLengths.add(bytes.length);
    }

    final batchStartPos = _sinkWithCounter!.written;
    _sinkWithCounter!.add(batchBytes.toBytes());

    int offset = 0;
    for (int i = 0; i < batchLengths.length; ++i) {
      final len = batchLengths[i];
      _fileEntries.add(_WayTemp(pos: batchStartPos + offset, length: len));
      offset += len;
    }
    _fileSorted = null;
  }

  Future<Wayholder> _fromFile(_WayTemp temp) async {
    _readbufferFile ??= createReadbufferSource(filename);

    if (readbuffer == null || readbuffer!.offset > temp.pos || readbuffer!.offset + readbuffer!.getBufferSize() < temp.pos + temp.length) {
      readbuffer = await _readbufferFile!.readFromFileAtMax(temp.pos, max(bufferLength, temp.length));
    }
    Uint8List uint8list = readbuffer!.getBuffer(temp.pos - readbuffer!.offset, temp.length);
    assert(uint8list.length == temp.length);

    return cacheFile.fromFile(uint8list);
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
}

//////////////////////////////////////////////////////////////////////////////

class _WayTemp {
  final int pos;
  final int length;

  _WayTemp({required this.pos, required this.length}) : assert(pos >= 0, "pos $pos"), assert(length > 0, "length $length");
}
