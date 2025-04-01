import 'dart:io';
import 'dart:math' as Math;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/readbufferfile.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/mapfile_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/poiholder.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/tile_constructor.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';
import 'package:mapsforge_flutter/src/utils/timing.dart';

import '../../../core.dart';
import '../../../datastore.dart';
import '../../../maps.dart';
import '../readbuffer.dart';

/// Each subfile consists of:
/// tile index header
//     for each base-tile: tile index entry
//
//     for each base-tile
//         tile header
//         for each POI: POI data
//         for each way: way properties
//             for each wayblock: way data

typedef Future<void> ProcessFunc(Tile tile);

class SubfileCreator {
  final _log = new Logger('SubfileCreator');

  /// Base zoom level of the sub-file, which equals to one block.
  final int baseZoomLevel;

  final ZoomlevelRange zoomlevelRange;

  final BoundingBox boundingBox;

  final MapHeaderInfo mapHeaderInfo;

  Map<int, Poiinfo> _poiinfos = {};

  Map<int, Wayinfo> _wayinfos = {};

  late final int _minX;

  late final int _minY;

  late final int _maxX;

  late final int _maxY;

  Writebuffer? _writebufferTileIndex;

  late final TileBuffer tileBuffer;

  SubfileCreator({required this.baseZoomLevel, required this.zoomlevelRange, required this.boundingBox, required this.mapHeaderInfo}) {
    MercatorProjection projection = MercatorProjection.fromZoomlevel(baseZoomLevel);
    _minX = projection.longitudeToTileX(boundingBox.minLongitude);
    _maxX = projection.longitudeToTileX(boundingBox.maxLongitude);
    _minY = projection.latitudeToTileY(boundingBox.maxLatitude);
    _maxY = projection.latitudeToTileY(boundingBox.minLatitude);
    tileBuffer = TileBuffer(baseZoomLevel);

    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      _poiinfos[zoomlevel] = Poiinfo();
      _wayinfos[zoomlevel] = Wayinfo();
    }
  }

  void dispose() {
    tileBuffer.dispose();
  }

  void addPoidata(ZoomlevelRange zoomlevelRange, List<PointOfInterest> pois) {
    if (this.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
    if (this.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
    Poiinfo poiinfo = _poiinfos[Math.max(this.zoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!;
    for (PointOfInterest pointOfInterest in pois) {
      poiinfo.setPoidata(pointOfInterest);
    }
  }

  void addWaydata(ZoomlevelRange zoomlevelRange, List<Wayholder> wayholders) {
    if (this.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
    if (this.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
    Wayinfo wayinfo = _wayinfos[Math.max(this.zoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!;
    for (Wayholder wayholder in wayholders) {
      wayinfo.setWaydata(wayholder.way);
    }
  }

  void analyze(List<Tagholder> poiTagholders, List<Tagholder> wayTagholders, String? languagesPreference) {
    _poiinfos.forEach((zoomlevel, poiinfo) {
      poiinfo.analyze(poiTagholders, languagesPreference);
    });
    _wayinfos.forEach((zoomlevel, wayinfo) {
      wayinfo.analyze(wayTagholders, languagesPreference);
    });
  }

  Future<void> _processAsync(String title, ProcessFunc process, [Future<void> Function(int processedTiles, int sumTiles)? lineProcess = null]) async {
    int started = DateTime.now().millisecondsSinceEpoch;
    int sumTiles = (_maxY - _minY + 1) * (_maxX - _minX + 1);
    for (int tileY = _minY; tileY <= _maxY; ++tileY) {
      for (int tileX = _minX; tileX <= _maxX; ++tileX) {
        Tile tile = Tile(tileX, tileY, baseZoomLevel, 0);
        await process(tile);
      }
      int processedTiles = (tileY - _minY + 1) * (_maxX - _minX + 1);
      if (lineProcess != null) {
        await lineProcess(processedTiles, sumTiles);
      }
      int diff = DateTime.now().millisecondsSinceEpoch - started;
      if (diff > 1000 * 120) {
        // more than one minute
        _log.info("Processed ${(processedTiles / sumTiles * 100).round()}% of tiles for $title at baseZoomLevel $baseZoomLevel");
        started = DateTime.now().millisecondsSinceEpoch;
      }
    }
  }

  void _processSync(String title, Function(Tile tile) process, [Function(int processedTiles, int sumTiles)? lineProcess = null]) {
    int started = DateTime.now().millisecondsSinceEpoch;
    int sumTiles = (_maxY - _minY + 1) * (_maxX - _minX + 1);
    for (int tileY = _minY; tileY <= _maxY; ++tileY) {
      for (int tileX = _minX; tileX <= _maxX; ++tileX) {
        Tile tile = Tile(tileX, tileY, baseZoomLevel, 0);
        process(tile);
      }
      int processedTiles = (tileY - _minY + 1) * (_maxX - _minX + 1);
      if (lineProcess != null) {
        lineProcess(processedTiles, sumTiles);
      }
      int diff = DateTime.now().millisecondsSinceEpoch - started;
      if (diff > 1000 * 120) {
        // more than one minute
        _log.info("Processed ${(processedTiles / sumTiles * 100).round()}% of tiles for %title at baseZoomLevel $baseZoomLevel.");
        started = DateTime.now().millisecondsSinceEpoch;
      }
    }
  }

  void _writeIndexHeaderSignature(bool debugFile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("+++IndexStart+++");
    }
  }

  Future<void> prepareTiles(bool debugFile, double maxDeviationPixel) async {
    Timing timing = Timing(log: _log);
    IsolateTileConstructor tileConstructor = IsolateTileConstructor(debugFile, _poiinfos, _wayinfos, zoomlevelRange, maxDeviationPixel, (_maxX - _minX + 1));
    List<Future> futures = [];
    await _processAsync("preparing tiles", (tile) async {
      Future future = _future(tileConstructor, tile);
      futures.add(future);
      // if (futures.length >= 200) {
      //   await Future.wait(futures);
      //   futures.clear();
      // }
    }, (int processedTiles, int sumTiles) async {
      await Future.wait(futures);
      futures.clear();
      if (sumTiles > 2000) {
        tileBuffer.cacheToDisk(processedTiles, sumTiles);
      }
    });
    await tileBuffer.writeComplete();
    tileConstructor.dispose();
    timing.lap(1000, "prepare tiles for baseZoomLevel $baseZoomLevel completed");
  }

  Future<void> _future(IsolateTileConstructor tileConstructor, Tile tile) async {
    Uint8List writebufferTile = await tileConstructor.writeTile(tile);
    tileBuffer.set(tile, writebufferTile);
  }

  Writebuffer writeTileIndex(bool debugFile) {
    if (_writebufferTileIndex != null) return _writebufferTileIndex!;
    _writebufferTileIndex = Writebuffer();
    _writeIndexHeaderSignature(debugFile, _writebufferTileIndex!);
    // todo find out how to do this
    bool coveredByWater = false;
    int offset = _writebufferTileIndex!.length + 5 * (_maxX - _minX + 1) * (_maxY - _minY + 1);
    int firstOffset = offset;
    _processSync("writing tile index", (tile) {
      _writeTileIndexEntry(_writebufferTileIndex!, coveredByWater, offset);
      offset += tileBuffer.getLength(tile);
      return Future.value(null);
    });
    assert(firstOffset == _writebufferTileIndex!.length,
        "$firstOffset != ${_writebufferTileIndex!.length} with debug=$debugFile and baseZoomLevel=$baseZoomLevel");
    _poiinfos.clear();
    _wayinfos.clear();
    return _writebufferTileIndex!;
  }

  /// Note: to calculate how many tile index entries there will be, use the formulae at [http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames] to find out how many tiles will be covered by the bounding box at the base zoom level of the sub file
  void _writeTileIndexEntry(Writebuffer writebuffer, bool coveredByWater, int offset) {
    int indexEntry = 0;
    if (coveredByWater) indexEntry = indexEntry |= MapFile.BITMASK_INDEX_WATER;

    // 2.-40. bit (mask: 0x7f ff ff ff ff): 39 bit offset of the tile in the sub file as 5-bytes LONG (optional debug information and index size is also counted; byte order is BigEndian i.e. most significant byte first)
    // If the tile is empty offset(tile,,i,,) = offset(tile,,i+1,,)
    indexEntry = indexEntry |= offset;
    writebuffer.appendInt5(indexEntry);
  }

  Future<int> getTilesLength(bool debugFile) async {
    int result = 0;
    _processSync("getting tiles length", (tile) {
      result += tileBuffer.getLength(tile);
    });
    return result;
  }

  Future<void> writeTiles(bool debugFile, MapfileSink ioSink) async {
    await _processAsync("writing tiles", (tile) async {
      Uint8List contentForTile = await tileBuffer.getAndRemove(tile);
      ioSink.add(contentForTile);
    });
  }

  void statistics() {
    int tileCount = (_maxX - _minX + 1) * (_maxY - _minY + 1);
    int poiCount = _poiinfos.values.fold(0, (int combine, Poiinfo poiinfo) => combine + poiinfo.count);
    int wayCount = _wayinfos.values.fold(0, (combine, wayinfo) => combine + wayinfo.count);
    _log.info("$zoomlevelRange, baseZoomLevel: $baseZoomLevel, tiles: $tileCount, poi: $poiCount, way: $wayCount");
  }
}

//////////////////////////////////////////////////////////////////////////////

/// All pois for one zoomlevel.
class Poiinfo {
  List<Poiholder> poiholders = [];

  Uint8List? content;

  int count = 0;

  Poiinfo();

  void addPoiholder(Poiholder poiholder) {
    assert(content == null);
    poiholders.add(poiholder);
    ++count;
  }

  void setPoidata(PointOfInterest poi) {
    assert(content == null);
    Poiholder poiholder = Poiholder(poi);
    poiholders.add(poiholder);
    ++count;
  }

  bool contains(PointOfInterest poi) {
    assert(content == null);
    return poiholders.firstWhereOrNull((test) => test.poi == poi) != null;
  }

  void analyze(List<Tagholder> tagholders, String? languagesPreference) {
    assert(content == null);
    for (Poiholder poiholder in poiholders) {
      poiholder.analyze(tagholders, languagesPreference);
    }
  }

  Uint8List writePoidata(bool debugFile, double tileLatitude, double tileLongitude) {
    if (content != null) return content!;
    Writebuffer writebuffer = Writebuffer();
    for (Poiholder poiholder in poiholders) {
      writebuffer.appendWritebuffer(poiholder.writePoidata(debugFile, tileLatitude, tileLongitude));
    }
    poiholders.clear();
    content = writebuffer.getUint8List();
    return content!;
  }
}

//////////////////////////////////////////////////////////////////////////////

/// All ways for one zoomlevel.
class Wayinfo {
  List<Wayholder> wayholders = [];

  Uint8List? content;

  int count = 0;

  Wayinfo();

  addWayholder(Wayholder wayholder) {
    assert(content == null);
    wayholders.add(wayholder);
    ++count;
  }

  void setWaydata(Way way) {
    assert(content == null);
    Wayholder wayholder = Wayholder(way);
    wayholders.add(wayholder);
    ++count;
  }

  Wayholder? searchWayholder(Way way) {
    assert(content == null);
    return wayholders.firstWhereOrNull((test) => test.way == way);
  }

  void analyze(List<Tagholder> tagholders, String? languagesPreference) {
    assert(content == null);
    for (Wayholder wayholder in wayholders) {
      wayholder.analyze(tagholders, languagesPreference);
    }
  }

  Uint8List writeWaydata(bool debugFile, Tile tile, double tileLatitude, double tileLongitude) {
    if (content != null) return content!;
    Writebuffer writebuffer = Writebuffer();
    for (Wayholder wayholder in wayholders) {
      writebuffer.appendWritebuffer(wayholder.writeWaydata(debugFile, tile, tileLatitude, tileLongitude));
    }
    wayholders.clear();
    content = writebuffer.getUint8List();
    return content!;
  }
}

//////////////////////////////////////////////////////////////////////////////

class TileBuffer {
  Map<Tile, Uint8List> _writebufferForTiles = {};

  Map<Tile, _TempfileIndex> _indexes = {};

  Map<Tile, int> _sizes = {};

  MapfileSink? _ioSink;

  ReadbufferFile? _readbufferFile;

  late final String _filename;

  TileBuffer(int baseZoomlevel) {
    _filename = "temp_${DateTime.now().millisecondsSinceEpoch}_${baseZoomlevel}.tmp";
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
  }

  void set(Tile tile, Uint8List content) {
    _writebufferForTiles[tile] = content;
    _sizes[tile] = content.length;
  }

  /// Returns the content of the tile. Assumes that the order of retrieval is exactly
  /// the same as the order of storage.
  Future<Uint8List> get(Tile tile) async {
    if (_writebufferForTiles.containsKey(tile)) return _writebufferForTiles[tile]!;

    await writeComplete();
    if (_readbufferFile != null) {
      _TempfileIndex tempfileIndex = _indexes[tile]!;
      Readbuffer readbuffer = await _readbufferFile!.readFromFileAt(tempfileIndex.position, tempfileIndex.length);
      return readbuffer.getBuffer(0, tempfileIndex.length);
    }
    return _writebufferForTiles[tile]!;
  }

  Future<Uint8List> getAndRemove(Tile tile) async {
    if (_writebufferForTiles.containsKey(tile)) {
      _sizes.remove(tile);
      return _writebufferForTiles.remove(tile)!;
    }
    if (_ioSink != null || _readbufferFile != null) {
      Uint8List result = await get(tile);
      _sizes.remove(tile);
      _indexes.remove(tile);
      if (_indexes.isEmpty) dispose();
      return result;
    }
    _sizes.remove(tile);
    return _writebufferForTiles.remove(tile)!;
  }

  int getLength(Tile tile) {
    return _sizes[tile]!;
  }

  void cacheToDisk(int processedTiles, int sumTiles) {
    if (_writebufferForTiles.isEmpty) return;
    _ioSink ??= MapfileSink(File(_filename).openWrite());
    _writebufferForTiles.forEach((tile, content) {
      _TempfileIndex tempfileIndex = _TempfileIndex(_ioSink!.written, content.length);
      _indexes[tile] = tempfileIndex;
      _ioSink!.add(content);
    });
    _writebufferForTiles.clear();
  }

  Future<void> writeComplete() async {
    if (_ioSink != null) {
      // close the writing and start reading
      await _ioSink?.close();
      _ioSink = null;
      _readbufferFile = ReadbufferFile(_filename);
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class _TempfileIndex {
  final int position;

  final int length;

  _TempfileIndex(this.position, this.length);
}
