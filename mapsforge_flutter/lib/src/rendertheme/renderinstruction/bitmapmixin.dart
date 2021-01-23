import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';
import 'package:mapsforge_flutter/src/graphics/mappaint.dart';

class BitmapMixin {
  static final _log = new Logger('BitmapMixin');

  SymbolCache symbolCache;

  String src;

  Bitmap bitmap;

  bool bitmapInvalid = false;

  Future<Bitmap> _future;

  double height = 0;

  double width = 0;

  int percent = 100;

  MapPaint symbolPaint;

  @mustCallSuper
  void dispose() {
    if (this.bitmap != null) {
      this.bitmap.decrementRefCount();
      bitmap = null;
    }
    _future = null;
  }

  @mustCallSuper
  Future<void> initBitmap(GraphicFactory graphicFactory) async {
    //print("initResources called for $src");
    if (bitmapInvalid) return;

    if (bitmap != null) return;

    if (symbolCache != null) {
      if (src == null || src.isEmpty) {
        return;
      }
      try {
        bitmap = await symbolCache.getSymbol(src, width.round(), height.round(), percent);
        bitmap.incrementRefCount();
      } catch (e, stacktrace) {
        _log.warning("${e.toString()}, ignore missing bitmap in rendering");
        //print("Exception $e\nStacktrace $stacktrace");
        bitmap = null;
        bitmapInvalid = true;
      }
    }

    symbolPaint = graphicFactory.createPaint();
    symbolPaint.setColorFromNumber(0xff000000);
  }

  @protected
  Future<Bitmap> getOrCreateBitmap(GraphicFactory graphicFactory, String src) async {
    if (bitmapInvalid) return null;
    if (null == src || src.isEmpty) {
      bitmapInvalid = true;
      return null;
    }
    assert(symbolCache != null);

    if (bitmap != null) return bitmap;

    if (_future != null) {
      return _future;
    }
    try {
      _future = symbolCache.getSymbol(src, width.round(), height.round(), percent);
      bitmap = await _future;
      bitmap?.incrementRefCount();
      _future = null;
      bitmapInvalid = false;
      return bitmap;
    } catch (e, stacktrace) {
      _log.warning("Exception $e\nStacktrace $stacktrace");
      bitmap = null;
      _future = null;
      bitmapInvalid = true;
      return bitmap;
    }
  }
}
