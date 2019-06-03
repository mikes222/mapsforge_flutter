import 'dart:ui';

import 'package:mapsforge_flutter/graphics/tilebitmap.dart';

import 'flutterbitmap.dart';

class FlutterTileBitmap extends FlutterBitmap implements TileBitmap {
  FlutterTileBitmap(Image bitmap) : super(bitmap) {
    incrementRefCount();
  }

  @override
  int getTimestamp() {
    // TODO: implement getTimestamp
    return null;
  }

  @override
  bool isExpired() {
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
    return 'FlutterTileBitmap{}';
  }
}
