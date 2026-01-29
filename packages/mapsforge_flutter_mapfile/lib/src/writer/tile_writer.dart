import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter_core/dart_isolate.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_mapfile/filter.dart';
import 'package:mapsforge_flutter_mapfile/mapfile_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/poiholder_writer.dart';
import 'package:mapsforge_flutter_mapfile/src/writer/wayholder_writer.dart';

abstract class ITileWriter {
  Future<Uint8List> writeTile(Tile tile);

  void dispose();
}

//////////////////////////////////////////////////////////////////////////////

/// An isolate-based wrapper for [TileWriter] to perform tile construction
/// in the background.
///
/// This is essential for performance, as it offloads the CPU-intensive work of
/// filtering, cropping, and serializing tile data from the main UI thread.
@pragma("vm:entry-point")
class IsolateTileWriter implements ITileWriter {
  late final FlutterIsolateInstance _isolateInstance = FlutterIsolateInstance();

  IsolateTileWriter._();

  static Future<IsolateTileWriter> create(
    bool debugFile,
    PoiWayCollections poiWayCollections,
    ZoomlevelRange zoomlevelRange,
    List<String> languagesPreferences,
    TagholderModel model,
  ) async {
    await poiWayCollections.freeRessources();
    _TileWriterInstanceRequest request = _TileWriterInstanceRequest(
      debugFile: debugFile,
      poiWayCollections: poiWayCollections,
      zoomlevelRange: zoomlevelRange,
      languagesPreferences: languagesPreferences,
      model: model,
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
    return _isolateInstance.compute(tile);
  }

  /// This is the instance variable. Note that it is a different instance in each isolate.
  static TileWriter? _tileWriter;

  @pragma('vm:entry-point')
  static Future<void> createInstance(IsolateInitInstanceParams object) async {
    await FlutterIsolateInstance.isolateInit(object, writeTileStatic);
    _TileWriterInstanceRequest request = object.initObject;
    _tileWriter ??= TileWriter(request.debugFile, request.poiWayCollections, request.zoomlevelRange, request.languagesPreferences, request.model);
    // init displaymodel since it is used for PixelProjection in WaySimplifyFilter in WayCropper
    //DisplayModel();
  }

  @pragma('vm:entry-point')
  static Future<Uint8List> writeTileStatic(Tile tile) async {
    Uint8List result = await _tileWriter!.writeTile(tile);
    //await _tileWriter!.poiWayCollections.freeRessources();
    return result;
  }
}

//////////////////////////////////////////////////////////////////////////////

/// A message to initialize the TileConstructor instance in the isolate.
class _TileWriterInstanceRequest {
  final PoiWayCollections poiWayCollections;

  final ZoomlevelRange zoomlevelRange;

  final bool debugFile;

  final List<String> languagesPreferences;

  final TagholderModel model;

  _TileWriterInstanceRequest({
    required this.debugFile,
    required this.poiWayCollections,
    required this.zoomlevelRange,
    required this.languagesPreferences,
    required this.model,
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
class TileWriter implements ITileWriter {
  static final _log = Logger('TileWriter');

  /// depending on the thickest line we draw we have to extend the margin so that
  /// a surrounding area is not visible in the tile.
  /// On the other side we may include more waypoints even if they are not visible
  /// in the margin.
  final double margin = 1.15;

  final bool debugFile;

  final PoiWayCollections poiWayCollections;

  ZoomlevelRange zoomlevelRange;

  final List<String> languagesPreferences;

  final TagholderModel model;

  late final WaySimplifyFilter waySimplifyFilter;

  TileWriter(this.debugFile, this.poiWayCollections, this.zoomlevelRange, this.languagesPreferences, this.model) {
    waySimplifyFilter = WaySimplifyFilter(zoomlevelRange.zoomlevelMax, 10);
  }

  @override
  void dispose() {}

  Future<PoiWayCollections> _filterForTile(Tile tile) async {
    PoiWayCollections poiWayInfos = PoiWayCollections();
    final tileBoundingBox = tile.getBoundingBox();
    for (var entry in poiWayCollections.poiholderCollections.entries) {
      int zoomlevel = entry.key;
      IPoiholderCollection poiholderCollection = entry.value;
      IPoiholderCollection newPoiholderCollection = HolderCollectionFactory().createPoiholderCollection("tile_$zoomlevel");
      await poiholderCollection.forEach((poiholder) {
        if (tileBoundingBox.containsLatLong(poiholder.position)) {
          newPoiholderCollection.add(poiholder);
        }
      });
      poiWayInfos.poiholderCollections[zoomlevel] = newPoiholderCollection;
    }
    WayCropper wayCropper = const WayCropper();
    BoundingBox boundingBox = tileBoundingBox.extendMargin(margin);
    for (var entry in poiWayCollections.wayholderCollections.entries) {
      int zoomlevel = entry.key;
      IWayholderCollection wayholderCollection = entry.value;
      IWayholderCollection newWayholderCollection = HolderCollectionFactory().createWayholderCollection("tile_$zoomlevel");
      await wayholderCollection.forEach((wayholder) {
        BoundingBox wayBoundingBox = wayholder.boundingBoxCached;
        if (tileBoundingBox.intersects(wayBoundingBox)) {
          Wayholder? wayCropped = wayCropper.cropWay(wayholder, boundingBox, zoomlevelRange.zoomlevelMax);
          if (wayCropped != null) newWayholderCollection.add(wayCropped);
        }
      });
      poiWayInfos.wayholderCollections[zoomlevel] = newWayholderCollection;
    }
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

  void _writeZoomtable(Tile tile, Writebuffer writebuffer, Map<int, IPoiholderCollection> poisPerZoomlevel, Map<int, IWayholderCollection> waysPerZoomlevel) {
    for (int queryZoomLevel = zoomlevelRange.zoomlevelMin; queryZoomLevel <= zoomlevelRange.zoomlevelMax; queryZoomLevel++) {
      IPoiholderCollection poiholderCollection = poisPerZoomlevel[queryZoomLevel]!;
      IWayholderCollection wayinfo = waysPerZoomlevel[queryZoomLevel]!;
      int poiCount = poiholderCollection.length;
      int wayCount = wayinfo.length;
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
    Writebuffer writebuffer = Writebuffer();
    PoiWayCollections poiWayInfos = await _filterForTile(tile);
    _writeTileHeaderSignature(tile, writebuffer);

    _writeZoomtable(tile, writebuffer, poiWayInfos.poiholderCollections, poiWayInfos.wayholderCollections);

    MercatorProjection projection = MercatorProjection.fromZoomlevel(tile.zoomLevel);
    double tileLatitude = projection.tileYToLatitude(tile.tileY);
    double tileLongitude = projection.tileXToLongitude(tile.tileX);

    Writebuffer poiWriteBuffer = Writebuffer();
    PoiholderWriter poiholderWriter = PoiholderWriter();
    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      IPoiholderCollection poiholderCollection = poiWayInfos.poiholderCollections[zoomlevel]!;
      await poiholderCollection.forEach((poiholder) {
        poiholderWriter.writePoidata(poiWriteBuffer, poiholder, debugFile, tileLatitude, tileLongitude, languagesPreferences, model);
      });
    }
    // the offset to the first way in the block
    writebuffer.appendUnsignedInt(poiWriteBuffer.length);
    writebuffer.appendWritebuffer(poiWriteBuffer);
    WayholderWriter wayholderWriter = WayholderWriter();
    for (int zoomlevel = zoomlevelRange.zoomlevelMin; zoomlevel <= zoomlevelRange.zoomlevelMax; ++zoomlevel) {
      IWayholderCollection wayholderCollection = poiWayInfos.wayholderCollections[zoomlevel]!;
      await wayholderCollection.forEach((wayholder) {
        wayholder = waySimplifyFilter.ensureMax(wayholder);
        wayholderWriter.writeWaydata(writebuffer, wayholder, debugFile, tile, tileLatitude, tileLongitude, languagesPreferences, model);
      });
    }
    return writebuffer.getUint8ListAndClear();
  }
}
