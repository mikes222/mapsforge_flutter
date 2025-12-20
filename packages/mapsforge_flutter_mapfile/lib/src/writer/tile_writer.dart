import 'dart:typed_data';

import 'package:ecache/ecache.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/dart_isolate.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/filter/way_cropper.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder_collection.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/wayholder_collection.dart';

abstract class ITileWriter {
  Future<Uint8List> writeTile(Tile tile);

  void dispose();
}

/// An isolate-based wrapper for [TileWriter] to perform tile construction
/// in the background.
///
/// This is essential for performance, as it offloads the CPU-intensive work of
/// filtering, cropping, and serializing tile data from the main UI thread.
@pragma("vm:entry-point")
class IsolateTileWriter implements ITileWriter {
  late final FlutterIsolateInstance _isolateInstance = FlutterIsolateInstance();

  IsolateTileWriter._();

  static Future<IsolateTileWriter> create(bool debugFile, PoiWayCollections poiWayCollections, ZoomlevelRange zoomlevelRange, double maxDeviationPixel) async {
    _TileWriterInstanceRequest request = _TileWriterInstanceRequest(
      debugFile: debugFile,
      poiWayCollections: poiWayCollections,
      zoomlevelRange: zoomlevelRange,
      maxDeviationPixel: maxDeviationPixel,
    );
    IsolateTileWriter instance = IsolateTileWriter._();
    await instance._isolateInstance.spawn(createInstance, request);
    return instance;
  }

  @override
  void dispose() {
    _isolateInstance.dispose();
  }

  @override
  Future<Uint8List> writeTile(Tile tile) async {
    return await _isolateInstance.compute(tile);
  }

  /// This is the instance variable. Note that it is a different instance in each isolate.
  static TileWriter? _tileWriter;

  @pragma('vm:entry-point')
  static Future<void> createInstance(IsolateInitInstanceParams object) async {
    await FlutterIsolateInstance.isolateInit(object, writeTileStatic);
    _TileWriterInstanceRequest request = object.initObject;
    _tileWriter ??= TileWriter(request.debugFile, request.poiWayCollections, request.zoomlevelRange, request.maxDeviationPixel);
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
  final PoiWayCollections poiWayCollections;

  final ZoomlevelRange zoomlevelRange;

  final double maxDeviationPixel;

  final bool debugFile;

  _TileWriterInstanceRequest({required this.debugFile, required this.poiWayCollections, required this.zoomlevelRange, required this.maxDeviationPixel});
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
class TileWriter implements ITileWriter {
  final _log = Logger('TileWriter');

  /// depending on the thickest line we draw we have to extend the margin so that
  /// a surrounding area is not visible in the tile.
  /// On the other side we may include more waypoints even if they are not visible
  /// in the margin.
  final double margin = 1.15;

  final double maxDeviationPixel;

  final bool debugFile;

  final PoiWayCollections poiWayCollections;

  final SimpleCache<BoundingBox, PoiWayCollections> _cache = SimpleCache(capacity: 1);

  ZoomlevelRange zoomlevelRange;

  Tile? first;

  int lastRemove = 0;

  TileWriter(this.debugFile, this.poiWayCollections, this.zoomlevelRange, this.maxDeviationPixel);

  @override
  void dispose() {
    _cache.clear();
    first = null;
  }

  Future<PoiWayCollections> _filterForTile(Tile tile) async {
    PoiWayCollections poiWayInfos = PoiWayCollections();
    poiWayCollections.poiholderCollections.forEach((zoomlevel, poiinfo) {
      PoiholderCollection newPoiinfo = PoiholderCollection();
      for (Poiholder poiholder in poiinfo.poiholders) {
        if (tile.getBoundingBox().containsLatLong(poiholder.poi.position)) {
          newPoiinfo.addPoiholder(poiholder);
        }
      }
      poiWayInfos.poiholderCollections[zoomlevel] = newPoiinfo;
    });
    WayCropper wayCropper = WayCropper(maxDeviationPixel: maxDeviationPixel);
    BoundingBox boundingBox = tile.getBoundingBox().extendMargin(margin);
    poiWayCollections.wayholderCollections.forEach((zoomlevel, wayinfo) {
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
      poiWayInfos.wayholderCollections[zoomlevel] = newWayinfo;
    });
    return poiWayInfos;
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
  @override
  Future<Uint8List> writeTile(Tile tile) async {
    assert(poiWayCollections.poiholderCollections.isNotEmpty, "poiWayCollections.poiholderCollections.isEmpty");
    assert(poiWayCollections.wayholderCollections.isNotEmpty, "poiWayCollections.wayholderCollections.isEmpty");
    //_removeOld(tile)
    first ??= tile;
    Writebuffer writebuffer = Writebuffer();
    PoiWayCollections poiWayInfos = await _filterForTile(tile);
    _writeTileHeaderSignature(tile, writebuffer);

    _writeZoomtable(tile, writebuffer, poiWayInfos.poiholderCollections, poiWayInfos.wayholderCollections);

    MercatorProjection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
    double tileLatitude = projection.tileYToLatitude(tile.tileY);
    double tileLongitude = projection.tileXToLongitude(tile.tileX);

    // the offset to the first way in the block
    int firstWayOffset = 0;
    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      PoiholderCollection poiholderCollection = poiWayInfos.poiholderCollections[zoomlevel]!;
      poiholderCollection.writePoidata(debugFile, tileLatitude, tileLongitude);
      firstWayOffset += poiholderCollection.content!.length;
    }
    writebuffer.appendUnsignedInt(firstWayOffset);
    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      PoiholderCollection poiholderCollection = poiWayInfos.poiholderCollections[zoomlevel]!;
      writebuffer.appendUint8(poiholderCollection.content!);
      poiholderCollection.content = null;
    }
    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      WayholderCollection wayholderCollection = poiWayInfos.wayholderCollections[zoomlevel]!;
      wayholderCollection.writeWaydata(debugFile, tile, tileLatitude, tileLongitude);
      writebuffer.appendUint8(wayholderCollection.content!);
      wayholderCollection.content = null;
    }
    return writebuffer.getUint8ListAndClear();
  }
}
