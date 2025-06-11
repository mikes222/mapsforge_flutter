import 'dart:math' as Math;
import 'dart:typed_data';

import 'package:ecache/ecache.dart';
import 'package:isolate_task_queue/isolate_task_queue.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/subfile_creator.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/way_cropper.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/wayholder.dart';
import 'package:mapsforge_flutter/src/mapfile/writer/writebuffer.dart';
import 'package:mapsforge_flutter/src/utils/timing.dart';

import '../../../core.dart';
import '../../../maps.dart';
import '../../model/zoomlevel_range.dart';

@pragma("vm:entry-point")
class IsolateTileConstructor {
  late final FlutterIsolateInstance _isolateInstance;

  IsolateTileConstructor._();

  static Future<IsolateTileConstructor> create(
      bool debugFile, Map<int, Poiinfo> poiinfos, Map<int, Wayinfo> wayinfos, ZoomlevelRange zoomlevelRange, double maxDeviationPixel, int tileCountX) async {
    _TileConstructorInstanceRequest _request = _TileConstructorInstanceRequest(
        debugFile: debugFile,
        poiinfos: poiinfos,
        wayinfos: wayinfos,
        zoomlevelRange: zoomlevelRange,
        maxDeviationPixel: maxDeviationPixel,
        tileCountX: tileCountX);
    IsolateTileConstructor _instance = IsolateTileConstructor._();
    _instance._isolateInstance = await FlutterIsolateInstance.createInstance(createInstance: createInstance, instanceParams: _request);
    return _instance;
  }

  void dispose() {
    _isolateInstance.dispose();
  }

  Future<Uint8List> writeTile(Tile tile) async {
    return await _isolateInstance.compute(writeTileStatic, _TileConstructorRequest(tile: tile));
  }

  /// This is the instance variable. Note that it is a different instance in each isolate.
  static TileConstructor? _tileConstructor;

  @pragma('vm:entry-point')
  static void createInstance(Object object) {
    _TileConstructorInstanceRequest request = object as _TileConstructorInstanceRequest;
    _tileConstructor ??=
        TileConstructor(request.debugFile, request.poiinfos, request.wayinfos, request.zoomlevelRange, request.maxDeviationPixel, request.tileCountX);
    // init displaymodel since it is used for PixelProjection in WaySimplifyFilter in WayCropper
    DisplayModel();
  }

  @pragma('vm:entry-point')
  static Future<Uint8List> writeTileStatic(_TileConstructorRequest request) async {
    return _tileConstructor!.writeTile(request.tile);
  }
}

//////////////////////////////////////////////////////////////////////////////

@pragma("vm:entry-point")
class IsolatePoolTileConstructor {
  late final FlutterIsolateInstancePool _isolateInstancePool;

  IsolatePoolTileConstructor(
      bool debugFile, Map<int, Poiinfo> poiinfos, Map<int, Wayinfo> wayinfos, ZoomlevelRange zoomlevelRange, double maxDeviationPixel, int tileCountX) {
    _isolateInstancePool = FlutterIsolateInstancePool(
        maxInstances: 6,
        createInstance: createPoolInstance,
        instanceParams: _TileConstructorInstanceRequest(
            debugFile: debugFile,
            poiinfos: poiinfos,
            wayinfos: wayinfos,
            zoomlevelRange: zoomlevelRange,
            maxDeviationPixel: maxDeviationPixel,
            tileCountX: tileCountX));
  }

  void dispose() {
    _isolateInstancePool.dispose();
  }

  Future<Uint8List> writeTile(Tile tile) async {
    return await _isolateInstancePool.compute(writePoolTileStatic, _TileConstructorRequest(tile: tile));
  }

  /// This is the instance variable. Note that it is a different instance in each isolate.
  static TileConstructor? _tileConstructor;

  @pragma('vm:entry-point')
  static void createPoolInstance(Object object) {
    _TileConstructorInstanceRequest request = object as _TileConstructorInstanceRequest;
    _tileConstructor ??=
        TileConstructor(request.debugFile, request.poiinfos, request.wayinfos, request.zoomlevelRange, request.maxDeviationPixel, request.tileCountX);
    // init displaymodel since it is used for PixelProjection in WaySimplifyFilter in WayCropper
    DisplayModel();
  }

  @pragma('vm:entry-point')
  static Future<Uint8List> writePoolTileStatic(_TileConstructorRequest request) async {
    return _tileConstructor!.writeTile(request.tile);
  }
}

//////////////////////////////////////////////////////////////////////////////

class _TileConstructorInstanceRequest {
  final Map<int, Poiinfo> poiinfos;

  final Map<int, Wayinfo> wayinfos;

  final ZoomlevelRange zoomlevelRange;

  final double maxDeviationPixel;

  final bool debugFile;

  final int tileCountX;

  _TileConstructorInstanceRequest({
    required this.tileCountX,
    required this.debugFile,
    required this.poiinfos,
    required this.wayinfos,
    required this.zoomlevelRange,
    required this.maxDeviationPixel,
  });
}

//////////////////////////////////////////////////////////////////////////////

class _TileConstructorRequest {
  final Tile tile;

  _TileConstructorRequest({required this.tile});
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

  final double maxDeviationPixel;

  final bool debugFile;

  final _PoiWayInfos _poiWayInfos;

  SimpleCache<BoundingBox, _PoiWayInfos> _cache = SimpleCache(capacity: 1);

  BoundingBox _boundingBox = BoundingBox.fromLatLongs([const LatLong(0, 0)]);

  ZoomlevelRange zoomlevelRange;

  final int tileCountX;

  Tile? first;

  int lastRemove = 0;

  TileConstructor(this.debugFile, Map<int, Poiinfo> poiinfos, Map<int, Wayinfo> wayinfos, this.zoomlevelRange, this.maxDeviationPixel, this.tileCountX)
      : _poiWayInfos = _PoiWayInfos(poiinfos, wayinfos);

  _PoiWayInfos _prefilter(Tile tile, BoundingBox tileBoundingBox) {
    // before we start prefiltering remove items which are not needed anymore. Do it in the save area of the cache to prevent concurrent execution.
    _removeOld(tile);
    Map<int, Poiinfo> resultPoi = {};
    _poiWayInfos.poiinfos.forEach((zoomlevel, poiinfo) {
      Poiinfo newPoiinfo = Poiinfo();
      poiinfo.poiholders.forEach((poiholder) {
        if (tileBoundingBox.containsLatLong(poiholder.poi.position)) {
          newPoiinfo.addPoiholder(poiholder);
        }
      });
      resultPoi[zoomlevel] = newPoiinfo;
    });

    Map<int, Wayinfo> resultWay = {};
    _poiWayInfos.wayinfos.forEach((zoomlevel, wayinfo) {
      Wayinfo newWayinfo = Wayinfo();
      wayinfo.wayholders.forEach((wayholder) {
        BoundingBox wayBoundingBox = wayholder.boundingBoxCached;
        if (tileBoundingBox.containsBoundingBox(wayBoundingBox)) {
          newWayinfo.addWayholder(wayholder);
        } else if (wayBoundingBox.containsBoundingBox(tileBoundingBox)) {
          // if (wayholder.way.latLongs[0].length > 50) {
          //   // this is a long way, see if it really intersects with the current tile2
          //   bool inTile = false;
          //   for (ILatLong point in wayholder.way.latLongs[0]) {
          //     if (tileBoundingBox.containsLatLong(point)) {
          //       inTile = true;
          //       break;
          //     }
          //   }
          //   if (inTile) {
          //     newWayinfo.addWayholder(wayholder);
          //   } else {
          //
          //   }
          // } else {
          newWayinfo.addWayholder(wayholder);
//          }
        } else if (tileBoundingBox.intersects(wayBoundingBox)) {
          newWayinfo.addWayholder(wayholder);
        }
      });
      resultWay[zoomlevel] = newWayinfo;
    });
    _boundingBox = tileBoundingBox;
    _PoiWayInfos poiWayInfos = _PoiWayInfos(resultPoi, resultWay);
    return poiWayInfos;
  }

  _PoiWayInfos _filterPrefiltered(_PoiWayInfos poiWayInfos, Tile tile) {
    Map<int, Poiinfo> resultPoi = {};
    poiWayInfos.poiinfos.forEach((zoomlevel, poiinfo) {
      Poiinfo newPoiinfo = Poiinfo();
      poiinfo.poiholders.forEach((poiholder) {
        if (tile.getBoundingBox().containsLatLong(poiholder.poi.position)) {
          newPoiinfo.addPoiholder(poiholder);
        }
      });
      resultPoi[zoomlevel] = newPoiinfo;
    });
    Map<int, Wayinfo> resultWay = {};
    WayCropper wayCropper = WayCropper(maxDeviationPixel: maxDeviationPixel);
    BoundingBox boundingBox = tile.getBoundingBox().extendMargin(margin);
    poiWayInfos.wayinfos.forEach((zoomlevel, wayinfo) {
      Wayinfo newWayinfo = Wayinfo();
      wayinfo.wayholders.forEach((wayholder) {
        BoundingBox wayBoundingBox = wayholder.boundingBoxCached;
        if (tile.getBoundingBox().intersects(wayBoundingBox) ||
            tile.getBoundingBox().containsBoundingBox(wayBoundingBox) ||
            wayBoundingBox.containsBoundingBox(tile.getBoundingBox())) {
          Wayholder? wayCropped = wayCropper.cropWay(wayholder, boundingBox, zoomlevelRange.zoomlevelMax);
          if (wayCropped != null) newWayinfo.addWayholder(wayCropped);
        }
      });
      resultWay[zoomlevel] = newWayinfo;
    });
    return _PoiWayInfos(resultPoi, resultWay);
  }

  /// Removes ways and pois which are not needed anymore. We remember the first tile and since the tiles comes in order we can remove everything
  /// which is contained in the boundary referenced by the first tile and the most current one. Do this just once in a while.
  void _removeOld(Tile newTile) {
    if (newTile == first) return;
    if (lastRemove == 0) {
      lastRemove = DateTime.now().millisecondsSinceEpoch;
      return;
    }
    // cleanup every minute
    if (DateTime.now().millisecondsSinceEpoch - lastRemove < 1000 * 60) return;
    Timing timing = Timing(log: _log);
    BoundingBox boundingBox = newTile.getBoundingBox().extendBoundingBox(first!.getBoundingBox());
    int poicountBefore = _poiWayInfos.poiinfos.values.fold(0, (idx, combine) => idx + combine.poiholders.length);
    _poiWayInfos.poiinfos.forEach((zoomlevel, poiinfo) {
      List.from(poiinfo.poiholders).forEach((poiholder) {
        if (boundingBox.containsLatLong(poiholder.poi.position)) {
          poiinfo.poiholders.remove(poiholder);
        }
      });
    });
    int poicountAfter = _poiWayInfos.poiinfos.values.fold(0, (idx, combine) => idx + combine.poiholders.length);
    timing.lap(200, "Removed old poi values $poicountBefore -> $poicountAfter");
    int waycountBefore = _poiWayInfos.wayinfos.values.fold(0, (idx, combine) => idx + combine.wayholders.length);
    _poiWayInfos.wayinfos.forEach((zoomlevel, wayinfo) {
      List.from(wayinfo.wayholders).forEach((wayholder) {
        BoundingBox wayBoundingBox = wayholder.boundingBoxCached;
        if (boundingBox.containsBoundingBox(wayBoundingBox)) {
          wayinfo.wayholders.remove(wayholder);
        }
      });
    });
    int waycountAfter = _poiWayInfos.wayinfos.values.fold(0, (idx, combine) => idx + combine.wayholders.length);
    timing.done(200, "Removed old way values $poicountBefore -> $poicountAfter, $waycountBefore -> $waycountAfter");
    lastRemove = DateTime.now().millisecondsSinceEpoch;
  }

  Future<_PoiWayInfos> _filterForTile(Tile tile) async {
    if (_boundingBox.containsBoundingBox(tile.getBoundingBox())) {
      _PoiWayInfos poiWayInfos = await _cache.getOrProduce(_boundingBox, (v) async => _prefilter(tile, _boundingBox));
      return _filterPrefiltered(poiWayInfos, tile);
    } else {
      Tile tile2 = Tile(Math.min(tile.tileX + tileCountX, Tile.getMaxTileNumber(tile.zoomLevel)), tile.tileY, tile.zoomLevel, tile.indoorLevel);
      BoundingBox tileBoundingBox = tile.getBoundingBox().extendBoundingBox(tile2.getBoundingBox());
      _PoiWayInfos poiWayInfos = await _cache.getOrProduce(tileBoundingBox, (v) async => _prefilter(tile, tileBoundingBox));
      return _filterPrefiltered(poiWayInfos, tile);
    }
  }

  /// Processes the block signature, if present.
  ///
  /// @return true if the block signature could be processed successfully, false otherwise.
  void _writeTileHeaderSignature(Tile tile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("###TileStart${tile.tileX},${tile.tileY}###".padRight(MapFile.SIGNATURE_LENGTH_BLOCK, " "));
    }
  }

  void _writeZoomtable(Tile tile, Writebuffer writebuffer, Map<int, Poiinfo> poisPerZoomlevel, Map<int, Wayinfo> waysPerZoomlevel) {
    for (int queryZoomLevel = zoomlevelRange.zoomlevelMin; queryZoomLevel <= zoomlevelRange.zoomlevelMax; queryZoomLevel++) {
      Poiinfo poiinfo = poisPerZoomlevel[queryZoomLevel]!;
      Wayinfo wayinfo = waysPerZoomlevel[queryZoomLevel]!;
      int poiCount = poiinfo.count;
      int wayCount = wayinfo.wayCount;
      writebuffer.appendUnsignedInt(poiCount);
      writebuffer.appendUnsignedInt(wayCount);
    }
  }

  Future<Uint8List> writeTile(Tile tile) async {
    first ??= tile;
    Writebuffer writebuffer = Writebuffer();
    _PoiWayInfos poiWayInfos = await _filterForTile(tile);
    _writeTileHeaderSignature(tile, writebuffer);

    _writeZoomtable(tile, writebuffer, poiWayInfos.poiinfos, poiWayInfos.wayinfos);

    MercatorProjection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
    double tileLatitude = projection.tileYToLatitude(tile.tileY);
    double tileLongitude = projection.tileXToLongitude(tile.tileX);

    // the offset to the first way in the block
    int firstWayOffset = 0;
    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      Poiinfo poiinfo = poiWayInfos.poiinfos[zoomlevel]!;
      poiinfo.writePoidata(debugFile, tileLatitude, tileLongitude);
      firstWayOffset += poiinfo.content!.length;
    }
    writebuffer.appendUnsignedInt(firstWayOffset);
    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      Poiinfo poiinfo = poiWayInfos.poiinfos[zoomlevel]!;
      writebuffer.appendUint8(poiinfo.content!);
      poiinfo.content = null;
      poiinfo.poiholders.clear();
    }
    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      Wayinfo wayinfo = poiWayInfos.wayinfos[zoomlevel]!;
      wayinfo.writeWaydata(debugFile, tile, tileLatitude, tileLongitude);
      writebuffer.appendUint8(wayinfo.content!);
      wayinfo.content = null;
    }
    return writebuffer.getUint8List();
  }
}

//////////////////////////////////////////////////////////////////////////////

class _PoiWayInfos {
  Map<int, Poiinfo> poiinfos = {};

  Map<int, Wayinfo> wayinfos = {};

  _PoiWayInfos(this.poiinfos, this.wayinfos);
}
