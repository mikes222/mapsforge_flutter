import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/maps.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';
import 'package:mapsforge_flutter/src/graphics/tilebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/flutterresourcebitmap.dart';
import 'package:mapsforge_flutter/src/implementation/graphics/fluttertilebitmap.dart';
import 'package:mapsforge_flutter/src/model/tile.dart';

import '../testassetbundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Bitmapcache', (WidgetTester tester) async {
    AssetBundle bundle = TestAssetBundle();
    SymbolCache symbolCache = FileSymbolCache(bundle);

    MemoryTileBitmapCache cache = MemoryTileBitmapCache();

    await tester.runAsync(() async {
      ResourceBitmap resourceBitmap = await symbolCache.getSymbol("arrow.png", 0, 0, 0);
      // ByteData content = await bundle.load("arrow.png");
      // assert(content != null);
      //
      // var codec = await ui.instantiateImageCodec(content.buffer.asUint8List());
      // // add additional checking for number of frames etc here
      // var frame = await codec.getNextFrame();
      // ui.Image img = frame.image;

      TileBitmap bitmap = FlutterTileBitmap((resourceBitmap as FlutterResourceBitmap).bitmap);
      MercatorProjectionImpl mercatorProjection = MercatorProjectionImpl(256, 0);
      Tile tile = Tile(0, 0, 0, 0, mercatorProjection);
      cache.addTileBitmap(tile, bitmap);

      TileBitmap result = await cache.getTileBitmapAsync(tile);
      assert(result == bitmap);
      cache.purgeAll();
    });
  });
}
