import 'dart:ui' as ui;

import 'package:mapsforge_flutter/src/graphics/bitmap.dart';

class FlutterBitmap implements Bitmap {
  final ui.Image bitmap;

  int _refcount = 0;

  FlutterBitmap(this.bitmap) : assert(bitmap != null);

  @override
  void decrementRefCount() {
    --_refcount;
    if (_refcount == 0) {
      bitmap.dispose();
      _refcount = -1;
    }
  }

  @override
  int getHeight() {
    return bitmap.height;
  }

  @override
  int getWidth() {
    return bitmap.width;
  }

  @override
  void incrementRefCount() {
    assert(_refcount != -1);
    ++_refcount;
  }

  @override
  bool isDestroyed() {
    return _refcount == -1;
  }

  @override
  void scaleTo(int width, int height) {
    // TODO: implement scaleTo
  }

  @override
  void setBackgroundColor(int color) {
    // TODO: implement setBackgroundColor
  }
}
