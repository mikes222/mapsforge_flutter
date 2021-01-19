import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ecache/ecache.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/exceptions/symbolnotfoundexception.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/flutterresourcebitmap.dart';

///
/// A cache for symbols (small bitmaps used in the map, eg. stopsigns, arrows). The [src] parameter specifies the filename including the
/// extension starting from the assets-path. eg. "patterns/arrow.png"
///
class FileSymbolCache extends SymbolCache {
  static final String PREFIX_JAR = "jar:";

  static final String PREFIX_JAR_V1 = "jar:/org/mapsforge/android/maps/rendertheme";

  /**
   * Default size is 20x20px (400px) at baseline mdpi (160dpi).
   */
  static int DEFAULT_SIZE = 20;

  final AssetBundle bundle;

  Cache<String, ResourceBitmap> _cache = new LruCache<String, ResourceBitmap>(
    storage: SimpleStorage<String, ResourceBitmap>(onEvict: (key, item) {
      item.decrementRefCount();
    }),
    capacity: 100,
  );

  FileSymbolCache(this.bundle) : assert(bundle != null);

  @override
  void dispose() {
    _cache.clear();
  }

  @override
  Future<ResourceBitmap> getSymbol(String src, int width, int height, int percent) async {
    if (src == null || src.length == 0) {
// no image source defined
      return null;
    }
    String key = "$src-$width-$height-$percent";
    ResourceBitmap bitmap = _cache.get(key);
    if (bitmap != null) return bitmap;

    bitmap = await _createSymbol(src, width, height, percent);
    if (bitmap != null) {
      bitmap.incrementRefCount();
      _cache.set(key, bitmap);
    }
    return bitmap;
  }

  Future<ResourceBitmap> _createSymbol(String src, int width, int height, int percent) async {
    // compatibility with mapsforge
    if (src.startsWith(PREFIX_JAR)) {
      src = src.substring(PREFIX_JAR.length);
      src = "packages/mapsforge_flutter/assets/" + src;
    } else if (src.startsWith(PREFIX_JAR_V1)) {
      src = src.substring(PREFIX_JAR_V1.length);
      src = "packages/mapsforge_flutter/assets/" + src;
    }

// we need to hash with the width/height included as the same symbol could be required
// in a different size and must be cached with a size-specific hash
    if (src.toLowerCase().endsWith(".svg")) {
      return _createSvgSymbol(src, width, height);
    } else if (src.toLowerCase().endsWith(".png")) {
      return _createPngSymbol(src, width, height);
    } else {
      throw Exception("Unknown resource fileformat $src");
    }
  }

  Future<ByteData> fetchResource(String src) async {
    ByteData content = await bundle.load(src);
    return content;
  }

  Future<FlutterResourceBitmap> _createPngSymbol(String src, int width, int height) async {
    ByteData content = await fetchResource(src);
    if (content == null) throw SymbolNotFoundException(src);
    if (width != 0 && height != 0) {
//        imag.Image image = imag.decodeImage(content.buffer.asUint8List());
//        image = imag.copyResize(image, width: width, height: height);

//        var codec = await ui.instantiateImageCodec(imag.encodePng(image));
      var codec = await ui.instantiateImageCodec(content.buffer.asUint8List(), targetHeight: height, targetWidth: width);
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      ui.Image img = frame.image;

      FlutterResourceBitmap result = FlutterResourceBitmap(img);
      return result;
    } else {
      var codec = await ui.instantiateImageCodec(content.buffer.asUint8List());
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      ui.Image img = frame.image;

      FlutterResourceBitmap result = FlutterResourceBitmap(img);
      return result;
    }

    //Image img = Image.memory(content.buffer.asUint8List());
    //MemoryImage image = MemoryImage(content.buffer.asUint8List());
  }

  Future<FlutterResourceBitmap> _createSvgSymbol(String src, int width, int height) async {
    ByteData content = await fetchResource(src);
    if (content == null) throw SymbolNotFoundException(src);

    final DrawableRoot svgRoot = await svg.fromSvgBytes(content.buffer.asUint8List(), src);

// If you only want the final Picture output, just use
    final ui.Picture picture = svgRoot.toPicture(
        size: ui.Size(width != 0 ? width.toDouble() : DEFAULT_SIZE.toDouble(), height != 0 ? height.toDouble() : DEFAULT_SIZE.toDouble()));
    ui.Image image = await picture.toImage(width != 0 ? width : DEFAULT_SIZE, height != 0 ? height : DEFAULT_SIZE);
    //print("image: " + image.toString());
    FlutterResourceBitmap result = FlutterResourceBitmap(image);
    return result;

    //final Widget svg = new SvgPicture.asset(assetName, semanticsLabel: 'Acme Logo');

    //return graphicFactory.renderSvg(inputStream, displayModel.getScaleFactor(), width, height, percent);
  }
}
