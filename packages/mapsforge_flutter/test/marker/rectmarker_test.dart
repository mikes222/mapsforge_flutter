import 'package:datastore_renderer/cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/single_marker_painter.dart';
import 'package:mapsforge_flutter/src/transform_widget.dart';
import 'package:mapsforge_flutter_core/model.dart';

import '../test_asset_bundle.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _initLogging();
    SymbolCacheMgr().symbolCache = FileSymbolCache(imageLoader: ImageBundleLoader(bundle: TestAssetBundle("test/assets")));
  });

  testWidgets('Renders a rectmarker', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 10);

    RectMarker circleMarker = RectMarker(minLatLon: const LatLong(45.97, 17.9), maxLatLon: const LatLong(46.03, 18.1));
    await tester.runAsync(() async {
      await circleMarker.changeZoomlevel(position.zoomlevel, position.projection);
    });

    Key key = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            key: key,
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 1)),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return TransformWidget(
                    screensize: constraints.biggest,
                    mapPosition: position,
                    mapCenter: position.getCenter(),
                    child: CustomPaint(foregroundPainter: SingleMarkerPainter(position, circleMarker), child: Container()),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/rect_marker.png'));
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
