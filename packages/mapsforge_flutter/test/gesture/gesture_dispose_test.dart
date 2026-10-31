import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapsforge_flutter/gesture.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/projection.dart';
import 'package:mapsforge_flutter_renderer/offline_renderer.dart';
import 'package:mapsforge_flutter_renderer/ui.dart';
import 'package:mapsforge_flutter_rendertheme/model.dart';

class _EmptyRenderer extends Renderer {
  @override
  Future<JobResult> executeJob(JobRequest jobRequest) async {
    ui.PictureRecorder recorder = ui.PictureRecorder();
    ui.Canvas(recorder);
    return JobResult.normal(TilePicture.fromPicture(recorder.endRecording()));
  }

  @override
  Future<JobResult> retrieveLabels(JobRequest jobRequest) async => JobResult.normalLabels(RenderInfoCollection([]));

  @override
  String getRenderKey() => 'empty';

  @override
  bool supportLabels() => true;
}

void main() {
  test('events after dispose are ignored', () async {
    MapModel mapModel = MapModel(renderer: _EmptyRenderer());
    mapModel.setPosition(MapPosition(46, 18, 16));
    await mapModel.dispose();

    mapModel.setPosition(MapPosition(47, 19, 16));
    expect(mapModel.lastPosition!.latitude, 46);
    mapModel.manualMove(Object());
    mapModel.tap(null);
    mapModel.longTap(null);
    mapModel.doubleTap(null);
    PixelProjection projection = PixelProjection(16);
    mapModel.dragNdrop(
      DragNdropEvent(
        latitude: 46,
        longitude: 18,
        projection: projection,
        mappoint: projection.latLonToPixel(const LatLong(46, 18)),
        type: DragNdropEventType.start,
      ),
    );
  });

  testWidgets('a fling stops when the view is disposed', (WidgetTester tester) async {
    MapModel mapModel = MapModel(renderer: _EmptyRenderer());
    mapModel.setPosition(MapPosition(46, 18, 16));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 400, height: 400, child: GenericGestureDetector(mapModel: mapModel)),
      ),
    );

    // A quick swipe: the finger leaves while the map still moves. The fling's speed is measured with the wall
    // clock, so real time has to pass between the moves.
    TestGesture gesture = await tester.startGesture(const Offset(200, 200));
    for (int i = 1; i <= 5; i++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 15)));
      await tester.pump(const Duration(milliseconds: 10));
      await gesture.moveTo(Offset(200 + i * 30.0, 200));
    }
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));
    double moving = mapModel.lastPosition!.longitude;
    await tester.pump(const Duration(milliseconds: 50));
    expect(mapModel.lastPosition!.longitude, isNot(moving), reason: 'the fling must still be moving the map');

    // The view goes away while the map is still moving; the map model lives on.
    await tester.pumpWidget(const SizedBox());
    double stopped = mapModel.lastPosition!.longitude;
    await tester.pump(const Duration(milliseconds: 500));
    expect(mapModel.lastPosition!.longitude, stopped, reason: 'the fling must stop with the view');

    await mapModel.dispose();
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
