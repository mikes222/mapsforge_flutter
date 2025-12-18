import 'dart:io';
import 'dart:math' as Math;
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/filter/way_cropper.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder_collection.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/tile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/wayholder_collection.dart';

/// Each subfile consists of:
/// tile index header
//     for each base-tile: tile index entry
//
//     for each base-tile
//         tile header
//         for each POI: POI data
//         for each way: way properties
//             for each wayblock: way data

typedef ProcessFunc = Future<void> Function(Tile tile);

/// A class responsible for creating a single sub-file within a Mapsforge map file.
///
/// This involves collecting all POIs and ways for a given zoom level range,
/// processing them into tiles, and writing the tile index and tile data.
class SubfileCreator {
  final _log = Logger('SubfileCreator');

  /// Base zoom level of the sub-file, which equals to one block.
  final int baseZoomLevel;

  final ZoomlevelRange zoomlevelRange;

  final MapHeaderInfo mapHeaderInfo;

  final Map<int, PoiholderCollection> _poiholderCollection = {};

  final Map<int, WayholderCollection> _wayholderCollection = {};

  late final int _minX;

  late final int _minY;

  late final int _maxX;

  late final int _maxY;

  Writebuffer? _writebufferTileIndex;

  late final TileBuffer tileBuffer;

  SubfileCreator({required this.baseZoomLevel, required this.zoomlevelRange, required this.mapHeaderInfo}) {
    MercatorProjection projection = MercatorProjection.fromZoomlevel(baseZoomLevel);
    _minX = projection.longitudeToTileX(mapHeaderInfo.boundingBox.minLongitude);
    _maxX = projection.longitudeToTileX(mapHeaderInfo.boundingBox.maxLongitude);
    _minY = projection.latitudeToTileY(mapHeaderInfo.boundingBox.maxLatitude);
    _maxY = projection.latitudeToTileY(mapHeaderInfo.boundingBox.minLatitude);

    assert(_minX >= 0, "minX $_minX < 0 for ${mapHeaderInfo.boundingBox} and $baseZoomLevel");
    assert(_minY >= 0, "minY $_minY < 0 for ${mapHeaderInfo.boundingBox} and $baseZoomLevel");
    tileBuffer = TileBuffer(baseZoomLevel);

    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      _poiholderCollection[zoomlevel] = PoiholderCollection();
      _wayholderCollection[zoomlevel] = WayholderCollection();
    }
  }

  void dispose() {
    tileBuffer.dispose();
    _poiholderCollection.clear();
    _wayholderCollection.clear();
    _writebufferTileIndex = null;
  }

  Iterable<PoiholderCollection> get poiholderCollection => _poiholderCollection.values;

  Iterable<WayholderCollection> get wayholderCollection => _wayholderCollection.values;

  /// Adds a list of POIs to the appropriate zoom level within this sub-file.
  void addPoidata(ZoomlevelRange zoomlevelRange, List<PointOfInterest> pois) {
    if (this.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
    if (this.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
    PoiholderCollection poiinfo = _poiholderCollection[Math.max(this.zoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!;
    for (PointOfInterest pointOfInterest in pois) {
      poiinfo.setPoidata(pointOfInterest);
    }
  }

  /// Adds a list of ways to the appropriate zoom level within this sub-file.
  void addWaydata(ZoomlevelRange zoomlevelRange, List<Wayholder> wayholders) {
    if (this.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
    if (this.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
    WayholderCollection wayinfo = _wayholderCollection[Math.max(this.zoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!;
    //print("Adding ${wayholders.length} ways to zoomlevelRange $zoomlevelRange for baseZoomLevel $baseZoomLevel");
    WayCropper wayCropper = WayCropper(maxDeviationPixel: 5);
    if (tileCount >= 100) {
      // one tile may span over the boundary of the mapfile, so do not crop
      for (Wayholder wayholder in wayholders) {
        Wayholder? wayCropped = wayCropper.cropOutsideWay(wayholder, mapHeaderInfo.boundingBox);
        if (wayCropped != null) wayinfo.addWayholder(wayCropped);
      }
    } else {
      wayinfo.addWayholders(wayholders);
    }
  }

  Future<void> _processAsync(String title, ProcessFunc process, [Future<void> Function(int processedTiles, int sumTiles)? lineProcess]) async {
    int started = DateTime.now().millisecondsSinceEpoch;
    int lastProcessedTiles = 0;
    for (int tileY = _minY; tileY <= _maxY; ++tileY) {
      for (int tileX = _minX; tileX <= _maxX; ++tileX) {
        Tile tile = Tile(tileX, tileY, baseZoomLevel, 0);
        await process(tile);
      }
      int processedTiles = (tileY - _minY + 1) * (_maxX - _minX + 1);
      if (lineProcess != null) {
        await lineProcess(processedTiles, tileCount);
      }
      int diff = DateTime.now().millisecondsSinceEpoch - started;
      if (diff >= 1000 * 120) {
        // more than two minutes
        _log.info(
          "Processed ${(processedTiles / tileCount * 100).round()}% of tiles for $title at baseZoomLevel $baseZoomLevel (${((processedTiles - lastProcessedTiles) / diff * 1000).toStringAsFixed(1)} tiles/sec)",
        );
        started = DateTime.now().millisecondsSinceEpoch;
        lastProcessedTiles = processedTiles;
      }
    }
  }

  void _processSync(String title, Function(Tile tile) process, [Function(int processedTiles, int sumTiles)? lineProcess]) {
    int started = DateTime.now().millisecondsSinceEpoch;
    int lastProcessedTiles = 0;
    for (int tileY = _minY; tileY <= _maxY; ++tileY) {
      for (int tileX = _minX; tileX <= _maxX; ++tileX) {
        Tile tile = Tile(tileX, tileY, baseZoomLevel, 0);
        process(tile);
      }
      int processedTiles = (tileY - _minY + 1) * (_maxX - _minX + 1);
      if (lineProcess != null) {
        lineProcess(processedTiles, tileCount);
      }
      int diff = DateTime.now().millisecondsSinceEpoch - started;
      if (diff >= 1000 * 120) {
        // more than two minutes
        _log.info(
          "Processed ${(processedTiles / tileCount * 100).round()}% of tiles for %title at baseZoomLevel $baseZoomLevel (${((processedTiles - lastProcessedTiles) / diff * 1000).toStringAsFixed(1)} tiles/sec).",
        );
        started = DateTime.now().millisecondsSinceEpoch;
        lastProcessedTiles = processedTiles;
      }
    }
  }

  void _writeIndexHeaderSignature(bool debugFile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("+++IndexStart+++");
    }
  }

  /// Prepares all tiles for this sub-file by processing the POIs and ways in
  /// parallel isolates.
  Future<void> prepareTiles(bool debugFile, double maxDeviationPixel, int instanceCount) async {
    var session = PerformanceProfiler().startSession(category: "SubfileCreator.prepareTiles");
    List<IsolateTileWriter> tileWriters = [];
    // each instance must process this number of consecutive tiles
    final int iterationCount = 20;
    for (int i = 0; i < instanceCount; ++i) {
      tileWriters.add(
        await IsolateTileWriter.create(
          debugFile,
          _poiholderCollection,
          _wayholderCollection,
          zoomlevelRange,
          maxDeviationPixel,
          Math.min(_maxX - _minX + 1, iterationCount),
        ),
      );
    }
    // the isolates now hove the infos, we can remove them from memory here
    _poiholderCollection.clear();
    _wayholderCollection.clear();
    List<Future> futures = [];
    int current = 0;
    int counter = 0;
    await _processAsync(
      "preparing tiles",
      (tile) async {
        Future future = _future(tileWriters[current], tile);
        futures.add(future);
        ++counter;
        if (counter >= iterationCount) {
          counter = 0;
          ++current;
          current = current % instanceCount;
        }
      },
      (int processedTiles, int sumTiles) async {
        if (futures.length > iterationCount * instanceCount * 5 || processedTiles == sumTiles) {
          await Future.wait(futures);
          futures.clear();
          tileBuffer.cacheToDisk(processedTiles, sumTiles);
        }
      },
    );
    await tileBuffer.writeComplete();
    for (int i = 0; i < instanceCount; ++i) {
      tileWriters[i].dispose();
    }
    tileWriters.clear();
    session.complete();
  }

  Future<void> _future(IsolateTileWriter tileWriter, Tile tile) async {
    Uint8List writebufferTile = await tileWriter.writeTile(tile);
    tileBuffer.set(tile, writebufferTile);
  }

  /// Writes the tile index for this sub-file to a [Writebuffer].
  Writebuffer writeTileIndex(bool debugFile) {
    if (_writebufferTileIndex != null) return _writebufferTileIndex!;
    _writebufferTileIndex = Writebuffer();
    _writeIndexHeaderSignature(debugFile, _writebufferTileIndex!);
    // todo find out how to do this
    bool coveredByWater = false;
    int offset = _writebufferTileIndex!.length + 5 * tileCount;
    int firstOffset = offset;
    _processSync("writing tile index", (tile) {
      _writeTileIndexEntry(_writebufferTileIndex!, coveredByWater, offset);
      offset += tileBuffer.getLength(tile);
      return Future.value(null);
    });
    assert(
      firstOffset == _writebufferTileIndex!.length,
      "$firstOffset != ${_writebufferTileIndex!.length} with debug=$debugFile and baseZoomLevel=$baseZoomLevel",
    );
    return _writebufferTileIndex!;
  }

  /// Note: to calculate how many tile index entries there will be, use the formulae at [http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames] to find out how many tiles will be covered by the bounding box at the base zoom level of the sub file
  void _writeTileIndexEntry(Writebuffer writebuffer, bool coveredByWater, int offset) {
    int indexEntry = 0;
    if (coveredByWater) indexEntry = indexEntry |= Mapfile.BITMASK_INDEX_WATER;

    // 2.-40. bit (mask: 0x7f ff ff ff ff): 39 bit offset of the tile in the sub file as 5-bytes LONG (optional debug information and index size is also counted; byte order is BigEndian i.e. most significant byte first)
    // If the tile is empty offset(tile,,i,,) = offset(tile,,i+1,,)
    indexEntry = indexEntry |= offset;
    writebuffer.appendInt5(indexEntry);
  }

  /// Calculates the total length of all tile data in this sub-file.
  Future<int> getTilesLength(bool debugFile) async {
    int result = 0;
    _processSync("getting tiles length", (tile) {
      result += tileBuffer.getLength(tile);
    });
    return result;
  }

  /// Writes all tile data for this sub-file to the given [ioSink].
  Future<void> writeTiles(bool debugFile, SinkWithCounter ioSink) async {
    await _processAsync("writing tiles", (tile) async {
      Uint8List contentForTile = await tileBuffer.getAndRemove(tile);
      ioSink.add(contentForTile);
    });
  }

  int get tileCount => (_maxX - _minX + 1) * (_maxY - _minY + 1);

  /// Logs statistics about the contents of this sub-file.
  void statistics() {
    int poiCount = _poiholderCollection.values.fold(0, (int combine, PoiholderCollection poiinfo) => combine + poiinfo.count);
    int wayCount = _wayholderCollection.values.fold(0, (combine, wayinfo) => combine + wayinfo.wayCount);
    int pathCount = _wayholderCollection.values.fold(
      0,
      (combine, wayinfo) => combine + wayinfo.wayholders.fold(0, (combine, wayholder) => combine + wayholder.pathCount()),
    );
    int nodeCount = _wayholderCollection.values.fold(0, (combine, wayinfo) => combine + wayinfo.nodeCount);
    _log.info(
      "$zoomlevelRange, baseZoomLevel: $baseZoomLevel, tiles: $tileCount, poi: $poiCount, way: $wayCount with ${wayCount != 0 ? (pathCount / wayCount).toStringAsFixed(1) : "n/a"} paths and ${pathCount != 0 ? (nodeCount / pathCount).toStringAsFixed(1) : "n/a"} nodes per path",
    );
  }
}

//////////////////////////////////////////////////////////////////////////////

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
