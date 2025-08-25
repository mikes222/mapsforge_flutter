import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/util/rotate_helper.dart';

class TapGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  const TapGestureDetector({super.key, required this.mapModel});

  @override
  State<TapGestureDetector> createState() => _TapGestureDetectorState();
}

//////////////////////////////////////////////////////////////////////////////

class _TapGestureDetectorState extends State<TapGestureDetector> {
  static final _log = Logger('_TapGestureDetectorState');

  final bool doLog = false;

  _TapDownEvent? _eventHandler;

  // short click:
  // onTapDown
  // onTapUp
  //
  // long click:
  // onTapDown
  // onTapUp
  //
  // doubletap:
  // onDoubleTapDown
  // onTapDown
  // onDoubleTap
  //
  // normal drag event:
  // optionally (if the user waits a bit): onTapDown
  // onScaleStart with pointerCount 1
  // several onScaleUpdate with scale 1.0, rotation 0.0 and pointerCount: 1
  // onScaleEnd with velocity 0/0 and pointerCount: 0
  // NO onTapUp!
  //
  // zoom-in event:
  // optionally (if the user waits a bit): onTapDown
  // onScaleStart with pointerCount 2
  // several onScaleUpdate scale > 1, rotation normally != 0 and pointerCount: 2
  // onScaleEnd with velocity 0/0 and pointerCount: 1
  //
  // swipe: (similar to normal drag event)
  // optionally (if the user waits a bit): onTapDown
  // onScaleStart with pointerCount 1
  // several onScaleUpdate with scale 1.0, rotation 0.0 and pointerCount: 1
  // onScaleEnd with velocity -2324/-2699, pointerCount 0
  // velocity is in pixels per second
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (TapDownDetails details) {
            if (doLog) _log.info("onTapDown $details with localPosition ${details.localPosition}");
            // only if we do not have already a double tap down event
            _eventHandler ??= _TapDownEvent(mapModel: widget.mapModel, tapDownLocalPosition: details.localPosition, size: constraints.biggest);
          },
          onTapUp: (TapUpDetails details) {
            if (doLog) _log.info("onTapUp $details");
            _eventHandler?.tapUp(size: constraints.biggest);
            _eventHandler?.dispose();
            _eventHandler = null;
          },
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

/////////////////////////////////////////////////////////////////////////////

class _TapDownEvent {
  final MapModel mapModel;

  final Offset tapDownLocalPosition;

  final int tapDownTime;

  bool _stop = false;

  bool _longPressed = false;

  Timer? _timer;

  _TapDownEvent({required this.mapModel, required this.tapDownLocalPosition, required Size size}) : tapDownTime = DateTime.now().millisecondsSinceEpoch {
    _timer = Timer(const Duration(milliseconds: 500), () {
      // tapped at least 500 ms, user wants to move something (or long-press, but the latter is reported at onTapUp)
      if (_stop) return;
      _longPressed = true;

      PositionInfo positionInfo = RotateHelper.normalize(mapModel.lastPosition!, size, tapDownLocalPosition.dx, tapDownLocalPosition.dy);
    });
  }

  void dispose() {
    _stop = true;
    _timer?.cancel();
    _timer = null;
  }

  void tapUp({required Size size}) {
    _stop = true;
    _timer?.cancel();
    _timer = null;
    PositionInfo positionInfo = RotateHelper.normalize(mapModel.lastPosition!, size, tapDownLocalPosition.dx, tapDownLocalPosition.dy);

    if (longPressed) {
      // tapped at least 500 ms, long tap
      // we already reported a gestureMoveStartEvent, we should cancel it
      TapEvent tapEvent = TapEvent(
        latitude: positionInfo.latitude,
        longitude: positionInfo.longitude,
        projection: mapModel.lastPosition!.projection,
        mappoint: positionInfo.mappoint,
      );
      mapModel.longTap(tapEvent);
      return;
    } else {
      TapEvent tapEvent = TapEvent(
        latitude: positionInfo.latitude,
        longitude: positionInfo.longitude,
        projection: mapModel.lastPosition!.projection,
        mappoint: positionInfo.mappoint,
      );
      mapModel.tap(tapEvent);
    }
  }

  bool get longPressed => _longPressed;
}
