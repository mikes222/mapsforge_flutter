import 'dart:math' as Math;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/mapfile/map_header_info.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/mapfile_writer.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/poiholder.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/way_cropper.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';
import 'package:mapsforge_flutter/src/model/zoomlevel_range.dart';
import 'package:mapsforge_flutter/src/utils/timing.dart';

import '../../../core.dart';
import '../../../datastore.dart';
import '../../../maps.dart';

/// Each subfile consists of:
/// tile index header
//     for each base-tile: tile index entry
//
//     for each base-tile
//         tile header
//         for each POI: POI data
//         for each way: way properties
//             for each wayblock: way data

typedef ProcessFunc(Tile tile);

class SubfileCreator {
  final _log = new Logger('SubfileCreator');

  /// Base zoom level of the sub-file, which equals to one block.
  final int baseZoomLevel;

  final ZoomlevelRange zoomlevelRange;

  final BoundingBox boundingBox;

  final MapHeaderInfo mapHeaderInfo;

  Map<int, Poiinfo> _poiinfos = {};

  Map<int, Wayinfo> _wayinfos = {};

  Map<Tile, Uint8List> _writebufferForTiles = {};

  late final int _minX;

  late final int _minY;

  late final int _maxX;

  late final int _maxY;

  Writebuffer? _writebufferTileIndex;

  Writebuffer? _writebufferTiles;

  SubfileCreator(
      {required this.baseZoomLevel,
      required this.zoomlevelRange,
      required this.boundingBox,
      required this.mapHeaderInfo}) {
    MercatorProjection projection =
        MercatorProjection.fromZoomlevel(baseZoomLevel);
    _minX = projection.longitudeToTileX(boundingBox.minLongitude);
    _maxX = projection.longitudeToTileX(boundingBox.maxLongitude);
    _minY = projection.latitudeToTileY(boundingBox.maxLatitude);
    _maxY = projection.latitudeToTileY(boundingBox.minLatitude);

    for (int zoomlevel = zoomlevelRange.zoomlevelMin;
        zoomlevel <= zoomlevelRange.zoomlevelMax;
        ++zoomlevel) {
      _poiinfos[zoomlevel] = Poiinfo();
      _wayinfos[zoomlevel] = Wayinfo();
    }
  }

  void addPoidata(ZoomlevelRange zoomlevelRange, List<PointOfInterest> pois) {
    if (this.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
    if (this.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
    Poiinfo poiinfo = _poiinfos[Math.max(
        this.zoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!;
    for (PointOfInterest pointOfInterest in pois) {
      poiinfo.setPoidata(pointOfInterest);
    }
  }

  void addWaydata(ZoomlevelRange zoomlevelRange, List<Wayholder> wayholders) {
    if (this.zoomlevelRange.zoomlevelMin > zoomlevelRange.zoomlevelMax) return;
    if (this.zoomlevelRange.zoomlevelMax < zoomlevelRange.zoomlevelMin) return;
    Wayinfo wayinfo = _wayinfos[Math.max(
        this.zoomlevelRange.zoomlevelMin, zoomlevelRange.zoomlevelMin)]!;
    for (Wayholder wayholder in wayholders) {
      wayinfo.setWaydata(wayholder.way);
    }
  }

  void analyze(List<Tagholder> poiTagholders, List<Tagholder> wayTagholders,
      String? languagesPreference) {
    _poiinfos.forEach((zoomlevel, poiinfo) {
      poiinfo.analyze(poiTagholders, languagesPreference);
    });
    _wayinfos.forEach((zoomlevel, wayinfo) {
      wayinfo.analyze(wayTagholders, languagesPreference);
    });
  }

  Map<int, Poiinfo> _filterPoisForTile(Tile tile) {
    Map<int, Poiinfo> result = {};
    _poiinfos.forEach((zoomlevel, poiinfo) {
      result[zoomlevel] = Poiinfo();
      poiinfo._poiholders.forEach((poiholder) {
        if (tile.getBoundingBox().containsLatLong(poiholder.poi.position)) {
          result[zoomlevel]!.addPoiholder(poiholder);
        }
      });
    });
    return result;
  }

  Map<int, Wayinfo> _filterWaysForTile(Tile tile) {
    Map<int, Wayinfo> result = {};
    WayCropper wayCropper = WayCropper();
    _wayinfos.forEach((zoomlevel, wayinfo) {
      result[zoomlevel] = Wayinfo();
      wayinfo._wayholders.forEach((wayholder) {
        BoundingBox wayBoundingBox = wayholder.way.getBoundingBox();
        if (tile.getBoundingBox().intersects(wayBoundingBox) ||
            tile.getBoundingBox().containsBoundingBox(wayBoundingBox) ||
            wayBoundingBox.containsBoundingBox(tile.getBoundingBox())) {
          Wayholder wayCropped = wayCropper.cropWay(wayholder, tile);
          if (wayCropped.way.latLongs.isNotEmpty)
            result[zoomlevel]!.addWayholder(wayCropped);
        }
      });
    });
    return result;
  }

  void _process(ProcessFunc process) {
    int started = DateTime.now().millisecondsSinceEpoch;
    int sumTiles = (_maxY - _minY + 1) * (_maxX - _minX + 1);
    for (int tileY = _minY; tileY <= _maxY; ++tileY) {
      for (int tileX = _minX; tileX <= _maxX; ++tileX) {
        Tile tile = Tile(tileX, tileY, baseZoomLevel, 0);
        process(tile);
      }
      int diff = DateTime.now().millisecondsSinceEpoch - started;
      if (diff > 1000 * 60) {
        // more than one minute
        int processedTiles = (tileY - _minY + 1) * (_maxX - _minX + 1);
        print(
            "Processed ${(processedTiles / sumTiles * 100).round()}% of tiles for baseZoomLevel $baseZoomLevel");
        started = DateTime.now().millisecondsSinceEpoch;
      }
    }
  }

  void _writeIndexHeaderSignature(bool debugFile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("+++IndexStart+++");
    }
  }

  Writebuffer writeTileIndex(bool debugFile) {
    if (_writebufferTileIndex != null) return _writebufferTileIndex!;
    _writebufferTileIndex = Writebuffer();
    _writeIndexHeaderSignature(debugFile, _writebufferTileIndex!);
    // todo find out how to do this
    bool coveredByWater = false;
    int offset = _writebufferTileIndex!.length +
        5 * (_maxX - _minX + 1) * (_maxY - _minY + 1);
    int firstOffset = offset;
    _process((tile) {
      _writeTileIndexEntry(_writebufferTileIndex!, coveredByWater, offset);
      Uint8List writebufferTile = _writeTile(debugFile, tile);
      offset += writebufferTile.length;
      _writebufferForTiles[tile] = writebufferTile;
    });
    assert(firstOffset == _writebufferTileIndex!.length,
        "$firstOffset != ${_writebufferTileIndex!.length} with debug=$debugFile and baseZoomLevel=$baseZoomLevel");
    _poiinfos.clear();
    _wayinfos.clear();
    return _writebufferTileIndex!;
  }

  /// Note: to calculate how many tile index entries there will be, use the formulae at [http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames] to find out how many tiles will be covered by the bounding box at the base zoom level of the sub file
  void _writeTileIndexEntry(
      Writebuffer writebuffer, bool coveredByWater, int offset) {
    int indexEntry = 0;
    if (coveredByWater) indexEntry = indexEntry |= MapFile.BITMASK_INDEX_WATER;

    // 2.-40. bit (mask: 0x7f ff ff ff ff): 39 bit offset of the tile in the sub file as 5-bytes LONG (optional debug information and index size is also counted; byte order is BigEndian i.e. most significant byte first)
    // If the tile is empty offset(tile,,i,,) = offset(tile,,i+1,,)
    indexEntry = indexEntry |= offset;
    writebuffer.appendInt5(indexEntry);
  }

  Writebuffer writeTiles(bool debugFile) {
    if (_writebufferTiles != null) return _writebufferTiles!;
    _writebufferTiles = Writebuffer();
    _process((tile) {
      Uint8List contentForTile = _writebufferForTiles[tile]!;
      _writebufferTiles!.appendUint8(contentForTile);
      _writebufferForTiles.remove(tile);
    });
    return _writebufferTiles!;
  }

  Uint8List _writeTile(bool debugFile, Tile tile) {
    Writebuffer writebuffer = Writebuffer();
    Timing timing = Timing(log: _log);
    Map<int, Poiinfo> poisPerZoomlevel = _filterPoisForTile(tile);
    Map<int, Wayinfo> waysPerZoomlevel = _filterWaysForTile(tile);
    timing.lap(1000,
        "tile: $tile, poiCount: ${poisPerZoomlevel.values.fold(0, (count, combine) => count + combine.count)}, wayCount: ${waysPerZoomlevel.values.fold(0, (count, combine) => count + combine.count)}");
    _writeTileHeaderSignature(debugFile, tile, writebuffer);

    _writeZoomtable(tile, writebuffer, poisPerZoomlevel, waysPerZoomlevel);

    MercatorProjection projection =
        MercatorProjection.fromZoomlevel(tile.zoomLevel);
    double tileLatitude = projection.tileYToLatitude(tile.tileY);
    double tileLongitude = projection.tileXToLongitude(tile.tileX);

    // the offset to the first way in the block
    int firstWayOffset = 0;
    for (int zoomlevel = zoomlevelRange.zoomlevelMin;
        zoomlevel <= zoomlevelRange.zoomlevelMax;
        ++zoomlevel) {
      Poiinfo poiinfo = poisPerZoomlevel[zoomlevel]!;
      poiinfo.writePoidata(debugFile, tileLatitude, tileLongitude);
      firstWayOffset += poiinfo.content!.length;
    }
    writebuffer.appendUnsignedInt(firstWayOffset);
    for (int zoomlevel = zoomlevelRange.zoomlevelMin;
        zoomlevel <= zoomlevelRange.zoomlevelMax;
        ++zoomlevel) {
      Poiinfo poiinfo = poisPerZoomlevel[zoomlevel]!;
      writebuffer.appendUint8(poiinfo.content!);
      poiinfo.content = null;
      poiinfo._poiholders.clear();
    }
    for (int zoomlevel = zoomlevelRange.zoomlevelMin;
        zoomlevel <= zoomlevelRange.zoomlevelMax;
        ++zoomlevel) {
      Wayinfo wayinfo = waysPerZoomlevel[zoomlevel]!;
      wayinfo.writeWaydata(debugFile, tile, tileLatitude, tileLongitude);
      writebuffer.appendUint8(wayinfo.content!);
      wayinfo.content = null;
    }
    return writebuffer.getUint8List();
  }

  /// Processes the block signature, if present.
  ///
  /// @return true if the block signature could be processed successfully, false otherwise.
  void _writeTileHeaderSignature(
      bool debugFile, Tile tile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength(
          "###TileStart${tile.tileX},${tile.tileY}###"
              .padRight(MapFile.SIGNATURE_LENGTH_BLOCK, " "));
    }
  }

  void _writeZoomtable(Tile tile, Writebuffer writebuffer,
      Map<int, Poiinfo> poisPerZoomlevel, Map<int, Wayinfo> waysPerZoomlevel) {
    for (int queryZoomLevel = zoomlevelRange.zoomlevelMin;
        queryZoomLevel <= zoomlevelRange.zoomlevelMax;
        queryZoomLevel++) {
      Poiinfo poiinfo = poisPerZoomlevel[queryZoomLevel]!;
      Wayinfo wayinfo = waysPerZoomlevel[queryZoomLevel]!;
      int poiCount = poiinfo.count;
      int wayCount = wayinfo.count;
      writebuffer.appendUnsignedInt(poiCount);
      writebuffer.appendUnsignedInt(wayCount);
    }
  }

  void statistics() {
    int tileCount = (_maxX - _minX + 1) * (_maxY - _minY + 1);
    int poiCount = _poiinfos.values
        .fold(0, (int combine, Poiinfo poiinfo) => combine + poiinfo.count);
    int wayCount =
        _wayinfos.values.fold(0, (combine, wayinfo) => combine + wayinfo.count);
    print(
        "$zoomlevelRange, baseZoomLevel: $baseZoomLevel, tiles: $tileCount, poi: $poiCount, way: $wayCount");
  }
}

//////////////////////////////////////////////////////////////////////////////

/// All pois for one zoomlevel.
class Poiinfo {
  List<Poiholder> _poiholders = [];

  Uint8List? content;

  int count = 0;

  Poiinfo();

  void addPoiholder(Poiholder poiholder) {
    assert(content == null);
    _poiholders.add(poiholder);
    ++count;
  }

  void setPoidata(PointOfInterest poi) {
    assert(content == null);
    Poiholder poiholder = Poiholder(poi);
    _poiholders.add(poiholder);
    ++count;
  }

  bool contains(PointOfInterest poi) {
    assert(content == null);
    return _poiholders.firstWhereOrNull((test) => test.poi == poi) != null;
  }

  void analyze(List<Tagholder> tagholders, String? languagesPreference) {
    assert(content == null);
    for (Poiholder poiholder in _poiholders) {
      poiholder.analyze(tagholders, languagesPreference);
    }
  }

  Uint8List writePoidata(
      bool debugFile, double tileLatitude, double tileLongitude) {
    if (content != null) return content!;
    Writebuffer writebuffer = Writebuffer();
    for (Poiholder poiholder in _poiholders) {
      writebuffer.appendWritebuffer(
          poiholder.writePoidata(debugFile, tileLatitude, tileLongitude));
    }
    _poiholders.clear();
    content = writebuffer.getUint8List();
    return content!;
  }
}

//////////////////////////////////////////////////////////////////////////////

/// All ways for one zoomlevel.
class Wayinfo {
  List<Wayholder> _wayholders = [];

  Uint8List? content;

  int count = 0;

  Wayinfo();

  addWayholder(Wayholder wayholder) {
    assert(content == null);
    _wayholders.add(wayholder);
    ++count;
  }

  void setWaydata(Way way) {
    assert(content == null);
    Wayholder wayholder = Wayholder(way);
    _wayholders.add(wayholder);
    ++count;
  }

  Wayholder? searchWayholder(Way way) {
    assert(content == null);
    return _wayholders.firstWhereOrNull((test) => test.way == way);
  }

  void analyze(List<Tagholder> tagholders, String? languagesPreference) {
    assert(content == null);
    for (Wayholder wayholder in _wayholders) {
      wayholder.analyze(tagholders, languagesPreference);
    }
  }

  Uint8List writeWaydata(
      bool debugFile, Tile tile, double tileLatitude, double tileLongitude) {
    if (content != null) return content!;
    Writebuffer writebuffer = Writebuffer();
    for (Wayholder wayholder in _wayholders) {
      writebuffer.appendWritebuffer(
          wayholder.writeWaydata(debugFile, tile, tileLatitude, tileLongitude));
    }
    _wayholders.clear();
    content = writebuffer.getUint8List();
    return content!;
  }
}
