import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ecache/ecache.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/exceptions/symbolnotfoundexception.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/flutterresourcebitmap.dart';
import 'package:path_provider/path_provider.dart';

///
/// A cache for symbols (small bitmaps used in the map, eg. stopsigns, arrows). The [src] parameter specifies the filename including the
/// extension starting from the assets-path. eg. "patterns/arrow.png"
///
class FileSymbolCache extends SymbolCache {
  static final _log = new Logger('FileSymbolCache');

  static final String PREFIX_JAR = "jar:";

  static final String PREFIX_JAR_V1 = "jar:/org/mapsforge/android/maps/rendertheme";

  /**
   * Default size is 20x20px (400px) at baseline mdpi (160dpi).
   */
  static int DEFAULT_SIZE = 20;

  final AssetBundle? bundle;

  final String? relativePathPrefix;

  Cache<String, ResourceBitmap> _cache = new LruCache<String, ResourceBitmap>(
    storage: SimpleStorage<String, ResourceBitmap>(onEvict: (key, item) {
      item.decrementRefCount();
    }),
    capacity: 100,
  );

  ///
  /// Creates a new FileSymbolCache. If the [relativePathPrefix] is not null the symbols will be loaded given by the [relativePathPrefix] first and if
  /// not found there the symbols will be loaded by the bundle.
  ///
  FileSymbolCache(AssetBundle this.bundle, [this.relativePathPrefix]) : assert(bundle != null);

  FileSymbolCache.withRelativePathPrefix(String this.relativePathPrefix)
      : assert(relativePathPrefix != null),
        bundle = null;

  @override
  void dispose() {
    _cache.clear();
  }

  @override
  Future<ResourceBitmap?> getSymbol(String? src, int width, int height, int? percent) async {
    if (src == null || src.length == 0) {
// no image source defined
      return null;
    }
    String key = "$src-$width-$height-$percent";
    ResourceBitmap? bitmap = _cache.get(key);
    if (bitmap != null) return bitmap;

    bitmap = await _createSymbol(src, width, height, percent);
    if (bitmap != null) {
      bitmap.incrementRefCount();
      _cache.set(key, bitmap);
    }
    return bitmap;
  }

  Future<ResourceBitmap> _createSymbol(String src, int width, int height, int? percent) async {
// we need to hash with the width/height included as the same symbol could be required
// in a different size and must be cached with a size-specific hash
    if (src.toLowerCase().endsWith(".svg")) {
      return _createSvgSymbol(src, width, height, percent);
    } else if (src.toLowerCase().endsWith(".png")) {
      return _createPngSymbol(src, width, height, percent);
    } else {
      throw Exception("Unknown resource fileformat $src");
    }
  }

  ///
  /// Returns the content of the symbol given as [src] as [ByteData]. This method reads the file or resource and returns the requested bytes.
  ///
  @protected
  Future<ByteData?> fetchResource(String src) async {
    // compatibility with mapsforge
    if (src.startsWith(PREFIX_JAR)) {
      src = src.substring(PREFIX_JAR.length);
      src = "packages/mapsforge_flutter/assets/" + src;
    } else if (src.startsWith(PREFIX_JAR_V1)) {
      src = src.substring(PREFIX_JAR_V1.length);
      src = "packages/mapsforge_flutter/assets/" + src;
    }
    if (relativePathPrefix != null) {
      Directory dir = await getApplicationDocumentsDirectory();
      src = dir.path + "/" + relativePathPrefix! + src;
      //_log.info("Trying to load symbol from $src");
      File file = File(relativePathPrefix! + src);
      if (await file.exists()) {
        Uint8List bytes = await file.readAsBytes();
        return ByteData.view(bytes.buffer);
      }
    }
    if (bundle != null) {
      ByteData content = await bundle!.load(src);
      return content;
    }
    return null;
  }

  Future<FlutterResourceBitmap> _createPngSymbol(String src, int width, int height, int? percent) async {
    ByteData? content = await fetchResource(src);
    if (content == null) throw SymbolNotFoundException(src);
    Uint8List bytes = content.buffer.asUint8List();
    if (width != 0 && height != 0) {
//        imag.Image image = imag.decodeImage(content.buffer.asUint8List());
//        image = imag.copyResize(image, width: width, height: height);

//        var codec = await ui.instantiateImageCodec(imag.encodePng(image));
      if (percent != null && percent != 100) {
        width = (width * percent.toDouble() / 100.0).round();
        height = (height * percent.toDouble() / 100.0).round();
      }
      var codec = await ui.instantiateImageCodec(bytes, targetHeight: height, targetWidth: width);
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      ui.Image img = frame.image;

      FlutterResourceBitmap result = FlutterResourceBitmap(img, src);
      return result;
    } else {
      var codec = await ui.instantiateImageCodec(bytes);
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      ui.Image img = frame.image;

      if (percent != null && percent != 100) {
        width = img.width;
        height = img.height;
        width = (width * percent.toDouble() / 100.0).round();
        height = (height * percent.toDouble() / 100.0).round();

        var codec = await ui.instantiateImageCodec(bytes, targetHeight: height, targetWidth: width);
        var frame = await codec.getNextFrame();
        img = frame.image;
      }

      FlutterResourceBitmap result = FlutterResourceBitmap(img, src);
      return result;
    }

    //Image img = Image.memory(content.buffer.asUint8List());
    //MemoryImage image = MemoryImage(content.buffer.asUint8List());
  }

  Future<FlutterResourceBitmap> _createSvgSymbol(String src, int width, int height, int? percent) async {
    ByteData? content = await fetchResource(src);
    if (content == null) throw SymbolNotFoundException(src);
    DrawableRoot svgRoot = await svg.fromSvgBytes(content.buffer.asUint8List(), src);

    if (percent != null && percent != 100) {
      if (width != null) width = (width * percent.toDouble() / 100.0).round();
      if (height != null) height = (height * percent.toDouble() / 100.0).round();
    }
// If you only want the final Picture output, just use
    final ui.Picture picture = svgRoot.toPicture(
        size: ui.Size(width != 0 ? width.toDouble() : DEFAULT_SIZE.toDouble(), height != 0 ? height.toDouble() : DEFAULT_SIZE.toDouble()));
    ui.Image image = await picture.toImage(width != 0 ? width : DEFAULT_SIZE, height != 0 ? height : DEFAULT_SIZE);
    //print("image: " + image.toString());
    FlutterResourceBitmap result = FlutterResourceBitmap(image, src);
    return result;

    //final Widget svg = new SvgPicture.asset(assetName, semanticsLabel: 'Acme Logo');

    //return graphicFactory.renderSvg(inputStream, displayModel.getScaleFactor(), width, height, percent);
  }
}
