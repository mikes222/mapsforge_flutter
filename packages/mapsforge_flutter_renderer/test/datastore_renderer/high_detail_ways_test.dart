import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/src/util/datastore_reader_impl.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';
import 'package:mapsforge_flutter_rendertheme/rendertheme.dart';

const _themeXml = '''
<rendertheme xmlns="http://mapsforge.org/renderTheme" version="6" map-background="#ffffff">
  <rule e="way" k="test" v="yes">
    <line stroke="#ff0000" stroke-width="2" />
    <caption k="name" font-size="10" fill="#000000" display="always" />
  </rule>
</rendertheme>
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('highDetailWays', () {
    late _Fixture fixture;

    setUp(() {
      fixture = _Fixture(7);
    });

    tearDown(() {
      fixture.datastore.dispose();
      fixture.theme.dispose();
    });

    test('default and explicit false drop tiny roads', () async {
      fixture.addWay(const [Tag('highway', 'primary')]);
      final defaultResult = await DatastoreReaderImpl(
        fixture.datastore,
      ).read(fixture.tile, fixture.level);
      final falseResult = await DatastoreReaderImpl(
        fixture.datastore,
        highDetailWays: false,
      ).read(fixture.tile, fixture.level);
      expect(defaultResult, isNotNull);
      expect(falseResult, isNotNull);
      expect(defaultResult!.drawings.renderInfos, isEmpty);
      expect(falseResult!.drawings.renderInfos, isEmpty);
    });

    test('enabled retains tiny road geometry', () async {
      final way = fixture.addWay(const [Tag('highway', 'primary')]);
      final result = await fixture.read(true);
      final properties =
          (result.drawings.renderInfos.single as RenderInfoWay).wayProperties;
      expect(properties.way, same(way));
    });

    test('enabled still drops tiny unrelated ways', () async {
      fixture.addWay(const [Tag('natural', 'cliff')]);
      expect((await fixture.read(true)).drawings.renderInfos, isEmpty);
    });
  });

  for (final enabled in <bool?>[null, true]) {
    test('renderer forwards highDetailWays=$enabled', () async {
      final fixture = _Fixture(7);
      fixture.addWay(const [Tag('highway', 'primary')]);
      final renderer = enabled == null
          ? DatastoreRenderer(fixture.datastore, fixture.theme)
          : DatastoreRenderer(
              fixture.datastore,
              fixture.theme,
              highDetailWays: enabled,
            );
      addTearDown(renderer.dispose);

      final result = await renderer.executeJob(JobRequest(fixture.tile));
      expect(result.picture, isNotNull);
      final picture = result.picture!;
      addTearDown(picture.dispose);
      final image = picture.getImage() ?? picture.convertPictureToImage();
      addTearDown(image.dispose);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(bytes, isNotNull);
      var redPixels = 0;
      for (var offset = 0; offset < bytes!.lengthInBytes; offset += 4) {
        if (bytes.getUint8(offset) > 200 &&
            bytes.getUint8(offset + 1) < 100 &&
            bytes.getUint8(offset + 2) < 100) {
          redPixels++;
        }
      }
      expect(redPixels, enabled == true ? greaterThan(0) : 0);
    });
  }
}

class _Fixture {
  final int zoom;
  final MemoryDatastore datastore = MemoryDatastore();
  final Rendertheme theme = RenderThemeBuilder.createFromString(_themeXml);
  late final PixelProjection projection = PixelProjection(zoom);
  late final Tile tile = Tile(1 << (zoom - 1), 1 << (zoom - 1), zoom, 0);
  late final RenderthemeZoomlevel level = theme.prepareZoomlevel(zoom);

  _Fixture(this.zoom);

  Way way(
    List<Tag> tags, {
    List<Mappoint> points = const [Mappoint(64, 64), Mappoint(68, 64)],
  }) {
    final origin = projection.getLeftUpper(tile);
    return Way(0, tags, [
      points
          .map(
            (point) => projection.pixelToLatLong(
              origin.x + point.x,
              origin.y + point.y,
            ),
          )
          .toList(),
    ], null);
  }

  Way addWay(
    List<Tag> tags, {
    List<Mappoint> points = const [Mappoint(64, 64), Mappoint(68, 64)],
  }) {
    final result = way([const Tag('test', 'yes'), ...tags], points: points);
    datastore.addWay(result);
    return result;
  }

  Future<LayerContainerCollection> read(bool enabled) async {
    final result = await DatastoreReaderImpl(
      datastore,
      highDetailWays: enabled,
    ).read(tile, level);
    expect(result, isNotNull);
    return result!;
  }
}
