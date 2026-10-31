import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

/// Renders two minimal themes from `rendertheme_fixes/` with the library's own
/// [DatastoreRenderer] and checks a few pixels of the resulting tile.
///
///     cd packages/mapsforge_flutter_renderer
///     flutter test test/datastore_renderer/rendertheme_fixes_test.dart
///
/// Pixel probes are used instead of a golden file on purpose: only the colour
/// of a way matters here, and goldens of anti-aliased lines differ slightly
/// from machine to machine.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const int zoomlevel = 16;
  final PixelProjection projection = PixelProjection(zoomlevel);
  final Tile tile = Tile(
    projection.longitudeToTileX(18),
    projection.latitudeToTileY(46),
    zoomlevel,
    0,
  );
  final BoundingBox box = tile.getBoundingBox();
  final double tileLeft = tile.tileX * projection.tileSize;
  final double tileTop = tile.tileY * projection.tileSize;

  /// A horizontal way across the whole tile, [fraction] of the way down.
  Way horizontalWay(List<Tag> tags, double fraction) {
    double lat =
        box.maxLatitude - (box.maxLatitude - box.minLatitude) * fraction;
    double margin = (box.maxLongitude - box.minLongitude) * 0.1;
    return Way(0, tags, [
      [
        LatLong(lat, box.minLongitude - margin),
        LatLong(lat, box.maxLongitude + margin),
      ],
    ], null);
  }

  /// Pixel row (inside the tile) of the way created by [horizontalWay].
  int rowOf(double fraction) {
    double lat =
        box.maxLatitude - (box.maxLatitude - box.minLatitude) * fraction;
    return (projection.latitudeToPixelY(lat) - tileTop).round();
  }

  int centerColumn() =>
      (projection.longitudeToPixelX((box.minLongitude + box.maxLongitude) / 2) -
              tileLeft)
          .round();

  /// Renders [datastore] with [renderTheme] and returns the tile's RGBA pixels.
  Future<_Pixels> render(
    Rendertheme renderTheme,
    MemoryDatastore datastore,
  ) async {
    DatastoreRenderer renderer = DatastoreRenderer(
      datastore,
      renderTheme,
      useSeparateLabelLayer: false,
    );
    addTearDown(renderer.dispose);
    JobResult jobResult = await renderer.executeJob(JobRequest(tile));
    expect(jobResult.picture, isNotNull);
    addTearDown(jobResult.picture!.dispose);
    // getImage() hands out a clone the caller owns. (convertPictureToImage()
    // returns a clone or the picture's own image depending on its state.)
    TilePicture picture = jobResult.picture!;
    ui.Image image =
        picture.getImage() ??
        picture.getPicture()!.toImageSync(
          projection.tileSize.round(),
          projection.tileSize.round(),
        );
    addTearDown(image.dispose);
    ByteData rgba = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    return _Pixels(rgba, image.width);
  }

  testWidgets('RuleOptimizer: aerialway casing is not painted over a highway', (
    WidgetTester tester,
  ) async {
    _Pixels? pixels = await tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile(
        "test/datastore_renderer/rendertheme_fixes/aerialway_casing.xml",
      );
      MemoryDatastore datastore = MemoryDatastore();
      datastore.addWay(horizontalWay([const Tag('highway', 'track')], 0.3));
      datastore.addWay(
        horizontalWay([const Tag('aerialway', 'cable_car')], 0.7),
      );
      return render(renderTheme, datastore);
    });

    int x = centerColumn();
    // Sanity check, true before and after the fix: the aerialway gets its casing.
    expect(
      pixels!.at(x, rowOf(0.7) - 10),
      _isRed,
      reason: "the aerialway should have its red casing",
    );
    // The defect: the casing rule also matched the highway and covered it.
    expect(
      pixels.at(x, rowOf(0.3)),
      _isBlue,
      reason:
          "the highway should be drawn in its own blue, not covered by the aerialway's red casing",
    );
    expect(
      pixels.at(x, rowOf(0.3) - 10),
      isNot(_isRed),
      reason: "the highway must not get the aerialway's red casing",
    );
  });

  testWidgets(
    'Dead rule: a theme with a rule that can never match still loads',
    (WidgetTester tester) async {
      _Pixels? pixels = await tester.runAsync(() async {
        Rendertheme renderTheme;
        try {
          renderTheme = await RenderThemeBuilder.createFromFile(
            "test/datastore_renderer/rendertheme_fixes/dead_rule.xml",
          );
        } on AssertionError catch (error) {
          fail("the theme failed to load: $error");
        }
        MemoryDatastore datastore = MemoryDatastore();
        datastore.addWay(horizontalWay([const Tag('highway', 'track')], 0.5));
        return render(renderTheme, datastore);
      });

      expect(
        pixels!.at(centerColumn(), rowOf(0.5)),
        _isBlue,
        reason: "the highway should be drawn in blue",
      );
    },
  );
}

class _Pixels {
  final ByteData rgba;
  final int width;

  _Pixels(this.rgba, this.width);

  /// Returns the pixel at ([x], [y]).
  _Rgba at(int x, int y) =>
      _Rgba(rgba.getUint32((y * width + x) * 4, Endian.big));
}

/// A pixel as 0xRRGGBBAA.
class _Rgba {
  final int value;

  const _Rgba(this.value);

  int get r => (value >> 24) & 0xff;
  int get g => (value >> 16) & 0xff;
  int get b => (value >> 8) & 0xff;

  @override
  String toString() => "#${value.toRadixString(16).padLeft(8, '0')} (RRGGBBAA)";
}

final Matcher _isRed = _ColorMatcher(
  "red",
  (c) => c.r > 200 && c.g < 80 && c.b < 80,
);
final Matcher _isBlue = _ColorMatcher("blue", (c) => c.b > 200 && c.r < 80);

class _ColorMatcher extends Matcher {
  final String name;
  final bool Function(_Rgba color) test;

  _ColorMatcher(this.name, this.test);

  @override
  bool matches(dynamic item, Map matchState) => test(item as _Rgba);

  @override
  Description describe(Description description) => description.add(name);
}
