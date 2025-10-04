import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/marker/cluster_marker.dart';
import 'package:mapsforge_flutter/src/marker/single_marker_painter.dart';
import 'package:mapsforge_flutter/src/transform_widget.dart';

void main() {
  group('ClusterMarker Golden Tests', () {
    testWidgets('Renders a clusterMarker', (WidgetTester tester) async {
      MapPosition position = MapPosition(46, 18, 10);

      ClusterMarker circleMarker = ClusterMarker(position: position.getLatLong(), markerCount: 5);
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
      await expectLater(find.byKey(key), matchesGoldenFile('goldens/cluster_marker_count_5.png'));
    });

    testWidgets('renders correctly with count greater than 9', (WidgetTester tester) async {
      MapPosition position = MapPosition(46, 18, 10);

      ClusterMarker circleMarker = ClusterMarker(position: position.getLatLong(), markerCount: 15);
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
      await expectLater(find.byKey(key), matchesGoldenFile('goldens/cluster_marker_count_15.png'));
    });

    /// Test a test with testGoldens :-) Seems not much easier.
    testGoldens('renders correctly with count less than 10', (tester) async {
      MapPosition position = MapPosition(46, 18, 10);

      ClusterMarker circleMarker = ClusterMarker(position: position.getLatLong(), markerCount: 5);
      await circleMarker.changeZoomlevel(position.zoomlevel, position.projection);

      final builder =
          GoldenBuilder.grid(
            columns: 1,
            widthToHeightRatio: 1,
            wrap: (child) => Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.blue, width: 1)),
              child: SizedBox(width: 40, height: 40, child: child),
            ),
          )..addScenario(
            'Count 5',
            Transform.translate(
              offset: const Offset(20, 20),
              child: CustomPaint(foregroundPainter: SingleMarkerPainter(position, circleMarker), child: Container()),
            ),
          );

      await tester.pumpWidgetBuilder(builder.build());
      await screenMatchesGolden(tester, 'cluster_marker_count_5_golden');
    });
  });
}
