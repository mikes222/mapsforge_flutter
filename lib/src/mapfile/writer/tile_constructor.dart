import 'dart:math' as Math;
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/subfile_creator.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/way_cropper.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';

import '../../../core.dart';
import '../../../maps.dart';
import '../../model/zoomlevel_range.dart';
import '../../utils/flutter_isolate.dart';

@pragma("vm:entry-point")
class IsolateTileConstructor {
  Map<int, Poiinfo> poiinfos = {};

  Map<int, Wayinfo> wayinfos = {};

  ZoomlevelRange zoomlevelRange;

  late final FlutterIsolateInstancePool _isolateInstancePool;

  IsolateTileConstructor(this.poiinfos, this.wayinfos, this.zoomlevelRange) {
    _isolateInstancePool = FlutterIsolateInstancePool(
        createInstance: createInstance,
        instanceParams: _TileConstructorInstanceRequest(
            poiinfos: poiinfos,
            wayinfos: wayinfos,
            zoomlevelRange: zoomlevelRange));
  }

  void dispose() {
    poiinfos.clear();
    wayinfos.clear();
    _isolateInstancePool.dispose();
  }

  Future<Uint8List> writeTile(bool debugFile, Tile tile) async {
    return await _isolateInstancePool.compute(writeTileStatic,
        _TileConstructorRequest(debugFile: debugFile, tile: tile));
  }

  /// This is the instance variable. Note that it is a different instance in each isolate.
  static TileConstructor? _tileConstructor;

  @pragma('vm:entry-point')
  static void createInstance(Object object) {
    _TileConstructorInstanceRequest request =
        object as _TileConstructorInstanceRequest;
    _tileConstructor ??= TileConstructor(
        request.poiinfos, request.wayinfos, request.zoomlevelRange);
  }

  @pragma('vm:entry-point')
  static Future<Uint8List> writeTileStatic(
      _TileConstructorRequest request) async {
    return _tileConstructor!.writeTile(request.debugFile, request.tile);
  }
}

//////////////////////////////////////////////////////////////////////////////

class _TileConstructorInstanceRequest {
  final Map<int, Poiinfo> poiinfos;

  final Map<int, Wayinfo> wayinfos;

  final ZoomlevelRange zoomlevelRange;

  _TileConstructorInstanceRequest({
    required this.poiinfos,
    required this.wayinfos,
    required this.zoomlevelRange,
  });
}

//////////////////////////////////////////////////////////////////////////////

class _TileConstructorRequest {
  final bool debugFile;

  final Tile tile;

  _TileConstructorRequest({required this.debugFile, required this.tile});
}

//////////////////////////////////////////////////////////////////////////////

/// Constructs a single tile.
class TileConstructor {
  final _log = new Logger('TileConstructor');

  /// depending on the thickest line we draw we have to extend the margin so that
  /// a surrounding area is not visible in the tile.
  /// On the other side we may include more waypoints even if they are not visible
  /// in the margin.
  final double margin = 1.15;

  Map<int, Poiinfo> poiinfos = {};

  Map<int, Wayinfo> wayinfos = {};

  Map<int, Poiinfo> _poiinfosPrefiltered = {};

  Map<int, Wayinfo> _wayinfosPrefiltered = {};

  BoundingBox _poiBoundingBox = BoundingBox.fromLatLongs([const LatLong(0, 0)]);

  BoundingBox _wayBoundingBox = BoundingBox.fromLatLongs([const LatLong(0, 0)]);

  ZoomlevelRange zoomlevelRange;

  TileConstructor(this.poiinfos, this.wayinfos, this.zoomlevelRange);

  Map<int, Poiinfo> _filterPoisForTilePrefiltered(Tile tile) {
    Map<int, Poiinfo> result = {};
    _poiinfosPrefiltered.forEach((zoomlevel, poiinfo) {
      Poiinfo newPoiinfo = Poiinfo();
      poiinfo.poiholders.forEach((poiholder) {
        if (tile.getBoundingBox().containsLatLong(poiholder.poi.position)) {
          newPoiinfo.addPoiholder(poiholder);
        }
      });
      result[zoomlevel] = newPoiinfo;
    });
    return result;
  }

  Map<int, Poiinfo> _filterPoisForTile(Tile tile) {
    if (_poiBoundingBox.containsBoundingBox(tile.getBoundingBox())) {
      return _filterPoisForTilePrefiltered(tile);
    }
    Tile tile2 = Tile(
        Math.min(tile.tileX + 10, Tile.getMaxTileNumber(tile.zoomLevel)),
        tile.tileY,
        tile.zoomLevel,
        tile.indoorLevel);
    BoundingBox tileBoundingBox =
        tile.getBoundingBox().extendBoundingBox(tile2.getBoundingBox());
    Map<int, Poiinfo> result = {};
    poiinfos.forEach((zoomlevel, poiinfo) {
      Poiinfo newPoiinfo = Poiinfo();
      poiinfo.poiholders.forEach((poiholder) {
        if (tileBoundingBox.containsLatLong(poiholder.poi.position)) {
          newPoiinfo.addPoiholder(poiholder);
        }
      });
      result[zoomlevel] = newPoiinfo;
    });
    _poiinfosPrefiltered = result;
    _poiBoundingBox = tileBoundingBox;
    return _filterPoisForTilePrefiltered(tile);
  }

  Map<int, Wayinfo> _filterWaysForTilePrefiltered(Tile tile) {
    Map<int, Wayinfo> result = {};
    WayCropper wayCropper = WayCropper();
    BoundingBox boundingBox = tile.getBoundingBox().extendMargin(margin);
    _wayinfosPrefiltered.forEach((zoomlevel, wayinfo) {
      Wayinfo newWayinfo = Wayinfo();
      wayinfo.wayholders.forEach((wayholder) {
        BoundingBox wayBoundingBox = wayholder.way.getBoundingBox();
        if (tile.getBoundingBox().intersects(wayBoundingBox) ||
            tile.getBoundingBox().containsBoundingBox(wayBoundingBox) ||
            wayBoundingBox.containsBoundingBox(tile.getBoundingBox())) {
          Wayholder wayCropped = wayCropper.cropWay(wayholder, boundingBox);
          if (wayCropped.way.latLongs.isNotEmpty)
            newWayinfo.addWayholder(wayCropped);
        }
      });
      result[zoomlevel] = newWayinfo;
    });
    return result;
  }

  Map<int, Wayinfo> _filterWaysForTile(Tile tile) {
    if (_wayBoundingBox.containsBoundingBox(tile.getBoundingBox())) {
      return _filterWaysForTilePrefiltered(tile);
    }
    Tile tile2 = Tile(
        Math.min(tile.tileX + 10, Tile.getMaxTileNumber(tile.zoomLevel)),
        tile.tileY,
        tile.zoomLevel,
        tile.indoorLevel);
    BoundingBox tileBoundingBox =
        tile.getBoundingBox().extendBoundingBox(tile2.getBoundingBox());
    Map<int, Wayinfo> result = {};
    wayinfos.forEach((zoomlevel, wayinfo) {
      Wayinfo newWayinfo = Wayinfo();
      wayinfo.wayholders.forEach((wayholder) {
        BoundingBox wayBoundingBox = wayholder.way.getBoundingBox();
        if (tileBoundingBox.intersects(wayBoundingBox) ||
            tileBoundingBox.containsBoundingBox(wayBoundingBox) ||
            wayBoundingBox.containsBoundingBox(tileBoundingBox)) {
          newWayinfo.addWayholder(wayholder);
        }
      });
      result[zoomlevel] = newWayinfo;
    });
    _wayinfosPrefiltered = result;
    _wayBoundingBox = tileBoundingBox;
    return _filterWaysForTilePrefiltered(tile);
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

  Uint8List writeTile(bool debugFile, Tile tile) {
    Writebuffer writebuffer = Writebuffer();
//    Timing timing = Timing(log: _log);
    Map<int, Poiinfo> poisPerZoomlevel = _filterPoisForTile(tile);
    Map<int, Wayinfo> waysPerZoomlevel = _filterWaysForTile(tile);
    // timing.lap(1000,
    //     "tile: $tile, poiCount: ${poisPerZoomlevel.values.fold(0, (count, combine) => count + combine.count)}, wayCount: ${waysPerZoomlevel.values.fold(0, (count, combine) => count + combine.count)}");
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
      poiinfo.poiholders.clear();
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
}
