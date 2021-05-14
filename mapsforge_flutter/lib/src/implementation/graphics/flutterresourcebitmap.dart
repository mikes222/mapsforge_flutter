import 'dart:ui';

import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';

import 'flutterbitmap.dart';

class FlutterResourceBitmap extends FlutterBitmap implements ResourceBitmap {
  FlutterResourceBitmap(Image bitmap, [String? src]) : super(bitmap, src);

  @override
  String toString() {
    return 'FlutterResourceBitmap{src: $src}';
  }
}
