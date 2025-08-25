import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/util/rotate_helper.dart';

class DoubleTapGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  const DoubleTapGestureDetector({super.key, required this.mapModel});

  @override
  State<DoubleTapGestureDetector> createState() => _DoubleTapGestureDetectorState();
}

//////////////////////////////////////////////////////////////////////////////

class _DoubleTapGestureDetectorState extends State<DoubleTapGestureDetector> {
  static final _log = Logger('_MoveGestureDetectorState');

  final bool doLog = false;

  _DoubleTapEvent? _eventHandler;

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
          onDoubleTapDown: (TapDownDetails details) {
            if (doLog) {
              _log.info("onDoubleTapDown $details with localPosition ${details.localPosition}");
            }
            _eventHandler = _DoubleTapEvent(mapModel: widget.mapModel, details: details);
          },
          onDoubleTap: () {
            if (doLog) _log.info("onDoubleTap");
            //print("Screensize: ${widget.screensize}");
            _eventHandler?.tapUp(size: constraints.biggest);
            _eventHandler = null;
          },
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

/////////////////////////////////////////////////////////////////////////////

class _DoubleTapEvent {
  final MapModel mapModel;

  late Offset _doubleTapLocalPosition;

  _DoubleTapEvent({required this.mapModel, required TapDownDetails details}) {
    _doubleTapLocalPosition = details.localPosition;
  }

  void tapUp({TapUpDetails? details, required Size size}) {
    MapPosition? lastPosition = mapModel.lastPosition;
    if (lastPosition == null) return;
    PositionInfo positionInfo = RotateHelper.normalize(lastPosition, size, _doubleTapLocalPosition.dx, _doubleTapLocalPosition.dy);
    // interpolate the new center between the old center and where we
    // pressed now. The new center is half-way between our double-pressed point and the old-center
    TapEvent tapEvent = TapEvent(
      latitude: positionInfo.latitude,
      longitude: positionInfo.longitude,
      projection: mapModel.lastPosition!.projection,
      mappoint: positionInfo.mappoint,
    );
    mapModel.doubleTap(tapEvent);
  }
}
