import 'dart:convert';
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
    //print("disposing $src");
    //print(StackTrace.current);
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

  @override
  bool debugDisposed() {
    return _bitmap.debugDisposed;
  }

  @override
  void debugGetOpenHandleStackTraces() {
    List<StackTrace>? stacktraces = _bitmap.debugGetOpenHandleStackTraces();
    if (stacktraces == null) return null;

    print("=== start $src");
    int i = 0;
    for (StackTrace stackTrace in stacktraces) {
      print("stack: $i");
      String str = stackTrace.toString();
      LineSplitter lineSplitter = const LineSplitter();
      List<String> lines = lineSplitter.convert(str);
      String out = "";
      for (String line in lines) {
        if (line.contains("painting.dart")) continue;
        if (line.contains("flutterbitmap.dart")) continue;
        if (line.contains("flutterresourcebitmap.dart")) continue;
        if (line.contains("execution_queue.dart")) continue;
        if (line.contains("asynchronous suspension")) continue;

        out = "$out$line\n";
      }
      if (out.length > 0)
        print(out);
      else
        print(stackTrace);
      ++i;
    }
    print("--- end");
  }
}
