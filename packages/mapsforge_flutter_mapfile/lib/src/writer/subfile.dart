import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/filter/boundary_filter.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/tile_buffer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/tile_writer.dart';

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
class Subfile {
  static final _log = Logger('Subfile');

  /// Base zoom level of the sub-file, which equals to one block.
  final int baseZoomLevel;

  final ZoomlevelRange zoomlevelRange;

  final MapHeaderInfo mapHeaderInfo;

  late final PoiWayCollections _poiWayCollections;

  late final int _minX;

  late final int _minY;

  late final int _maxX;

  late final int _maxY;

  late final int _tileCount;

  Writebuffer? _writebufferTileIndex;

  late final TileBuffer _tileBuffer;

  final BoundaryFilter filter = BoundaryFilter();

  final TagholderModel model;

  Subfile({
    required this.baseZoomLevel,
    required this.zoomlevelRange,
    required this.mapHeaderInfo,
    required PoiWayCollections poiWayCollections,
    required this.model,
  }) {
    MercatorProjection projection = MercatorProjection.fromZoomlevel(baseZoomLevel);
    _minX = projection.longitudeToTileX(mapHeaderInfo.boundingBox.minLongitude);
    _maxX = projection.longitudeToTileX(mapHeaderInfo.boundingBox.maxLongitude);
    _minY = projection.latitudeToTileY(mapHeaderInfo.boundingBox.maxLatitude);
    _maxY = projection.latitudeToTileY(mapHeaderInfo.boundingBox.minLatitude);
    _tileCount = (_maxX - _minX + 1) * (_maxY - _minY + 1);

    assert(_minX >= 0, "minX $_minX < 0 for ${mapHeaderInfo.boundingBox} and $baseZoomLevel");
    assert(_minY >= 0, "minY $_minY < 0 for ${mapHeaderInfo.boundingBox} and $baseZoomLevel");
    _tileBuffer = TileBuffer(baseZoomLevel);

    _poiWayCollections = poiWayCollections;
  }

  void dispose() {
    _tileBuffer.dispose();
    _poiWayCollections.clear();
    _writebufferTileIndex = null;
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
          "Processed ${(processedTiles / tileCount * 100).round()}% ($processedTiles) of tiles for $title at baseZoomLevel $baseZoomLevel (${((processedTiles - lastProcessedTiles) / diff * 1000).toStringAsFixed(1)} tiles/sec)",
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
  Future<void> prepareTiles(bool debugFile, int instanceCount) async {
    var session = PerformanceProfiler().startSession(category: "SubfileCreator.prepareTiles");

    List<String> languagesPreferences = [];
    if (mapHeaderInfo.languagesPreference != null) languagesPreferences.addAll(mapHeaderInfo.languagesPreference!.split(","));

    // each instance must process this number of consecutive tiles
    // makes no sense to create multiple isolates for so few tiles
    if (tileCount <= 100) instanceCount = 1;
    // too many tiles (hence too many ways). Danger of OutOfMemory Exception
    //if (tileCount > 50000 && instanceCount > 2) instanceCount = 2;

    List<ITileWriter> tileWriters = await createTileWriters(_minY, instanceCount, debugFile, languagesPreferences);
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
        if (futures.length > 20) {
          await Future.wait(futures);
          futures.clear();
        }
      },
      (int currentTileY, int processedTiles, int sumTiles) async {
        // wait until all futures are completed and write the results to the tileBuffer
        await Future.wait(futures);
        futures.clear();
        if (tileCount > 100) {
          if (currentTileY > _minY && (currentTileY % 5 == 0)) {
            // remove data from previous lines (y)
            Tile tile1 = Tile(_minX, _minY, baseZoomLevel, 0);
            Tile tile2 = Tile(_maxX, currentTileY - 1, baseZoomLevel, 0);
            BoundingBox tileBoundingBox = tile1.getBoundingBox().extendBoundingBox(tile2.getBoundingBox());
            await filter.remove(_poiWayCollections, tileBoundingBox);
          }
          // destroy old writers and build writers with prefiltered data for the next line
          for (var tileWriter in tileWriters) {
            tileWriter.dispose();
          }
          tileWriters.clear();
          if (currentTileY < _maxY) {
            tileWriters = await createTileWriters(currentTileY + 1, instanceCount, debugFile, languagesPreferences);
          }
        }
      },
    );
    await _poiWayCollections.clear();
    await _tileBuffer.writeComplete();
    session.complete();
  }

  Future<void> _future(ITileWriter tileWriter, Tile tile) async {
    Uint8List writebufferTile = await tileWriter.writeTile(tile);
    _tileBuffer.set(tile, writebufferTile);
  }

  Future<List<ITileWriter>> createTileWriters(int currentTileY, int instanceCount, bool debugFile, List<String> languagesPreferences) async {
    List<ITileWriter> result = [];
    PoiWayCollections prefiltered = _poiWayCollections;
    if (tileCount > 100) {
      Tile tile1 = Tile(_minX, currentTileY, baseZoomLevel, 0);
      Tile tile2 = Tile(_maxX, currentTileY, baseZoomLevel, 0);
      BoundingBox tileBoundingBox = tile1.getBoundingBox().extendBoundingBox(tile2.getBoundingBox());
      prefiltered = await filter.filter(_poiWayCollections, tileBoundingBox);
      assert(prefiltered.poiholderCollections.isNotEmpty, "poiWayCollections.poiholderCollections.isEmpty");
      assert(prefiltered.wayholderCollections.isNotEmpty, "poiWayCollections.wayholderCollections.isEmpty");
    }
    // print("for $currentTileY");
    // for (var entry in prefiltered.poiholderCollections.entries) {
    //   if (entry.key < 15)
    //     for (var poiholder in await entry.value.getAll()) {
    //       print("filter ${entry.key}: ${poiholder}");
    //     }
    // }
    for (int i = 0; i < instanceCount; ++i) {
      result.add(
        await IsolateTileWriter.create(debugFile, prefiltered, zoomlevelRange, languagesPreferences, model),
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
      offset += _tileBuffer.getLength(tile);
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
      result += _tileBuffer.getLength(tile);
    });
    return result;
  }

  /// Writes all tile data for this sub-file to the given [ioSink].
  Future<void> writeTiles(bool debugFile, SinkWithCounter ioSink) async {
    await _processAsync("writing tiles", (tile) async {
      Uint8List contentForTile = await _tileBuffer.getAndRemove(tile);
      ioSink.add(contentForTile);
    });
  }

  int get tileCount => _tileCount;

  /// Logs statistics about the contents of this sub-file.
  Future<void> statistics() async {
    int poiCount = 0;
    for (final poiholderCollection in _poiWayCollections.poiholderCollections.values) {
      poiCount += poiholderCollection.length;
    }

    int wayCount = 0;
    int pathCount = 0;
    int nodeCount = 0;
    for (final wayholderCollection in _poiWayCollections.wayholderCollections.values) {
      wayCount += wayholderCollection.length;
      pathCount += await wayholderCollection.pathCount();
      nodeCount += await wayholderCollection.nodeCount();
    }

    _log.info(
      "$zoomlevelRange, baseZoomLevel: $baseZoomLevel, tiles: $tileCount, poi: $poiCount, way: $wayCount with ${wayCount != 0 ? (pathCount / wayCount).toStringAsFixed(1) : "n/a"} paths and ${pathCount != 0 ? (nodeCount / pathCount).toStringAsFixed(1) : "n/a"} nodes per path",
    );
  }
}

//////////////////////////////////////////////////////////////////////////////

class PoiWayCollections {
  /// minimum zoomlevel for all corresponding pois
  final Map<int, IPoiholderCollection> poiholderCollections = {};

  /// minimum zoomlevel for all corresponding ways
  final Map<int, IWayholderCollection> wayholderCollections = {};

  PoiWayCollections();

  Future<void> clear() async {
    for (var poiholderCollection in poiholderCollections.values) {
      await poiholderCollection.dispose();
    }
    for (var wayholderCollection in wayholderCollections.values) {
      await wayholderCollection.dispose();
    }
    poiholderCollections.clear();
    wayholderCollections.clear();
  }

  Future<void> freeRessources() async {
    for (var poiholderCollection in poiholderCollections.values) {
      await poiholderCollection.freeRessources();
    }
    for (var wayholderCollection in wayholderCollections.values) {
      await wayholderCollection.freeRessources();
    }
  }
}
