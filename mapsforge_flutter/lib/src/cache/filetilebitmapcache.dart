import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/model/boundingbox.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';
import 'package:mapsforge_flutter/src/utils/filehelper.dart';

import 'memorytilebitmapcache.dart';
import 'tilebitmapcache.dart';

class FileTileBitmapCache extends TileBitmapCache {
  static final _log = new Logger('FileTileBitmapCache');

  final MemoryTileBitmapCache _memoryBitmapCache;

  ///
  /// a unique key for the rendered bitmaps. The key should be dependent of the renderingTheme. In other words if the bitmaps should be
  /// rendered differently (day/night for example or different mapfiles) there should be different rendering keys
  ///
  String renderkey;

  List<String> _files;

  String _dir;

  FileTileBitmapCache(this.renderkey) : _memoryBitmapCache = MemoryTileBitmapCache() {
    _init();
  }

  Future _init() async {
    assert(renderkey != null && !renderkey.contains("/"));
    _dir = await FileHelper.getTempDirectory("mapsforgetiles/" + renderkey);
    _files = await FileHelper.getFiles(_dir);
    _log.info("Starting cache for renderkey $renderkey with ${_files.length} items in filecache");
//    files.forEach((file) {
//      _log.info("  file in cache: $file");
//    });
  }

  void purgeAll() async {
    if (_files == null) return;
    int count = 0;
    await _files.forEach((file) async {
      _log.info("  purging file from cache: $file");
      bool ok = await FileHelper.delete(file);
      if (ok) ++count;
    });
    _log.info("purged $count files from cache $renderkey");
    _files.clear();
    _memoryBitmapCache.purgeAll();
  }

  @override
  void addTileBitmap(Tile tile, TileBitmap tileBitmap) {
    _memoryBitmapCache.addTileBitmap(tile, tileBitmap);
    _storeFile(tile, tileBitmap);
  }

//  @override
//  TileBitmap getTileBitmap(Tile tile) {
//    TileBitmap tileBitmap = _memoryBitmapCache.getTileBitmap(tile);
//    return tileBitmap;
//  }

  @override
  TileBitmap getTileBitmapSync(Tile tile) {
    return _memoryBitmapCache.getTileBitmapSync(tile);
  }

  @override
  Future<TileBitmap> getTileBitmapAsync(Tile tile) async {
    TileBitmap tileBitmap = _memoryBitmapCache.getTileBitmap(tile);
    if (tileBitmap != null) return tileBitmap;

    String filename = _calculateFilename(tile);
    if (_files == null || !_files.contains(filename)) {
      // not yet initialized or not in cache
      return null;
    }
    File file = File(filename);
    Uint8List content = await file.readAsBytes();
    try {
      var codec = await instantiateImageCodec(content.buffer.asUint8List());
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      Image img = frame.image;
      tileBitmap = FlutterTileBitmap(img);
      _memoryBitmapCache.addTileBitmap(tile, tileBitmap);
      return tileBitmap;
    } catch (e, stacktrace) {
      _log.warning("Error while reading image from file, deleting file $filename");
      await file.delete();
    }
    return null;
  }

  Future _storeFile(Tile tile, TileBitmap tileBitmap) async {
    String filename = _calculateFilename(tile);
    if (_files == null) {
      // not yet initialized
      return;
    }
    if (_files.contains(filename)) return;
    Image img = (tileBitmap as FlutterTileBitmap).bitmap;
    ByteData content = await img.toByteData(format: ImageByteFormat.png);
    File file = File(filename);
    file.writeAsBytes(content.buffer.asUint8List(), mode: FileMode.write);
    _files.add(filename);
  }

  String _calculateFilename(Tile tile) {
    return "$_dir/${tile.zoomLevel}_${tile.tileX}_${tile.tileY}.png";
  }

  @override
  void dispose() {
    _memoryBitmapCache.dispose();
  }

  @override
  Future<void> purgeByBoundary(BoundingBox boundingBox) async {
    // todo find a method to remove only affected files. For now we clear the whole cache
    if (_files == null) return;
    int count = 0;
    await _files.forEach((file) async {
      _log.info("  purging file from cache: $file");
      bool ok = await FileHelper.delete(file);
      if (ok) ++count;
    });
    _log.info("purged $count files from cache $renderkey");
    _files.clear();

    _memoryBitmapCache.purgeByBoundary(boundingBox);
  }
}
