import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mapsforge_flutter/src/graphics/graphicfactory.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/flutterresourcebitmap.dart';

///
/// An abstract cache for symbols (small bitmaps used in the map, eg. stopsigns, arrows). The class retrieves and caches requested symbols. It also resizes them if desired.
///
abstract class SymbolCache {
  SymbolCache();

  ///
  /// Disposes the cache. It should not be used afterwards
  ///
  void dispose() {}

  ///
  /// loads and returns the desired symbol
  ///
  Future<ResourceBitmap> getSymbol(String src, int width, int height, int percent);
}
