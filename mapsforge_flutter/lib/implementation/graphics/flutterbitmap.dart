import 'dart:ui' as ui;

import 'package:mapsforge_flutter/graphics/bitmap.dart';

class FlutterBitmap implements Bitmap {
  final ui.Image bitmap;

  int _refcount = 0;

  FlutterBitmap(this.bitmap) : assert(bitmap != null);

  @override
  void decrementRefCount() {
    --_refcount;
    if (_refcount == 0) {
      bitmap.dispose();
    }
  }

  @override
  int getHeight() {
    // TODO: implement getHeight
    return null;
  }

  @override
  int getWidth() {
    // TODO: implement getWidth
    return null;
  }

  @override
  void incrementRefCount() {
    ++_refcount;
  }

  @override
  bool isDestroyed() {
    // TODO: implement isDestroyed
    return null;
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
