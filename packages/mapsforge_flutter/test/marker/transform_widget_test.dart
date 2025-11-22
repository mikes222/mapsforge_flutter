import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/transform_widget.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_renderer/cache.dart';

import '../test_asset_bundle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ui.Image image;

  setUp(() async {
    _initLogging();
    SymbolCacheMgr().symbolCache = FileSymbolCache();
    SymbolCacheMgr().symbolCache.addLoader("jar:", ImageBundleLoader(bundle: TestAssetBundle("test/assets")));

    final bytes = await File('test/assets/transform_testimage.png').readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    image = frame.image;
  });

  testWidgets('Base image', (WidgetTester tester) async {
    // Decode the PNG into a ui.Image before pumping the widget to ensure it is
    // synchronously available during painting.

    Key key = UniqueKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: Center(
            key: key,
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 1)),
              child: CustomPaint(size: const Size(200, 200), painter: _ImagePainter(image)),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(find.byKey(key), matchesGoldenFile('goldens/transform_widget_testimage.png'));
  });

  testWidgets('TransformWidget base position', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 12);

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
                    child: Transform.translate(
                      // shift the map according the the centerposition set with viewModel.setPosition() et al
                      offset: const Offset((-400), (-300)),
                      child: CustomPaint(size: const Size(200, 200), painter: _ImagePainter(image)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(find.byKey(key), matchesGoldenFile('goldens/transform_widget_base.png'));
  });

  testWidgets('TransformWidget rotated 45 degrees', (WidgetTester tester) async {
    MapPosition base = MapPosition(46, 18, 12);
    MapPosition position = base.rotateTo(45);

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
                    child: Transform.translate(
                      // shift the map according the the centerposition set with viewModel.setPosition() et al
                      offset: const Offset((-400), (-300)),
                      child: CustomPaint(size: const Size(200, 200), painter: _ImagePainter(image)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(key), matchesGoldenFile('goldens/transform_widget_rotation_45.png'));
  });

  testWidgets('TransformWidget zoomed out (zoom 8)', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 8);

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
                    child: Transform.translate(
                      // shift the map according the the centerposition set with viewModel.setPosition() et al
                      offset: const Offset((-400), (-300)),
                      child: CustomPaint(size: const Size(200, 200), painter: _ImagePainter(image)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(key), matchesGoldenFile('goldens/transform_widget_zoom_8.png'));
  });

  testWidgets('TransformWidget zoomed in (zoom 16)', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 16);

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
                    child: Transform.translate(
                      // shift the map according the the centerposition set with viewModel.setPosition() et al
                      offset: const Offset((-400), (-300)),
                      child: CustomPaint(size: const Size(200, 200), painter: _ImagePainter(image)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(key), matchesGoldenFile('goldens/transform_widget_zoom_16.png'));
  });

  testWidgets('TransformWidget scaled down around center', (WidgetTester tester) async {
    MapPosition base = MapPosition(46, 18, 12);
    MapPosition position = base.scaleAround(null, 0.5);

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
                    child: Transform.translate(
                      // shift the map according the the centerposition set with viewModel.setPosition() et al
                      offset: const Offset((-400 / 0.5), (-300 / 0.5)),
                      child: CustomPaint(size: const Size(200, 200), painter: _ImagePainter(image)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(key), matchesGoldenFile('goldens/transform_widget_scale_0_5.png'));
  });

  testWidgets('TransformWidget scaled up around focal point', (WidgetTester tester) async {
    MapPosition base = MapPosition(46, 18, 12);
    MapPosition position = base.scaleAround(const Offset(600, 500), 1.8);

    PoiMarker marker = PoiMarker(latLong: base.getLatLong(), src: "jar:transform_widget_image.svg", width: 200, height: 200);
    await tester.runAsync(() async {
      await marker.changeZoomlevel(base.zoomlevel, base.projection);
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
                    child: Transform.translate(
                      // shift the map according the the centerposition set with viewModel.setPosition() et al
                      offset: const Offset((-400 / 1.8), (-300 / 1.8)),
                      child: CustomPaint(size: const Size(200, 200), painter: _ImagePainter(image)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(key), matchesGoldenFile('goldens/transform_widget_scale_1_8_focal.png'));
  });

  testWidgets('TransformWidget with shifted mapCenter', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 12);
    Mappoint center = position.getCenter();
    MapPosition shifted = position.setCenter(center.x - 40, center.y - 40);

    PoiMarker marker = PoiMarker(latLong: position.getLatLong(), src: "jar:transform_widget_image.svg", width: 200, height: 200);
    await tester.runAsync(() async {
      await marker.changeZoomlevel(position.zoomlevel, position.projection);
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
                    mapCenter: shifted.getCenter(),
                    child: Transform.translate(
                      // shift the map according the the centerposition set with viewModel.setPosition() et al
                      offset: const Offset((-400 / 1.8), (-300 / 1.8)),
                      child: CustomPaint(size: const Size(200, 200), painter: _ImagePainter(image)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(find.byKey(key), matchesGoldenFile('goldens/transform_widget_shifted_center.png'));
  });
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Offset.zero & size;
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), rect, paint);
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) => false;
}

void _initLogging() {
  Logger.root.onRecord.listen((LogRecord r) {
    print('${r.time}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });

  Logger.root.level = Level.FINEST;
}
