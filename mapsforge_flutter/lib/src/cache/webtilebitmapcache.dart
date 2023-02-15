import 'dart:convert' as cnv;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:idb_shim/idb.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/utils/filehelper.dart';
import 'package:idb_shim/idb_browser.dart';

///
/// A file cache for the bitmaps of a [Tile]. The implementation can distinguish different sets of [Tile]s depending on the [renderkey].
/// This can be used to cache for example tiles used by day as well as tiles used by night.
///
class WebTileBitmapCache extends TileBitmapCache {
  static final _log = new Logger('WebTileBitmapCache');

  ///
  /// a unique key for the rendered bitmaps. The key should be dependent of the renderingTheme. In other words if the bitmaps should be
  /// rendered differently (day/night for example or different mapfiles) there should be different rendering keys
  ///
  String renderkey;

  late Set<String> _files;

  late String _dir;

  final int tileSize;

  /// true if the images should be stored in PNG format, false for raw format which is faster but consumes more space.
  /// PNG: 470ms for 16 files, RAW: 400ms for the same 16 files
  final bool png;

  final IdbFactory? idbFactory = getIdbFactory();

  static final Map<String, WebTileBitmapCache> _instances = Map();

  final String _tocStore = "_toc1";

  late Database database;

  static Future<WebTileBitmapCache> create(String renderkey,
      [png = true, tileSize = 256]) async {
    WebTileBitmapCache? result = _instances[renderkey];
    if (result != null) {
      _log.info(
          "Reusing cache for renderkey $renderkey with ${result._files.length} items in filecache");
      return result;
    }

    result = WebTileBitmapCache(renderkey, png, tileSize);
    _instances[renderkey] = result;
    await result._init();
    return result;
  }

  /// Purges all cached files from all caches regardless if the cache is used or not
  static Future<void> purgeAllCaches() async {
    for (WebTileBitmapCache cache in _instances.values) {
      await cache.purgeAll();
    }
    _instances.clear();
    // now purge every cache not yet active
    String rootDir = await FileHelper.getTempDirectory("mapsforgetiles");
    List<String> caches = (await FileHelper.getFiles(rootDir));
    for (String cache in caches) {
      List<String> files = (await FileHelper.getFiles(cache));
      for (String file in files) {
        try {
          await FileHelper.delete(file);
        } catch (error, stacktrace) {
          // ignore this error
        }
      }
      if (files.length > 0)
        _log.info("Deleted ${files.length} files from cache $cache");
    }
  }

  WebTileBitmapCache(this.renderkey, this.png, this.tileSize)
      : assert(!renderkey.contains("/"));

  Future _init() async {
    database = await idbFactory!.open(renderkey, version: 2,
        onUpgradeNeeded: (VersionChangeEvent event) {
      final db = (event.target as OpenDBRequest).result;
      if (!db.objectStoreNames.contains(_tocStore)) {
        db.createObjectStore(_tocStore /*, keyPath: 'timeStamp'*/);
        _log.info("Create WebTileBitmapCache");
      }
    });

    Transaction transaction = database.transaction(_tocStore, 'readwrite');
    ObjectStore store = transaction.objectStore(_tocStore);

    // Get everything in the store.
    _dir = ".";
    _files = {};
    store.openCursor(autoAdvance: true).listen((cursor) {
      print("Hello ${cursor.key}");
      _files.add(cursor.key as String);
    });

    _log.info(
        "Starting cache for renderkey $renderkey with ${_files.length} items in filecache");
  }

  @override
  @override
  Future<void> purgeAll() async {
    int count = 0;
    for (String file in []..addAll(_files)) {
      //_log.info("  purging file from cache: $file");
      try {
        bool ok = await FileHelper.delete(file);
        if (ok) ++count;
      } catch (error) {
        // do nothing
      }
    }
    _log.info("purged $count files from FileTileBitmapCache $renderkey");
    _files.clear();
  }

  @override
  void addTileBitmap(Tile tile, TileBitmap tileBitmap) {
    _storeFile(tile, tileBitmap);
  }

  @override
  TileBitmap? getTileBitmapSync(Tile tile) {
    return null;
  }

  Future<Image> _readImageFromFile(String filename) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    Transaction transaction = database.transaction(_tocStore, 'readwrite');
    ObjectStore store = transaction.objectStore(_tocStore);
    Object? object = await store.getObject(filename);
    //String base64 = object as String;
    Uint8List content = object as Uint8List; //cnv.base64Decode(base64);
    //print("readed ${content.length} bytes from store");
    Codec codec;
    if (png) {
      codec = await instantiateImageCodec(content.buffer.asUint8List());
    } else {
      final ImmutableBuffer buffer =
          await ImmutableBuffer.fromUint8List(content);
      ImageDescriptor descriptor = ImageDescriptor.raw(buffer,
          width: tileSize, height: tileSize, pixelFormat: PixelFormat.rgba8888);
      buffer.dispose();
      codec = await descriptor.instantiateCodec();
    }

    // add additional checking for number of frames etc here
    FrameInfo frame = await codec.getNextFrame();
    Image image = frame.image;
    int diff = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (diff > 100) _log.info("Read image from file took $diff ms");
    return image;
  }

  @override
  Future<TileBitmap?> getTileBitmapAsync(Tile tile) async {
    String filename = _calculateFilename(tile);
    if (!_files.contains(filename)) {
      // not yet initialized or not in cache
      return null;
    }
    try {
      Image image = await _readImageFromFile(filename);
      TileBitmap tileBitmap =
          FlutterTileBitmap(image, "FileTileBitmapCache ${tile.toString()}");
      return tileBitmap;
    } catch (error, stacktrace) {
      _log.warning(
          "Error $error while reading image from file, deleting file $filename");
      _files.remove(filename);
      try {
        File file = File(filename);
        await file.delete();
      } catch (error) {
        // ignore problem, file is already deleted
      }
    }
    return null;
  }

  Future _storeFile(Tile tile, TileBitmap tileBitmap) async {
    String filename = _calculateFilename(tile);
    if (_files.contains(filename)) return;
    Image image = (tileBitmap as FlutterTileBitmap).getClonedImage();
    ByteData? content = await (image.toByteData(
        format: png ? ImageByteFormat.png : ImageByteFormat.rawRgba));
    image.dispose();
    if (content != null) {
      Transaction transaction = database.transaction(_tocStore, 'readwrite');
      ObjectStore store = transaction.objectStore(_tocStore);
      //String base64 = cnv.base64Encode(content.buffer.asUint8List());
      await store.put(content.buffer.asUint8List(), filename);
//      print("writing $filename");
      _files.add(filename);
    }
  }

  String _calculateFilename(Tile tile) {
    return "$_dir/${tile.zoomLevel}_${tile.indoorLevel}_${tile.tileX}_${tile.tileY}.${png ? "png" : "raw"}";
  }

  @override
  void dispose() {
    // the instance is still available and may be used by another map.
    //_files.clear();
  }

  @override
  Future<void> purgeByBoundary(BoundingBox boundingBox) async {
    // todo find a method to remove only affected files. For now we clear the whole cache
    int count = 0;
    for (String file in []..addAll(_files)) {
      //_log.info("  purging file from cache: $file");
      try {
        bool ok = await FileHelper.delete(file);
        if (ok) ++count;
      } catch (error, stacktrace) {
        _log.warning("purging $file was not successful, ignoring");
      }
    }
    _log.info("purged $count files from cache $renderkey");
    _files.clear();
  }
}
