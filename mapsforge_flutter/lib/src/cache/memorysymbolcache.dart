import 'dart:typed_data';

import 'package:ecache/ecache.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/exceptions/symbolnotfoundexception.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/flutterresourcebitmap.dart';
import 'dart:ui' as ui;

class MemorySymbolCache extends SymbolCache {
  static final String PREFIX_JAR = "jar:";

  static final String PREFIX_JAR_V1 =
      "jar:/org/mapsforge/android/maps/rendertheme";

  final AssetBundle? bundle;

  LruCache<String, ResourceBitmap> _cache =
      new LruCache<String, ResourceBitmap>(
    storage: StatisticsStorage<String, ResourceBitmap>(onEvict: (key, item) {
      item.dispose();
    }),
    capacity: 500,
  );

  MemorySymbolCache({this.bundle});

  @override
  void dispose() {
    print("Statistics for MemorySymbolCache: ${_cache.storage.toString()}");
    _cache.clear();
    super.dispose();
  }

  @override
  Future<ResourceBitmap?> getSymbol(String? src, int width, int height) async {
    if (src == null || src.length == 0) {
// no image source defined
      return null;
    }
    String key = "$src-$width-$height";
    ResourceBitmap? bitmap = _cache.get(key);
    if (bitmap != null) return bitmap;

    bitmap = await _createSymbol(src, width, height);
    //bitmap.incrementRefCount();
    _cache.set(key, bitmap);
    return bitmap;
  }

  Future<ResourceBitmap> _createSymbol(
      String src, int width, int height) async {
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
    if (bundle != null) {
      ByteData content = await bundle!.load(src);
      return content;
    }
    return null;
  }

  Future<FlutterResourceBitmap> _createPngSymbol(
      String src, int width, int height) async {
    ByteData? content = await fetchResource(src);
    if (content == null) throw SymbolNotFoundException(src);
    Uint8List bytes = content.buffer.asUint8List();
    if (width != 0 && height != 0) {
      var codec = await ui.instantiateImageCodec(bytes,
          targetHeight: height, targetWidth: width);
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

      FlutterResourceBitmap result = FlutterResourceBitmap(img, src);
      return result;
    }
  }

  Future<FlutterResourceBitmap> _createSvgSymbol(
      String src, int width, int height) async {
    ByteData? content = await fetchResource(src);
    if (content == null) throw SymbolNotFoundException(src);
    DrawableRoot svgRoot =
        await svg.fromSvgBytes(content.buffer.asUint8List(), src);

// If you only want the final Picture output, just use
    final ui.Picture picture =
        svgRoot.toPicture(size: ui.Size(width.toDouble(), height.toDouble()));
    ui.Image image = await picture.toImage(width, height);
    //print("image: " + image.toString());
    FlutterResourceBitmap result = FlutterResourceBitmap(image, src);
    return result;

    //final Widget svg = new SvgPicture.asset(assetName, semanticsLabel: 'Acme Logo');

    //return graphicFactory.renderSvg(inputStream, displayModel.getScaleFactor(), width, height, percent);
  }
}
