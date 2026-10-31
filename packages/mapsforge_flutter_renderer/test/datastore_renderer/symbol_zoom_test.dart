import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

import '../test_asset_bundle.dart';

/// Renders a symbol and a line symbol, each a 20 x 20 red square, with the
/// library's own [DatastoreRenderer] and measures how big the square comes out.
///
///     cd packages/mapsforge_flutter_renderer
///     flutter test test/datastore_renderer/symbol_zoom_test.dart
///
/// Symbols grow from [MapsforgeSettingsMgr.symbolMinZoomlevel] on, which
/// defaults to [MapsforgeSettingsMgr.strokeMinZoomlevelText].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const LatLong center = LatLong(46, 18);
  final int strokeMinZoomlevelText = MapsforgeSettingsMgr().strokeMinZoomlevelText;

  setUp(() {
    SymbolCacheMgr().symbolCache = FileSymbolCache();
    SymbolCacheMgr().symbolCache.addLoader("jar:", ImageBundleLoader(bundle: TestAssetBundle("test/assets")));
  });
  tearDown(() {
    MapsforgeSettingsMgr().symbolMinZoomlevel = null;
    MapsforgeSettingsMgr().strokeMinZoomlevelText = strokeMinZoomlevelText;
  });

  /// Loads [theme] (after the settings are made, as an app would), renders the
  /// tile holding [center] at [zoomlevel] with a peak there and a track through
  /// it, and returns the size in pixels of the largest red square drawn.
  Future<int> squareSize(WidgetTester tester, String theme, int zoomlevel) async {
    return (await tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/datastore_renderer/symbol_zoom/$theme");
      PixelProjection projection = PixelProjection(zoomlevel);
      Tile tile = Tile(projection.longitudeToTileX(center.longitude), projection.latitudeToTileY(center.latitude), zoomlevel, 0);
      BoundingBox box = tile.getBoundingBox();
      MemoryDatastore datastore = MemoryDatastore();
      datastore.addPoi(PointOfInterest(0, TagCollection(tags: [const Tag('natural', 'peak')]), center));
      datastore.addWay(
        Way(
          0,
          [const Tag('highway', 'track')],
          [
            [LatLong(center.latitude, box.minLongitude), LatLong(center.latitude, box.maxLongitude)],
          ],
          null,
        ),
      );
      DatastoreRenderer renderer = DatastoreRenderer(datastore, renderTheme, useSeparateLabelLayer: false);
      addTearDown(renderer.dispose);
      JobResult jobResult = await renderer.executeJob(JobRequest(tile));
      expect(jobResult.picture, isNotNull);
      addTearDown(jobResult.picture!.dispose);
      TilePicture picture = jobResult.picture!;
      int size = projection.tileSize.round();
      ui.Image image = picture.getImage() ?? picture.getPicture()!.toImageSync(size, size);
      addTearDown(image.dispose);
      ByteData rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      bool red(int x, int y) {
        int pixel = rgba.getUint32((y * image.width + x) * 4, Endian.big);
        return (pixel >> 24) & 0xff > 200 && (pixel >> 16) & 0xff < 80 && (pixel >> 8) & 0xff < 80;
      }

      // The longest vertical run of red pixels in any column.
      int largest = 0;
      for (int x = 0; x < image.width; x++) {
        int run = 0;
        for (int y = 0; y < image.height; y++) {
          run = red(x, y) ? run + 1 : 0;
          if (run > largest) largest = run;
        }
      }
      return largest;
    }))!;
  }

  for (String theme in ["symbol.xml", "linesymbol.xml"]) {
    group(theme, () {
      testWidgets('grows from zoomlevel 18 by default', (WidgetTester tester) async {
        expect(await squareSize(tester, theme, 17), closeTo(20, 1));
        // 20 x 1.4^(20 - 18 + 1)
        expect(await squareSize(tester, theme, 20), closeTo(55, 1));
      });

      testWidgets('follows strokeMinZoomlevelText while symbolMinZoomlevel is not set', (WidgetTester tester) async {
        MapsforgeSettingsMgr().strokeMinZoomlevelText = 20;
        // 20 x 1.4^(20 - 20 + 1)
        expect(await squareSize(tester, theme, 20), closeTo(28, 1));
      });

      testWidgets('grows from symbolMinZoomlevel', (WidgetTester tester) async {
        MapsforgeSettingsMgr().symbolMinZoomlevel = 20;
        expect(await squareSize(tester, theme, 20), closeTo(28, 1));
      });

      testWidgets('keeps its size when symbolMinZoomlevel is above the maximum zoomlevel', (WidgetTester tester) async {
        MapsforgeSettingsMgr().symbolMinZoomlevel = MapsforgeSettingsMgr.defaultMaxZoomlevel + 1;
        expect(await squareSize(tester, theme, 20), closeTo(20, 1));
      });
    });
  }
}
