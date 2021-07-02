import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';

class BitmapMixin {
  static final _log = new Logger('BitmapMixin');

  SymbolCache? symbolCache;

  String? bitmapSrc;

  Bitmap? bitmap;

  bool bitmapInvalid = false;

  double bitmapHeight = 0;

  double bitmapWidth = 0;

  int bitmapPercent = 100;

  MapPaint? bitmapPaint;

  @mustCallSuper
  void dispose() {
    if (this.bitmap != null) {
      this.bitmap!.decrementRefCount();
      bitmap = null;
    }
  }

  @mustCallSuper
  Future<void> initBitmap(GraphicFactory graphicFactory) async {
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
      bitmap = await symbolCache!.getSymbol(bitmapSrc, bitmapWidth.round(), bitmapHeight.round(), bitmapPercent);
      bitmap!.incrementRefCount();
      bitmapPaint = graphicFactory.createPaint();
      bitmapPaint!.setColorFromNumber(0xff000000);
    } catch (e) {
      _log.warning("${e.toString()}, ignore missing bitmap in rendering");
      //print("Exception $e\nStacktrace $stacktrace");
      bitmap = null;
      bitmapInvalid = true;
    }
  }
}
