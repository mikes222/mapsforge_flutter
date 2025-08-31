import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/single_marker_painter.dart';
import 'package:mapsforge_flutter/src/transform_widget.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

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

  testWidgets('Renders a poimarker', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 12);

    PoiMarker circleMarker = PoiMarker(latLong: position.getLatLong(), src: "jar:symbols/tourist/view_point.svg", width: 200, height: 200);
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
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/poi_marker.png'));
  });

  testWidgets('Renders a poimarker bottom-center', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 12);

    PoiMarker circleMarker = PoiMarker(
      latLong: position.getLatLong(),
      src: "jar:symbols/tourist/view_point.svg",
      width: 200,
      height: 200,
      positioning: MapPositioning.BELOW,
    );
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
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/poi_marker_bottomcenter.png'));
  });

  testWidgets('Renders a poimarker bottom-center with text', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 12);

    PoiMarker circleMarker = PoiMarker(
      latLong: position.getLatLong(),
      src: "jar:symbols/tourist/view_point.svg",
      width: 200,
      height: 200,
      positioning: MapPositioning.BELOW,
    )..addCaption(caption: "PoiMarker with text");
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
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/poi_marker_bottomcenter_text.png'));
  });

  testWidgets('Renders a poimarker bottom-center with text above', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 12);

    PoiMarker circleMarker = PoiMarker(
      latLong: position.getLatLong(),
      src: "jar:symbols/tourist/view_point.svg",
      width: 200,
      height: 200,
      positioning: MapPositioning.BELOW,
    )..addCaption(caption: "PoiMarker with text", position: MapPositioning.ABOVE);
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
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/poi_marker_bottomcenter_text_above.png'));
  });

  testWidgets('Renders a poimarker bottom-center with text left', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 12);

    PoiMarker circleMarker = PoiMarker(
      latLong: position.getLatLong(),
      src: "jar:symbols/tourist/view_point.svg",
      width: 200,
      height: 200,
      positioning: MapPositioning.BELOW,
    )..addCaption(caption: "PoiMarker with text", position: MapPositioning.LEFT);
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
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/poi_marker_bottomcenter_text_left.png'));
  });

  testWidgets('Renders a poimarker with text', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 12);

    PoiMarker circleMarker = PoiMarker(latLong: position.getLatLong(), src: "jar:symbols/tourist/view_point.svg")..addCaption(caption: "Markercaption");
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
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/poi_marker_text.png'));
  });

  testWidgets('Renders a poimarker with multiple captions', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 12);

    PoiMarker circleMarker = PoiMarker(latLong: position.getLatLong(), src: "jar:symbols/tourist/view_point.svg")
      ..addCaption(caption: "Markercaption")
      ..addCaption(caption: "Markercaption", fontSize: 16, position: MapPositioning.ABOVE)
      ..addCaption(caption: "Markercaption", fontSize: 8, position: MapPositioning.RIGHT);
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
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/poi_marker_multiple_text.png'));
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
