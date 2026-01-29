import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_core/utils.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HgtRenderer renders a tile from a synthetic .hgt file', (WidgetTester tester) async {
    final tmp = await Directory.systemTemp.createTemp('hgt_renderer_test');
    addTearDown(() async {
      if (await tmp.exists()) {
        await tmp.delete(recursive: true);
      }
    });

    // 3x3 sample grid for N00E000.hgt, big-endian int16.
    // Rows are north->south. We'll create a simple gradient.
    final values = <int>[300, 310, 320, 200, 210, 220, 100, 110, 120];
    final bd = ByteData(values.length * 2);
    for (int i = 0; i < values.length; i++) {
      bd.setInt16(i * 2, values[i], Endian.big);
    }

    final file = File('${tmp.path}${Platform.pathSeparator}N00E000.hgt');
    await file.writeAsBytes(bd.buffer.asUint8List(), flush: true);

    MapsforgeSettingsMgr().tileSize = 16;

    final renderer = HgtRenderer(
      mode: HgtRenderMode.elevation,
      hgtFileProvider: HgtFileProvider(directoryPath: tmp.path),
    );
    addTearDown(renderer.dispose);

    // Pick a tile that overlaps lon/lat ~ 0.5/0.5 (within N00E000).
    final zoom = 10;
    final proj = MercatorProjection.fromZoomlevel(zoom);
    final tileX = proj.longitudeToTileX(0.5);
    final tileY = proj.latitudeToTileY(0.5);
    final tile = Tile(tileX, tileY, zoom, 0);

    final result = await renderer.executeJob(JobRequest(tile));
    expect(result.result, JOBRESULT.NORMAL);
    expect(result.picture, isNotNull);

    final img = await tester.runAsync(() async {
      return await result.picture!.convertPictureToImage();
    });
    addTearDown(result.picture!.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: RawImage(image: img)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(find.byType(RawImage), matchesGoldenFile('hgt/goldens/hgt_renderer_synthetic.png'));
  });
}
