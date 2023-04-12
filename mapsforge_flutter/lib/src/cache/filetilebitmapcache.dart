import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/implementation/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/utils/filehelper.dart';

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

  final Set<String> _files = {};

  late String _dir;

  final int tileSize;

  /// true if the images should be stored in PNG format, false for raw format which is faster but consumes more space.
  /// PNG: 470ms for 16 files, RAW: 400ms for the same 16 files
  final bool png;

  static final Map<String, FileTileBitmapCache> _instances = Map();

  static Future<FileTileBitmapCache> create(String renderkey,
      [png = true, tileSize = 256]) async {
    FileTileBitmapCache? result = _instances[renderkey];
    if (result != null) {
      _log.info(
          "Reusing cache for renderkey $renderkey with ${result._files.length} items in filecache");
      return result;
    }

    result = FileTileBitmapCache(renderkey, png, tileSize);
    // init before adding to the instances, otherwise purgeAll may find an uninitialized entry
    await result._init();
    _instances[renderkey] = result;
    return result;
  }

  /// Purges all cached files from all caches regardless if the cache is used or not
  static Future<void> purgeAllCaches() async {
    for (FileTileBitmapCache cache in List.from(_instances.values)) {
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

  FileTileBitmapCache(this.renderkey, this.png, this.tileSize)
      : assert(!renderkey.contains("/"));

  Future _init() async {
    _dir = await FileHelper.getTempDirectory("mapsforgetiles/" + renderkey);
    _files.addAll((await FileHelper.getFiles(_dir)).toSet());
    _log.info(
        "Starting cache for renderkey $renderkey with ${_files.length} items in filecache");
    // int timestamp = DateTime.now().millisecondsSinceEpoch;
    // for (String filename in _files) {
    //   _log.info("  file in cache: $filename");
    //   await _readImageFromFile(filename);
    // }
    // _log.info(
    //     "Reading ${_files.length} from filesystem took ${DateTime.now().millisecondsSinceEpoch - timestamp} ms");
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
    File file = File(filename);
    Uint8List content = await file.readAsBytes();
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
    File file = File(filename);
    try {
      Image image = await _readImageFromFile(filename);
      TileBitmap tileBitmap =
          FlutterTileBitmap(image, "FileTileBitmapCache ${tile.toString()}");
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
    Image image = (tileBitmap as FlutterTileBitmap).getClonedImage();
    ByteData? content = await (image.toByteData(
        format: png ? ImageByteFormat.png : ImageByteFormat.rawRgba));
    image.dispose();
    if (content != null) {
      File file = File(filename);
      await file.writeAsBytes(content.buffer.asUint8List(),
          mode: FileMode.write);
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
