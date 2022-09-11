import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';

class BitmapMixin {
  static final _log = new Logger('BitmapMixin');

  String? bitmapSrc;

  ResourceBitmap? bitmap;

  bool bitmapInvalid = false;

  double bitmapHeight = 0;

  double bitmapWidth = 0;

  int bitmapPercent = 100;

  MapPaint? bitmapPaint;

  /// Sets a new bitmap and destroys the old one if available
  Future<void> setBitmapSrc(String? bitmapSrc, SymbolCache? symbolCache) async {
    if (this.bitmap != null) {
      //this.bitmap!.decrementRefCount();
      bitmap = null;
    }
    bitmapInvalid = false;
    this.bitmapSrc = bitmapSrc;
    await initBitmap(symbolCache);
  }

  @mustCallSuper
  void dispose() {
    if (this.bitmap != null) {
      bitmap!.dispose();
      bitmap = null;
    }
    bitmapPaint = null;
  }

  @mustCallSuper
  Future<void> initBitmap(SymbolCache? symbolCache) async {
    //print("initResources called for $src");
    if (bitmapInvalid) return;

    if (bitmap != null) return;

    if (bitmapSrc == null || bitmapSrc!.isEmpty) {
      return;
    }

    if (symbolCache == null) {
      _log.warning("SymbolCache for bitmapMixin $bitmapSrc not defined");
      return;
    }
    try {
      //_log.info("$bitmapWidth - $bitmapHeight --> $bitmapPercent");
      bitmap = await symbolCache.getOrCreateSymbol(
          bitmapSrc!, bitmapWidth.round(), bitmapHeight.round());
      if (bitmap == null ||
          bitmap!.getWidth() == 0 ||
          bitmap!.getHeight() == 0) {
        _log.warning(
            "bitmap $bitmapSrc not found or no width/height, ignoring");
        bitmap = null;
        bitmapInvalid = true;
        return;
      }
      //bitmap!.incrementRefCount();
      if (bitmapPaint == null) {
        bitmapPaint = GraphicFactory().createPaint();
        bitmapPaint!.setColorFromNumber(0xff000000);
      }
    } catch (e) {
      _log.warning("${e.toString()}, ignore missing bitmap in rendering");
      //print("Exception $e\nStacktrace $stacktrace");
      bitmap = null;
      bitmapInvalid = true;
    }
  }
}
