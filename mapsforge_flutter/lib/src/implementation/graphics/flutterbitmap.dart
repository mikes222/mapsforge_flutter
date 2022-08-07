import 'dart:ui' as ui;

import 'package:mapsforge_flutter/src/graphics/bitmap.dart';

class FlutterBitmap implements Bitmap {
  final ui.Image bitmap;

  ///
  /// optinal string to denote the type of resource. This is used to debug memory issues
  ///
  final String? src;

  FlutterBitmap(this.bitmap, [this.src]);

  @override
  void dispose() {
    bitmap.dispose();
  }

  @override
  int getHeight() {
    return bitmap.height;
  }

  @override
  int getWidth() {
    return bitmap.width;
  }
}
