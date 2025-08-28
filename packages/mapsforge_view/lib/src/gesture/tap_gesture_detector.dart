import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/util/rotate_helper.dart';

/// Recognizes short and long taps and informs [MapModel]
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

  bool _longPressed = false;

  Timer? _timer;

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
            if (_timer != null) return;
            _longPressed = false;
            _timer = Timer(const Duration(milliseconds: 500), () {
              // tapped at least 500 ms, user wants to move something (or long-press, but the latter is reported at onTapUp)
              _longPressed = true;
              _timer = null;
            });
          },
          onTapUp: (TapUpDetails details) {
            if (doLog) _log.info("onTapUp $details");
            _timer?.cancel();
            _timer = null;
            MapPosition lastPosition = widget.mapModel.lastPosition!;
            PositionInfo positionInfo = RotateHelper.normalize(lastPosition, constraints.biggest, details.localPosition.dx, details.localPosition.dy);

            TapEvent tapEvent = TapEvent(
              latitude: positionInfo.latitude,
              longitude: positionInfo.longitude,
              projection: lastPosition.projection,
              mappoint: positionInfo.mappoint,
            );
            if (_longPressed) {
              widget.mapModel.longTap(tapEvent);
              return;
            } else {
              widget.mapModel.tap(tapEvent);
            }
          },
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
