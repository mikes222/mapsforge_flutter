import 'dart:ui';

import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';

import 'flutterbitmap.dart';

class FlutterTileBitmap extends FlutterBitmap implements TileBitmap {
  FlutterTileBitmap(Image bitmap, [String? src]) : super(bitmap, src);

  @override
  int? getTimestamp() {
    // TODO: implement getTimestamp
    return null;
  }

  @override
  bool? isExpired() {
    // TODO: implement isExpired
    return null;
  }

  @override
  void setExpiration(int expiration) {
    // TODO: implement setExpiration
  }

  @override
  void setTimestamp(int timestamp) {
    // TODO: implement setTimestamp
  }

  @override
  String toString() {
    return 'FlutterTileBitmap{$src}';
  }

  @override
  FlutterTileBitmap clone() {
    return FlutterTileBitmap(
        getClonedImage(), "$src-${++FlutterBitmap.bitmapSerial}");
  }
}
