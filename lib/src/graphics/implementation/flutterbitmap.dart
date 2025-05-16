import 'dart:ui' as ui;

import 'package:mapsforge_flutter/src/graphics/bitmap.dart';

class FlutterBitmap implements Bitmap {
  final ui.Image _bitmap;

  ///
  /// optinal string to denote the type of resource. This is used to debug memory issues
  ///
  final String? src;

  static int bitmapSerial = 0;

  const FlutterBitmap(this._bitmap, [this.src]);

  @override
  void dispose() {
    _bitmap.dispose();
  }

  @override
  int getHeight() {
    return _bitmap.height;
  }

  @override
  int getWidth() {
    return _bitmap.width;
  }

  @override
  FlutterBitmap clone() {
    return FlutterBitmap(getClonedImage(), "$src-${++bitmapSerial}");
  }

  ui.Image getClonedImage() {
    return _bitmap.clone();
  }
}
