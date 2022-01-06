import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/utils/filehelper.dart';

import 'tilebitmapcache.dart';

///
/// A file cache for the bitmaps of a [Tile]. The implementation can distinguish different sets of [Tile]s depending on the [renderkey].
/// This can be used to cache for example tiles used by day as well as tiles used by night.
///
class FileTileBitmapCache extends TileBitmapCache {
  static final _log = new Logger('FileTileBitmapCache');

  ///
  /// a unique key for the rendered bitmaps. The key should be dependent of the renderingTheme. In other words if the bitmaps should be
  /// rendered differently (day/night for example or different mapfiles) there should be different rendering keys
  ///
  String renderkey;

  late Set<String> _files;

  late String _dir;

  static final Map<String, FileTileBitmapCache> _instances = Map();

  static Future<FileTileBitmapCache> create(String renderkey) async {
    FileTileBitmapCache? result = _instances[renderkey];
    if (result != null) return result;

    result = FileTileBitmapCache._(renderkey);
    _instances[renderkey] = result;
    await result._init();
    return result;
  }

  /// Purges all cached files from all caches regardless if the cache is used or not
  static Future<void> purgeAllCaches() async {
    for (FileTileBitmapCache cache in _instances.values) {
      await cache.purgeAll();
    }
    // now purge every cache not yet active
    String rootDir = await FileHelper.getTempDirectory("mapsforgetiles");
    List<String> caches = (await FileHelper.getFiles(rootDir));
    for (String cache in caches) {
      List<String> files = (await FileHelper.getFiles(cache));
      for (String file in files) {
        await FileHelper.delete(file);
      }
      if (files.length > 0)
        _log.info("Deleted ${files.length} files from cache $cache");
    }
  }

  FileTileBitmapCache._(this.renderkey) : assert(!renderkey.contains("/"));

  Future _init() async {
    _dir = await FileHelper.getTempDirectory("mapsforgetiles/" + renderkey);
    _files = (await FileHelper.getFiles(_dir)).toSet();
    _log.info(
        "Starting cache for renderkey $renderkey with ${_files.length} items in filecache");
//    files.forEach((file) {
//      _log.info("  file in cache: $file");
//    });
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

  @override
  Future<TileBitmap?> getTileBitmapAsync(Tile tile) async {
    String filename = _calculateFilename(tile);
    if (!_files.contains(filename)) {
      // not yet initialized or not in cache
      return null;
    }
    File file = File(filename);
    try {
      Uint8List content = await file.readAsBytes();
      var codec = await instantiateImageCodec(content.buffer.asUint8List());
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      Image img = frame.image;
      TileBitmap tileBitmap =
          FlutterTileBitmap(img, "FileTileBitmapCache ${tile.toString()}");
      return tileBitmap;
    } catch (e, stacktrace) {
      _log.warning(
          "Error while reading image from file, deleting file $filename");
      _files.remove(filename);
      try {
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
    Image img = (tileBitmap as FlutterTileBitmap).bitmap;
    ByteData? content = await (img.toByteData(format: ImageByteFormat.png));
    if (content != null) {
      File file = File(filename);
      await file.writeAsBytes(content.buffer.asUint8List(),
          mode: FileMode.write);
      _files.add(filename);
    }
  }

  String _calculateFilename(Tile tile) {
    return "$_dir/${tile.zoomLevel}_${tile.indoorLevel}_${tile.tileX}_${tile.tileY}.png";
  }

  @override
  void dispose() {}

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
