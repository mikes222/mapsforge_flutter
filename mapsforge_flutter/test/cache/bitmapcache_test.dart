import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/core.dart';
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
      ResourceBitmap? resourceBitmap = await (symbolCache.getSymbol("arrow.png", 0, 0, 0));
      expect(resourceBitmap, isNotNull);
      TileBitmap bitmap = FlutterTileBitmap((resourceBitmap as FlutterResourceBitmap).bitmap);
      Tile tile = Tile(0, 0, 0, 0);
      cache.addTileBitmap(tile, bitmap);

      TileBitmap? result = await cache.getTileBitmapAsync(tile);
      expect(result, bitmap);
      cache.purgeAll();
    });
  });
}
