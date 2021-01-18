import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

import '../testassetbundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ///
  /// Test one single tile
  testWidgets('Bitmapcache', (WidgetTester tester) async {
    MemoryTileBitmapCache cache = MemoryTileBitmapCache();
    AssetBundle bundle = TestAssetBundle();
    ByteData content = await bundle.load("arrow.png");
    assert(content != null);

    await tester.runAsync(() async {
      var codec = await ui.instantiateImageCodec(content.buffer.asUint8List());
      // add additional checking for number of frames etc here
      var frame = await codec.getNextFrame();
      ui.Image img = frame.image;

      TileBitmap bitmap = FlutterTileBitmap(img);
      Tile tile = Tile(0, 0, 0, 0, 0);
      cache.addTileBitmap(tile, bitmap);

      TileBitmap result = await cache.getTileBitmapAsync(tile);
      assert(result == bitmap);
    });
  });
}
