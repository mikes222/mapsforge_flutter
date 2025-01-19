import 'dart:ui';

import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';

import '../../graphics/implementation/flutterbitmap.dart';

class FlutterResourceBitmap extends FlutterBitmap implements ResourceBitmap {
  FlutterResourceBitmap(Image bitmap, [String? src]) : super(bitmap, src);

  @override
  String toString() {
    return "FlutterResourceBitmap{src: $src, width: ${getWidth()}, height: ${getHeight()}}";
  }

  @override
  FlutterResourceBitmap clone() {
    FlutterResourceBitmap result = FlutterResourceBitmap(
        getClonedImage(), "$src-${++FlutterBitmap.bitmapSerial}");
    //print("Cloning ${result.src} from $src");
    //print(StackTrace.current);
    return result;
  }
}
