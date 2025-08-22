import 'package:datastore_renderer/src/cache/file_symbol_cache.dart';
import 'package:datastore_renderer/src/cache/image_bundle_loader.dart';
import 'package:datastore_renderer/src/cache/symbol_cache_mgr.dart';
import 'package:datastore_renderer/src/ui/symbol_image.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SymbolCacheMgr().symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle("test/cache")));

  testWidgets('SymbolCache returns an image', (WidgetTester tester) async {
    await tester.runAsync(() async {
      SymbolImage? symbolImage = await SymbolCacheMgr().getOrCreateSymbol("arrow.png", 30, 30);
      expect(symbolImage, isNotNull);
    });
  });
}
