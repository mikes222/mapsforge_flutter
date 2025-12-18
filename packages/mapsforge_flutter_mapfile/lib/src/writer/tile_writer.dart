import 'dart:math' as Math;
import 'dart:typed_data';

import 'package:ecache/ecache.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/buffer.dart';
import 'package:mapsforge_flutter_core/dart_isolate.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/filter/way_cropper.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder_collection.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/wayholder_collection.dart';

/// An isolate-based wrapper for [TileWriter] to perform tile construction
/// in the background.
///
/// This is essential for performance, as it offloads the CPU-intensive work of
/// filtering, cropping, and serializing tile data from the main UI thread.
@pragma("vm:entry-point")
class IsolateTileWriter {
  late final FlutterIsolateInstance _isolateInstance = FlutterIsolateInstance();

  IsolateTileWriter._();

  static Future<IsolateTileWriter> create(
    bool debugFile,
    Map<int, PoiholderCollection> poiholderCollection,
    Map<int, WayholderCollection> wayholderCollection,
    ZoomlevelRange zoomlevelRange,
    double maxDeviationPixel,
    int tileCountX,
  ) async {
    _TileWriterInstanceRequest request = _TileWriterInstanceRequest(
      debugFile: debugFile,
      poiholderCollection: poiholderCollection,
      wayholderCollection: wayholderCollection,
      zoomlevelRange: zoomlevelRange,
      maxDeviationPixel: maxDeviationPixel,
      tileCountX: tileCountX,
    );
    IsolateTileWriter instance = IsolateTileWriter._();
    await instance._isolateInstance.spawn(createInstance, request);
    return instance;
  }

  void dispose() {
    _isolateInstance.dispose();
  }

  Future<Uint8List> writeTile(Tile tile) async {
    return await _isolateInstance.compute(tile);
  }

  /// This is the instance variable. Note that it is a different instance in each isolate.
  static TileWriter? _tileWriter;

  @pragma('vm:entry-point')
  static Future<void> createInstance(IsolateInitInstanceParams object) async {
    await FlutterIsolateInstance.isolateInit(object, writeTileStatic);
    _TileWriterInstanceRequest request = object.initObject;
    _tileWriter ??= TileWriter(
      request.debugFile,
      request.poiholderCollection,
      request.wayholderCollection,
      request.zoomlevelRange,
      request.maxDeviationPixel,
      request.tileCountX,
    );
    // init displaymodel since it is used for PixelProjection in WaySimplifyFilter in WayCropper
    //DisplayModel();
  }

  @pragma('vm:entry-point')
  static Future<Uint8List> writeTileStatic(Tile tile) async {
    return _tileWriter!.writeTile(tile);
  }
}

//////////////////////////////////////////////////////////////////////////////

/// A message to initialize the TileConstructor instance in the isolate.
class _TileWriterInstanceRequest {
  final Map<int, PoiholderCollection> poiholderCollection;

  final Map<int, WayholderCollection> wayholderCollection;

  final ZoomlevelRange zoomlevelRange;

  final double maxDeviationPixel;

  final bool debugFile;

  final int tileCountX;

  _TileWriterInstanceRequest({
    required this.tileCountX,
    required this.debugFile,
    required this.poiholderCollection,
    required this.wayholderCollection,
    required this.zoomlevelRange,
    required this.maxDeviationPixel,
  });
}

//////////////////////////////////////////////////////////////////////////////

/// A message to request the construction of a single tile.
class _TileConstructorRequest {
  final Tile tile;

  _TileConstructorRequest({required this.tile});
}

//////////////////////////////////////////////////////////////////////////////

/// A class that constructs a single map tile from a given set of POIs and ways.
///
/// This involves filtering the data to include only the elements relevant to the
/// tile, cropping way geometries to the tile boundaries, and serializing the
/// final data into the binary tile format.
class TileWriter {
  final _log = Logger('TileWriter');

  /// depending on the thickest line we draw we have to extend the margin so that
  /// a surrounding area is not visible in the tile.
  /// On the other side we may include more waypoints even if they are not visible
  /// in the margin.
  final double margin = 1.15;

  final double maxDeviationPixel;

  final bool debugFile;

  final _PoiWayCollection _poiWayCollection;

  final SimpleCache<BoundingBox, _PoiWayCollection> _cache = SimpleCache(capacity: 1);

  BoundingBox _boundingBox = BoundingBox.fromLatLongs([const LatLong(0, 0)]);

  ZoomlevelRange zoomlevelRange;

  final int tileCountX;

  Tile? first;

  int lastRemove = 0;

  TileWriter(
    this.debugFile,
    Map<int, PoiholderCollection> poiholderCollection,
    Map<int, WayholderCollection> wayholderCollection,
    this.zoomlevelRange,
    this.maxDeviationPixel,
    this.tileCountX,
  ) : _poiWayCollection = _PoiWayCollection(poiholderCollection, wayholderCollection);

  _PoiWayCollection _prefilter(Tile tile, BoundingBox tileBoundingBox) {
    // before we start prefiltering remove items which are not needed anymore. Do it in the save area of the cache to prevent concurrent execution.
    _removeOld(tile);
    Map<int, PoiholderCollection> resultPoi = {};
    _poiWayCollection.poiinfos.forEach((zoomlevel, poiinfo) {
      PoiholderCollection newPoiinfo = PoiholderCollection();
      for (Poiholder poiholder in poiinfo.poiholders) {
        if (tileBoundingBox.containsLatLong(poiholder.poi.position)) {
          newPoiinfo.addPoiholder(poiholder);
        }
      }
      resultPoi[zoomlevel] = newPoiinfo;
    });

    Map<int, WayholderCollection> resultWay = {};
    _poiWayCollection.wayinfos.forEach((zoomlevel, wayinfo) {
      WayholderCollection newWayinfo = WayholderCollection();
      for (Wayholder wayholder in wayinfo.wayholders) {
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
      }
      resultWay[zoomlevel] = newWayinfo;
    });
    _boundingBox = tileBoundingBox;
    _PoiWayCollection poiWayInfos = _PoiWayCollection(resultPoi, resultWay);
    return poiWayInfos;
  }

  _PoiWayCollection _filterPrefiltered(_PoiWayCollection poiWayCollection, Tile tile) {
    Map<int, PoiholderCollection> resultPoi = {};
    poiWayCollection.poiinfos.forEach((zoomlevel, poiinfo) {
      PoiholderCollection newPoiinfo = PoiholderCollection();
      for (Poiholder poiholder in poiinfo.poiholders) {
        if (tile.getBoundingBox().containsLatLong(poiholder.poi.position)) {
          newPoiinfo.addPoiholder(poiholder);
        }
      }
      resultPoi[zoomlevel] = newPoiinfo;
    });
    Map<int, WayholderCollection> resultWay = {};
    WayCropper wayCropper = WayCropper(maxDeviationPixel: maxDeviationPixel);
    BoundingBox boundingBox = tile.getBoundingBox().extendMargin(margin);
    poiWayCollection.wayinfos.forEach((zoomlevel, wayinfo) {
      WayholderCollection newWayinfo = WayholderCollection();
      for (Wayholder wayholder in wayinfo.wayholders) {
        BoundingBox wayBoundingBox = wayholder.boundingBoxCached;
        if (tile.getBoundingBox().intersects(wayBoundingBox) ||
            tile.getBoundingBox().containsBoundingBox(wayBoundingBox) ||
            wayBoundingBox.containsBoundingBox(tile.getBoundingBox())) {
          Wayholder? wayCropped = wayCropper.cropWay(wayholder, boundingBox, zoomlevelRange.zoomlevelMax);
          if (wayCropped != null) newWayinfo.addWayholder(wayCropped);
        }
      }
      resultWay[zoomlevel] = newWayinfo;
    });
    return _PoiWayCollection(resultPoi, resultWay);
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
    var session = PerformanceProfiler().startSession(category: "TileConstructor.removeOld");
    BoundingBox boundingBox = newTile.getBoundingBox().extendBoundingBox(first!.getBoundingBox());
    int poicountBefore = _poiWayCollection.poiinfos.values.fold(0, (idx, combine) => idx + combine.poiholders.length);
    _poiWayCollection.poiinfos.forEach((zoomlevel, poiinfo) {
      for (Poiholder poiholder in List.from(poiinfo.poiholders)) {
        if (boundingBox.containsLatLong(poiholder.poi.position)) {
          poiinfo.poiholders.remove(poiholder);
        }
      }
    });
    int poicountAfter = _poiWayCollection.poiinfos.values.fold(0, (idx, combine) => idx + combine.poiholders.length);
    session.checkpoint("$poicountBefore -> $poicountAfter");
    int waycountBefore = _poiWayCollection.wayinfos.values.fold(0, (idx, combine) => idx + combine.wayholders.length);
    _poiWayCollection.wayinfos.forEach((zoomlevel, wayinfo) {
      for (Wayholder wayholder in List.from(wayinfo.wayholders)) {
        BoundingBox wayBoundingBox = wayholder.boundingBoxCached;
        if (boundingBox.containsBoundingBox(wayBoundingBox)) {
          wayinfo.wayholders.remove(wayholder);
        }
      }
    });
    int waycountAfter = _poiWayCollection.wayinfos.values.fold(0, (idx, combine) => idx + combine.wayholders.length);
    session.complete();
    lastRemove = DateTime.now().millisecondsSinceEpoch;
  }

  Future<_PoiWayCollection> _filterForTile(Tile tile) async {
    if (_boundingBox.containsBoundingBox(tile.getBoundingBox())) {
      _PoiWayCollection poiWayInfos = await _cache.getOrProduce(_boundingBox, (v) async => _prefilter(tile, _boundingBox));
      return _filterPrefiltered(poiWayInfos, tile);
    } else {
      Tile tile2 = Tile(Math.min(tile.tileX + tileCountX, Tile.getMaxTileNumber(tile.zoomLevel)), tile.tileY, tile.zoomLevel, tile.indoorLevel);
      BoundingBox tileBoundingBox = tile.getBoundingBox().extendBoundingBox(tile2.getBoundingBox());
      _PoiWayCollection poiWayInfos = await _cache.getOrProduce(tileBoundingBox, (v) async => _prefilter(tile, tileBoundingBox));
      return _filterPrefiltered(poiWayInfos, tile);
    }
  }

  /// Processes the block signature, if present.
  ///
  /// @return true if the block signature could be processed successfully, false otherwise.
  void _writeTileHeaderSignature(Tile tile, Writebuffer writebuffer) {
    if (debugFile) {
      writebuffer.appendStringWithoutLength("###TileStart${tile.tileX},${tile.tileY}###".padRight(Mapfile.SIGNATURE_LENGTH_BLOCK, " "));
    }
  }

  void _writeZoomtable(Tile tile, Writebuffer writebuffer, Map<int, PoiholderCollection> poisPerZoomlevel, Map<int, WayholderCollection> waysPerZoomlevel) {
    for (int queryZoomLevel = zoomlevelRange.zoomlevelMin; queryZoomLevel <= zoomlevelRange.zoomlevelMax; queryZoomLevel++) {
      PoiholderCollection poiinfo = poisPerZoomlevel[queryZoomLevel]!;
      WayholderCollection wayinfo = waysPerZoomlevel[queryZoomLevel]!;
      int poiCount = poiinfo.count;
      int wayCount = wayinfo.wayCount;
      writebuffer.appendUnsignedInt(poiCount);
      writebuffer.appendUnsignedInt(wayCount);
    }
  }

  /// Constructs and writes a single [tile] to a byte array.
  ///
  /// This is the main entry point for the class. It filters the available POIs
  /// and ways for the given tile, processes them, and serializes them into a
  /// [Uint8List] representing the binary tile data.
  Future<Uint8List> writeTile(Tile tile) async {
    first ??= tile;
    Writebuffer writebuffer = Writebuffer();
    _PoiWayCollection poiWayInfos = await _filterForTile(tile);
    _writeTileHeaderSignature(tile, writebuffer);

    _writeZoomtable(tile, writebuffer, poiWayInfos.poiinfos, poiWayInfos.wayinfos);

    MercatorProjection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
    double tileLatitude = projection.tileYToLatitude(tile.tileY);
    double tileLongitude = projection.tileXToLongitude(tile.tileX);

    // the offset to the first way in the block
    int firstWayOffset = 0;
    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      PoiholderCollection poiholderCollection = poiWayInfos.poiinfos[zoomlevel]!;
      poiholderCollection.writePoidata(debugFile, tileLatitude, tileLongitude);
      firstWayOffset += poiholderCollection.content!.length;
    }
    writebuffer.appendUnsignedInt(firstWayOffset);
    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      PoiholderCollection poiholderCollection = poiWayInfos.poiinfos[zoomlevel]!;
      writebuffer.appendUint8(poiholderCollection.content!);
      poiholderCollection.content = null;
      poiholderCollection.poiholders.clear();
    }
    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      WayholderCollection wayholderCollection = poiWayInfos.wayinfos[zoomlevel]!;
      wayholderCollection.writeWaydata(debugFile, tile, tileLatitude, tileLongitude);
      writebuffer.appendUint8(wayholderCollection.content!);
      wayholderCollection.content = null;
    }
    return writebuffer.getUint8List();
  }
}

//////////////////////////////////////////////////////////////////////////////

class _PoiWayCollection {
  Map<int, PoiholderCollection> poiinfos = {};

  Map<int, WayholderCollection> wayinfos = {};

  _PoiWayCollection(this.poiinfos, this.wayinfos);
}
