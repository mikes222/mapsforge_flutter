import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/core.dart';
import 'package:mapsforge_flutter/src/graphics/resourcebitmap.dart';

import '../testassetbundle.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SymbolCache', (WidgetTester tester) async {
    AssetBundle bundle = TestAssetBundle();
    SymbolCache symbolCache =
        FileSymbolCache(imageLoader: ImageBundleLoader(bundle: bundle));

    await tester.runAsync(() async {
      ResourceBitmap resourceBitmap =
          (await (symbolCache.getOrCreateSymbol("arrow.png", 0, 0)))!;
      assert(resourceBitmap != null);
    });
  });
}
