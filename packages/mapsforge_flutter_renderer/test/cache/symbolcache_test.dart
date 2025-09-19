import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter_renderer/src/cache/file_symbol_cache.dart';
import 'package:mapsforge_flutter_renderer/src/cache/image_bundle_loader.dart';
import 'package:mapsforge_flutter_renderer/src/cache/symbol_cache_mgr.dart';
import 'package:mapsforge_flutter_renderer/src/ui/symbol_image.dart';

import '../test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SymbolCacheMgr().symbolCache = FileSymbolCache();
  SymbolCacheMgr().symbolCache.addLoader("jar:", ImageBundleLoader(bundle: TestAssetBundle("test/cache")));

  testWidgets('SymbolCache returns an image', (WidgetTester tester) async {
    await tester.runAsync(() async {
      SymbolImage? symbolImage = await SymbolCacheMgr().getOrCreateSymbol("jar:arrow.png", 30, 30);
      expect(symbolImage, isNotNull);
    });
  });
}
