import 'package:dart_common/datastore.dart';
import 'package:dart_common/model.dart';
import 'package:dart_common/projection.dart';
import 'package:dart_common/src/datastore/memory_datastore.dart';
import 'package:dart_rendertheme/rendertheme.dart';
import 'package:datastore_renderer/src/job/job_request.dart';
import 'package:datastore_renderer/src/job/job_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _initLogging();
  });

  testWidgets('Line with bitmap', (WidgetTester tester) async {
    int l = 0;
    int zoomlevel = 16;
    int x = MercatorProjection.fromZoomlevel(zoomlevel).longitudeToTileX(18);
    int y = MercatorProjection.fromZoomlevel(zoomlevel).latitudeToTileY(46);

    var img = await (tester.runAsync(() async {
      Rendertheme renderTheme = await RenderThemeBuilder.createFromFile("test/rendertheme.xml");

      MemoryDatastore datastore = MemoryDatastore();
      // <line src="jar:patterns/access-destination.png" stroke-width="8.0" />
      // width changed to make the shader more visible
      datastore.addWay(
        const Way(
          0,
          [Tag('highway', 'track'), Tag('access', 'destination')],
          [
            [LatLong(45.96, 17.953), LatLong(46.0006, 18.0006)],
          ],
          null,
        ),
      );
      Tile tile = Tile(x, y, zoomlevel, l);
      expect(await datastore.supportsTile(tile), true);
      DatastoreReadResult result = await datastore.readMapDataSingle(tile);
      expect(result.ways.length, equals(1));
      JobRequest mapGeneratorJob = JobRequest(tile);
      MapDataStoreRenderer _dataStoreRenderer = MapDataStoreRenderer(datastore, renderTheme, symbolCache, true);

      JobResult jobResult = (await (_dataStoreRenderer.executeJob(mapGeneratorJob)));
      expect(jobResult.picture, isNotNull);
      return await jobResult.picture!.convertToImage();
    }));

    expect(img, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 1)),
              child: RawImage(image: img),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    //await tester.pump();
    await expectLater(find.byType(RawImage), matchesGoldenFile('bitmapline.png'));
  });
}

void _initLogging() {
  // Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });

  // Root logger level.
  Logger.root.level = Level.FINEST;
}
