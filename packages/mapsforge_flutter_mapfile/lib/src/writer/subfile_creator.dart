import 'dart:math' as Math;
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/filter/boundary_filter.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder_collection.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/tile_buffer.dart';
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

  final PoiWayCollections _poiWayCollections = PoiWayCollections();

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
      _poiWayCollections.poiholderCollections[zoomlevel] = PoiholderCollection();
      _poiWayCollections.wayholderCollections[zoomlevel] = WayholderCollection();
    }
  }

  void dispose() {
    tileBuffer.dispose();
    _poiWayCollections.clear();
    _writebufferTileIndex = null;
  }

  Iterable<PoiholderCollection> get poiholderCollection => _poiWayCollections.poiholderCollections.values;

  Iterable<WayholderCollection> get wayholderCollection => _poiWayCollections.wayholderCollections.values;

  /// Adds a list of POIs to the appropriate zoom level within this sub-file.
  void addPoidata(ZoomlevelRange zoomlevelRange, List<PointOfInterest> pois) {
    if (this.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
    if (this.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
    PoiholderCollection poiinfo = _poiWayCollections.poiholderCollections[Math.max(this.zoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!;
    for (PointOfInterest pointOfInterest in pois) {
      poiinfo.setPoidata(pointOfInterest);
    }
  }

  /// Adds a list of ways to the appropriate zoom level within this sub-file.
  void addWaydata(ZoomlevelRange zoomlevelRange, List<Wayholder> wayholders) {
    if (this.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
    if (this.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
    WayholderCollection wayinfo = _poiWayCollections.wayholderCollections[Math.max(this.zoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!;
    wayinfo.addWayholders(wayholders);
  }

  Future<void> _processAsync(
    String title,
    ProcessFunc process, [
    Future<void> Function(int currentTileY, int processedTiles, int sumTiles)? lineProcess,
  ]) async {
    int started = DateTime.now().millisecondsSinceEpoch;
    int lastProcessedTiles = 0;
    for (int tileY = _minY; tileY <= _maxY; ++tileY) {
      for (int tileX = _minX; tileX <= _maxX; ++tileX) {
        Tile tile = Tile(tileX, tileY, baseZoomLevel, 0);
        await process(tile);
      }
      int processedTiles = (tileY - _minY + 1) * (_maxX - _minX + 1);
      if (lineProcess != null) {
        await lineProcess(tileY, processedTiles, tileCount);
      }
      int diff = DateTime.now().millisecondsSinceEpoch - started;
      if (diff >= 1000 * 60) {
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
      int count = 0;
      for (int tileX = _minX; tileX <= _maxX; ++tileX) {
        Tile tile = Tile(tileX, tileY, baseZoomLevel, 0);
        process(tile);
        ++count;
        if (count % 200 == 0) {
          int processedTiles = (tileY - _minY + 1) * (_maxX - _minX + 1);
          if (lineProcess != null) {
            lineProcess(processedTiles, tileCount);
          }
        }
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
    _log.info("prepare tiles $zoomlevelRange with $tileCount tiles");
    List<ITileWriter> tileWriters = await createTileWriters(_minY, instanceCount, debugFile, maxDeviationPixel);
    // each instance must process this number of consecutive tiles
    // makes no sense to create multiple isolates for so few tiles
    if (tileCount < 50) instanceCount = 1;
    // too many tiles (hence too many ways). Danger of OutOfMemory Exception
    //if (tileCount > 50000 && instanceCount > 2) instanceCount = 2;

    // the isolates now hove the infos, we can remove them from memory here
    List<Future> futures = [];
    int current = 0;
    await _processAsync(
      "preparing tiles",
      (tile) async {
        Future future = _future(tileWriters[current], tile);
        futures.add(future);
        ++current;
        if (current >= instanceCount) {
          current = 0;
        }
      },
      (int currentTileY, int processedTiles, int sumTiles) async {
        if (futures.length > instanceCount * 10 || processedTiles == sumTiles) {
          //_log.info("Waiting for ${futures.length} futures. Currently processed: $processedTiles / $sumTiles");
          await Future.wait(futures);
          futures.clear();
          tileBuffer.cacheToDisk(processedTiles, sumTiles);
        }
        if (tileCount > 100 && currentTileY < _maxY) {
          tileWriters.clear();
          tileWriters = await createTileWriters(currentTileY + 1, instanceCount, debugFile, maxDeviationPixel);
        }
      },
    );
    _poiWayCollections.clear();
    await tileBuffer.writeComplete();
    tileWriters.clear();
    session.complete();
  }

  Future<void> _future(ITileWriter tileWriter, Tile tile) async {
    Uint8List writebufferTile = await tileWriter.writeTile(tile);
    tileBuffer.set(tile, writebufferTile);
  }

  Future<List<ITileWriter>> createTileWriters(int currentTileY, int instanceCount, bool debugFile, double maxDeviationPixel) async {
    List<ITileWriter> result = [];
    PoiWayCollections prefiltered = _poiWayCollections;
    if (tileCount > 100) {
      Tile tile1 = Tile(_minX, currentTileY, baseZoomLevel, 0);
      Tile tile2 = Tile(_maxX, currentTileY, baseZoomLevel, 0);
      BoundingBox tileBoundingBox = tile1.getBoundingBox().extendBoundingBox(tile2.getBoundingBox());
      BoundaryFilter filter = BoundaryFilter();
      assert(_poiWayCollections.poiholderCollections.isNotEmpty, "poiWayCollections.poiholderCollections.isEmpty");
      assert(_poiWayCollections.wayholderCollections.isNotEmpty, "poiWayCollections.wayholderCollections.isEmpty");
      prefiltered = filter.filter(_poiWayCollections, tileBoundingBox);
      assert(prefiltered.poiholderCollections.isNotEmpty, "poiWayCollections.poiholderCollections.isEmpty");
      assert(prefiltered.wayholderCollections.isNotEmpty, "poiWayCollections.wayholderCollections.isEmpty");
    }
    for (int i = 0; i < instanceCount; ++i) {
      result.add(
        await IsolateTileWriter.create(debugFile, prefiltered, zoomlevelRange, maxDeviationPixel),
        // TileWriter(
        //   debugFile,
        //   Map.from(_poiholderCollection),
        //   Map.from(_wayholderCollection),
        //   zoomlevelRange,
        //   maxDeviationPixel,
        //   Math.min(_maxX - _minX + 1, iterationCount),
        // ),
      );
    }
    return result;
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
    int poiCount = _poiWayCollections.poiholderCollections.values.fold(0, (int combine, poiinfo) => combine + poiinfo.count);
    int wayCount = _poiWayCollections.wayholderCollections.values.fold(0, (combine, wayinfo) => combine + wayinfo.wayCount);
    int pathCount = _poiWayCollections.wayholderCollections.values.fold(
      0,
      (combine, wayinfo) => combine + wayinfo.wayholders.fold(0, (combine, wayholder) => combine + wayholder.pathCount()),
    );
    int nodeCount = _poiWayCollections.wayholderCollections.values.fold(0, (combine, wayinfo) => combine + wayinfo.nodeCount);
    _log.info(
      "$zoomlevelRange, baseZoomLevel: $baseZoomLevel, tiles: $tileCount, poi: $poiCount, way: $wayCount with ${wayCount != 0 ? (pathCount / wayCount).toStringAsFixed(1) : "n/a"} paths and ${pathCount != 0 ? (nodeCount / pathCount).toStringAsFixed(1) : "n/a"} nodes per path",
    );
  }
}

//////////////////////////////////////////////////////////////////////////////

class PoiWayCollections {
  /// minimum zoomlevel for all corresponding pois
  final Map<int, PoiholderCollection> poiholderCollections = {};

  /// minimum zoomlevel for all corresponding ways
  final Map<int, WayholderCollection> wayholderCollections = {};

  PoiWayCollections();

  void clear() {
    poiholderCollections.clear();
    wayholderCollections.clear();
  }
}
