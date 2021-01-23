import 'dart:ui' as ui;

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/graphics/bitmap.dart';

class FlutterBitmap implements Bitmap {
  static final _log = new Logger('FlutterBitmap');

  final ui.Image bitmap;

  int _refcount = 0;

  ///
  /// optinal string to denote the type of resource. This is used to debug memory issues
  ///
  final String src;

  FlutterBitmap(this.bitmap, [this.src]) : assert(bitmap != null);

  @override
  void incrementRefCount() {
    assert(_refcount != -1);
    ++_refcount;
    if ((_refcount % 10) == 0) {
      _log.warning("Bitmap $this ($bitmap) refcount is $_refcount");
    }
  }

  @override
  void decrementRefCount() {
    assert(_refcount != -1);
    --_refcount;
    if (_refcount == 0) {
      bitmap.dispose();
      _refcount = -1;
    }
  }

  @override
  int getHeight() {
    assert(_refcount != -1);
    return bitmap.height;
  }

  @override
  int getWidth() {
    assert(_refcount != -1);
    return bitmap.width;
  }

  @override
  bool isDestroyed() {
    return _refcount == -1;
  }

  // @override
  // void scaleTo(int width, int height) {
  //   // TODO: implement scaleTo
  // }
  //
  // @override
  // void setBackgroundColor(int color) {
  //   // TODO: implement setBackgroundColor
  // }
}
