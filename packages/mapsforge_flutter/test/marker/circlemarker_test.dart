import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/marker.dart';
import 'package:mapsforge_flutter/src/marker/single_marker_painter.dart';
import 'package:mapsforge_flutter/src/transform_widget.dart';

///
/// flutter test --update-goldens
///
///
void main() {
  testWidgets('Renders a circlemarker', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 10);

    CircleMarker circleMarker = CircleMarker(latLong: position.getLatLong());
    await circleMarker.changeZoomlevel(position.zoomlevel, position.projection);

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
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/circle_marker.png'));
  });

  testWidgets('Renders a circlemarker with text', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 15);

    CircleMarker circleMarker = CircleMarker(latLong: position.getLatLong())..addCaption(caption: 'Markercaption');
    await circleMarker.changeZoomlevel(position.zoomlevel, position.projection);

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
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/circle_marker_text.png'));
  });

  testWidgets('Renders a filled circlemarker', (WidgetTester tester) async {
    MapPosition position = MapPosition(46, 18, 17);

    CircleMarker circleMarker = CircleMarker(latLong: position.getLatLong(), fillColor: 0xff00ff00, radius: 20, strokeWidth: 4);
    await circleMarker.changeZoomlevel(position.zoomlevel, position.projection);

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
    await expectLater(find.byKey(key), matchesGoldenFile('goldens/circle_marker_filled.png'));
  });
}
