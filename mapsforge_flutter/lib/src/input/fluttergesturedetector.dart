import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import '../../core.dart';
import '../utils/rotatehelper.dart';

///
/// A detector for finger-gestures. It currently supports move, pinch-to-zoom and doubleclick
///
class FlutterGestureDetector extends StatefulWidget {
  final ViewModel viewModel;

  final Widget child;

  /// The absorption factor of a swipe. The lower the factor the faster swiping
  /// stops.
  final double swipeAbsorption;

  final Size screensize;

  const FlutterGestureDetector(
      {Key? key,
      required this.viewModel,
      required this.child,
      required this.screensize,
      this.swipeAbsorption = 0.8})
      : assert(swipeAbsorption >= 0 && swipeAbsorption <= 1),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return FlutterGestureDetectorState();
  }
}

/////////////////////////////////////////////////////////////////////////////

class FlutterGestureDetectorState extends State<FlutterGestureDetector> {
  static final _log = new Logger('FlutterGestureDetectorState');

  _GestureTapEvent? _gestureTapEvent;

  _GestureEvent? _gestureEvent;

  @override
  FlutterGestureDetector get widget => super.widget;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _gestureEvent?.dispose();
    _gestureEvent = null;
    _gestureTapEvent?.dispose();
    _gestureTapEvent = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool doLog = false;

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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (TapDownDetails details) {
        if (doLog)
          _log.info(
              "onTapDown $details with localPosition ${details.localPosition}");
        _gestureEvent?.dispose();
        _gestureEvent = null;
        // only if we do not have already a double tap down event
        _gestureTapEvent ??= _TapDownEvent(
            viewModel: widget.viewModel,
            tapDownLocalPosition: details.localPosition,
            size: widget.screensize);
      },
      // onLongPressDown: (LongPressDownDetails details) {
      //   if (doLog) _log.info("onLongPressDown $details");
      // },
      // onPanDown: (DragDownDetails details) {
      //   if (doLog) _log.info("onPanDown $details");
      // },
      onTapUp: (TapUpDetails details) {
        if (doLog) _log.info("onTapUp $details");
        _gestureTapEvent?.tapUp(size: widget.screensize);
        _gestureTapEvent = null;
        _gestureEvent?.dispose();
        _gestureEvent = null;
      },
      onDoubleTapDown: (TapDownDetails details) {
        if (doLog)
          _log.info(
              "onDoubleTapDown $details with localPosition ${details.localPosition}");
        _gestureTapEvent?.dispose();
        _gestureTapEvent =
            _DoubleTapEvent(viewModel: widget.viewModel, details: details);
      },
      onDoubleTap: () {
        if (doLog) _log.info("onDoubleTap");
        //print("Screensize: ${widget.screensize}");
        _gestureTapEvent?.tapUp(size: widget.screensize);
        _gestureTapEvent?.dispose();
        _gestureTapEvent = null;
        _gestureEvent?.dispose();
        _gestureEvent = null;
      },
      onScaleStart: (ScaleStartDetails details) {
        if (doLog) _log.info("onScaleStart $details");
        _gestureTapEvent?.dispose();
        _gestureEvent?.dispose();
        _gestureEvent = null;
        if (_gestureTapEvent?.longPressed ?? false) {
          _gestureEvent = _DragAroundEvent(viewModel: widget.viewModel);
        } else {
          if (details.pointerCount == 1) {
            _gestureEvent ??= _MoveAroundEvent(
                viewModel: widget.viewModel,
                swipeAbsorption: widget.swipeAbsorption,
                startLocalFocalPoint: details.localFocalPoint,
                startCenter: widget.viewModel.mapViewPosition!.getCenter());
          } else {
            _gestureEvent = _ScaleEvent(
                viewModel: widget.viewModel,
                startLocalFocalPoint: details.localFocalPoint,
                startCenter: widget.viewModel.mapViewPosition!.getCenter());
          }
        }
        _gestureTapEvent = null;
        widget.viewModel.gestureEvent();
      },
      onScaleUpdate: (ScaleUpdateDetails details) {
        if (doLog) _log.info("onScaleUpdate $details");
        _gestureEvent?.update(details: details, size: widget.screensize);
      },
      onScaleEnd: (ScaleEndDetails details) {
        if (doLog) _log.info("onScaleEnd $details");
        _gestureTapEvent?.dispose();
        _gestureTapEvent = null;
        bool disposeAllowed =
            _gestureEvent?.end(details: details, size: widget.screensize) ??
                true;
        if (disposeAllowed) _gestureEvent?.dispose();
        _gestureEvent = null;
      },
      child: widget.child,
    );
  }
}

/////////////////////////////////////////////////////////////////////////////

abstract class _GestureEvent {
  void dispose();

  void update({required ScaleUpdateDetails details, required Size size});

  /// return true if a dispose is allowed, otherwise false
  bool end({required ScaleEndDetails details, required Size size});
}

/////////////////////////////////////////////////////////////////////////////

abstract class _GestureTapEvent {
  void dispose();

  void tapUp({required Size size});

  bool get longPressed;
}

/////////////////////////////////////////////////////////////////////////////

class _ScaleEvent implements _GestureEvent {
  static final _log = new Logger('FlutterGestureDetectorState._ScaleEvent');

  final ViewModel viewModel;

  final Offset startLocalFocalPoint;

  final Mappoint startCenter;

  double? lastScale = null;

  Offset? lastFocalPoint;

  _ScaleEvent(
      {required this.viewModel,
      required this.startLocalFocalPoint,
      required this.startCenter});

  @override
  void update({required ScaleUpdateDetails details, required Size size}) {
    // do not send tiny changes
    if (lastScale != null &&
        ((details.scale / lastScale!) - 1).abs() < 0.01 &&
        lastFocalPoint != null &&
        (lastFocalPoint!.dx - details.focalPoint.dx).abs() < 5 &&
        (lastFocalPoint!.dy - details.focalPoint.dy).abs() < 5) return;
    // _log.info(
    //     "onScaleUpdate scale ${details.scale} around ${details.localFocalPoint}, rotation ${details.rotation}, size $size");
    lastScale = details.scale;
    lastFocalPoint = details.focalPoint;
    /*MapViewPosition? newPost =*/
    viewModel.setScaleAround(details.localFocalPoint, details.scale);
    // Mappoint(details.localFocalPoint.dx * viewModel.viewScaleFactor,
    //     details.localFocalPoint.dy * viewModel.viewScaleFactor),
    // lastScale!);
  }

  @override
  bool end({required ScaleEndDetails details, required Size size}) {
    // no zoom: 0, double zoom: 1, half zoom: -1
    double zoomLevelOffset = log(lastScale!) / log(2);
    int zoomLevelDiff = zoomLevelOffset.round();
    if (zoomLevelDiff != 0) {
      // Complete large zooms towards gesture direction
      num mult = pow(2, zoomLevelDiff);
      // if (doLog)
      //   _log.info("onScaleEnd zooming now zoomLevelDiff $zoomLevelDiff");
      PositionInfo? positionInfo = RotateHelper.normalize(
          viewModel, size, startLocalFocalPoint.dx, startLocalFocalPoint.dy);
      if (positionInfo == null) return true;
      MapViewPosition newPost = viewModel.zoomAround(
          positionInfo.latitude +
              (viewModel.mapViewPosition!.latitude! - positionInfo.latitude) /
                  mult,
          positionInfo.longitude +
              (viewModel.mapViewPosition!.longitude! - positionInfo.longitude) /
                  mult,
          viewModel.mapViewPosition!.zoomLevel + zoomLevelDiff);
//      if (doLog) _log.info("onScaleEnd  resulting in ${newPost.toString()}");
    } else if (lastScale != 1) {
      // no significant zoom. Restore the old zoom
      /*MapViewPosition newPost =*/ viewModel
          .setZoomLevel((viewModel.mapViewPosition!.zoomLevel));
      // if (doLog)
      //   _log.info(
      //       "onScaleEnd Restored zoom to ${viewModel.mapViewPosition!.zoomLevel}");
    }
    return true;
  }

  @override
  void dispose() {}
}

/////////////////////////////////////////////////////////////////////////////

class _TapDownEvent implements _GestureTapEvent {
  final ViewModel viewModel;

  final Offset tapDownLocalPosition;

  final int tapDownTime;

  bool _stop = false;

  bool _longPressed = false;

  Timer? _timer;

  _TapDownEvent(
      {required this.viewModel,
      required this.tapDownLocalPosition,
      required Size size})
      : tapDownTime = DateTime.now().millisecondsSinceEpoch {
    _timer = Timer(const Duration(milliseconds: 500), () {
      // tapped at least 500 ms, user wants to move something (or long-press, but the latter is reported at onTapUp)
      if (_stop) return;
      _longPressed = true;

      PositionInfo? positionInfo = RotateHelper.normalize(
          viewModel, size, tapDownLocalPosition.dx, tapDownLocalPosition.dy);
      if (positionInfo == null) return;

      MoveAroundEvent event = MoveAroundEvent(
        latitude: positionInfo.latitude,
        longitude: positionInfo.longitude,
        projection: viewModel.mapViewPosition!.projection,
        mappoint: positionInfo.mappoint,
      );

      viewModel.gestureMoveStartEvent(event);
    });
  }

  @override
  void dispose() {
    _stop = true;
    _timer?.cancel();
    _timer = null;
  }

  @override
  void tapUp({required Size size}) {
    _stop = true;
    _timer?.cancel();
    _timer = null;
    PositionInfo? positionInfo = RotateHelper.normalize(
        viewModel, size, tapDownLocalPosition.dx, tapDownLocalPosition.dy);
    if (positionInfo == null) return;

    if (longPressed) {
      // tapped at least 500 ms, long tap
      // we already reported a gestureMoveStartEvent, we should cancel it

      MoveAroundEvent event = MoveAroundEvent(
        latitude: positionInfo.latitude,
        longitude: positionInfo.longitude,
        projection: viewModel.mapViewPosition!.projection,
        mappoint: positionInfo.mappoint,
      );
      viewModel.gestureMoveCancelEvent(event);

      TapEvent tapEvent = TapEvent(
        latitude: positionInfo.latitude,
        longitude: positionInfo.longitude,
        projection: viewModel.mapViewPosition!.projection,
        mappoint: positionInfo.mappoint,
      );
      viewModel.longTapEvent(tapEvent);
      return;
    } else {
      TapEvent event = TapEvent(
        latitude: positionInfo.latitude,
        longitude: positionInfo.longitude,
        projection: viewModel.mapViewPosition!.projection,
        mappoint: positionInfo.mappoint,
      );
      viewModel.tapEvent(event);
      return;
    }
  }

  @override
  bool get longPressed => _longPressed;
}

/////////////////////////////////////////////////////////////////////////////

class _DoubleTapEvent extends _GestureTapEvent {
  final ViewModel viewModel;

  Offset? _doubleTapLocalPosition;

  _DoubleTapEvent({required this.viewModel, required TapDownDetails details}) {
    _doubleTapLocalPosition = details.localPosition;
  }

  @override
  void dispose() {}

  @override
  void tapUp({TapUpDetails? details, required Size size}) {
    //print("pos: $_doubleTapLocalPosition");
    if (_doubleTapLocalPosition == null) return;
    PositionInfo? positionInfo = RotateHelper.normalize(viewModel, size,
        _doubleTapLocalPosition!.dx, _doubleTapLocalPosition!.dy);
    if (positionInfo == null) return;
    // interpolate the new center between the old center and where we
    // pressed now. The new center is half-way between our double-pressed point and the old-center
    viewModel.zoomInAround(
        (positionInfo.latitude - viewModel.mapViewPosition!.latitude!) / 2 +
            viewModel.mapViewPosition!.latitude!,
        (positionInfo.longitude - viewModel.mapViewPosition!.longitude!) / 2 +
            viewModel.mapViewPosition!.longitude!);
  }

  @override
  bool get longPressed => false;
}

/////////////////////////////////////////////////////////////////////////////

class _MoveAroundEvent implements _GestureEvent {
  /// Minimum pixels per second (squared) to activate flinging
  final double _swipeThresholdSquared = 20000;

  final int _swipeSleepMs = 33; // milliseconds between swipes

  final ViewModel viewModel;

  final Offset startLocalFocalPoint;

  final Mappoint startCenter;

  Timer? _swipeTimer;

  Offset? _swipeOffset;

  /// The absorption factor of a swipe. The lower the factor the faster swiping
  /// stops.
  final double swipeAbsorption;

  Offset? _updateLocalFocalPoint;

  _MoveAroundEvent(
      {required this.viewModel,
      required this.swipeAbsorption,
      required this.startLocalFocalPoint,
      required this.startCenter});

  @override
  void dispose() {
    _swipeTimer?.cancel();
    _swipeTimer = null;
    _swipeOffset = null;
  }

  @override
  void update({required ScaleUpdateDetails details, required Size size}) {
    _updateLocalFocalPoint = details.localFocalPoint;
    // move map around
    double diffX = (details.localFocalPoint.dx - startLocalFocalPoint.dx) *
        viewModel.viewScaleFactor;
    double diffY = (details.localFocalPoint.dy - startLocalFocalPoint.dy) *
        viewModel.viewScaleFactor;
    if (viewModel.mapViewPosition?.rotation != 0) {
      double hyp = sqrt(diffX * diffX + diffY * diffY);
      double rad = atan2(diffY, diffX);
      double rot = viewModel.mapViewPosition!.rotationRadian;
      diffX = cos(-rot + rad) * hyp;
      diffY = sin(-rot + rad) * hyp;

      // print(
      //     "diff: $diffX/$diffY @ ${widget.viewModel.mapViewPosition!.rotation}($rad) from ${(details.localFocalPoint.dx - _startLocalFocalPoint!.dx) * widget.viewModel.viewScaleFactor}/${(details.localFocalPoint.dy - _startLocalFocalPoint!.dy) * widget.viewModel.viewScaleFactor}");
    }
    // if (_lastMoveTimestamp <
    //     DateTime.now().millisecondsSinceEpoch - 300) {
    //_lastMoveTimestamp = DateTime.now().millisecondsSinceEpoch;
    //_log.info("Move around ${_scaleEvent!.startCenter.x - diffX}/${_scaleEvent!.startCenter.y - diffY}");
    viewModel.setCenter(startCenter.x - diffX, startCenter.y - diffY);
//          }
  }

  @override
  bool end({required ScaleEndDetails details, required Size size}) {
    if (details.velocity.pixelsPerSecond.distanceSquared <
        _swipeThresholdSquared) {
      return true;
    }
    if (_updateLocalFocalPoint != null) {
      // check the direction of velocity. If velocity points to wrong direction do not swipe
      if ((_updateLocalFocalPoint!.dx - startLocalFocalPoint.dx).sign !=
          details.velocity.pixelsPerSecond.dx.sign) return true;
      if ((_updateLocalFocalPoint!.dy - startLocalFocalPoint.dy).sign !=
          details.velocity.pixelsPerSecond.dy.sign) return true;
    }
    // calculate the offset per iteration
    _swipeOffset =
        details.velocity.pixelsPerSecond / 1000 * _swipeSleepMs.toDouble();
    if (viewModel.mapViewPosition?.rotation != 0) {
      double hyp = sqrt(_swipeOffset!.dx * _swipeOffset!.dx +
          _swipeOffset!.dy * _swipeOffset!.dy);
      double rad = atan2(_swipeOffset!.dy, _swipeOffset!.dx);
      double rot = viewModel.mapViewPosition!.rotationRadian;
      _swipeOffset = Offset(cos(-rot + rad) * hyp, sin(-rot + rad) * hyp);
      // print(
      //     "diff: $diffX/$diffY @ ${widget.viewModel.mapViewPosition!.rotation}($rad) from ${(details.localFocalPoint.dx - _startLocalFocalPoint!.dx) * widget.viewModel.viewScaleFactor}/${(details.localFocalPoint.dy - _startLocalFocalPoint!.dy) * widget.viewModel.viewScaleFactor}");
    }
    // if there is still a timer running, stop it now
    _swipeTimer?.cancel();
    _swipeTimer =
        Timer.periodic(Duration(milliseconds: _swipeSleepMs), (timer) {
      _swipeTimerProcess();
    });
    return false;
  }

  void _swipeTimerProcess() {
    // if (!mounted || _swipeOffset == null) {
    //   // we should stop swiping
    //   _swipeTimer?.cancel();
    //   _swipeTimer = null;
    //   _swipeOffset = null;
    //   return;
    // }
    //if (doLog) _log.info("Swiping ${_swipeOffset!.distance}");
    Mappoint? center = viewModel.mapViewPosition?.getCenter();
    if (center != null) {
      viewModel.setCenter(
          center.x - _swipeOffset!.dx, center.y - _swipeOffset!.dy);
    }
    // slow down after each iteration
    _swipeOffset = _swipeOffset! * swipeAbsorption;
    if (_swipeOffset!.distanceSquared < 20) {
      // only 4 pixels for the next iteration, now lets stop swiping
      _swipeTimer?.cancel();
      _swipeTimer = null;
      _swipeOffset = null;
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

class _DragAroundEvent implements _GestureEvent {
  final ViewModel viewModel;

  Offset? _updateLocalFocalPoint;

  _DragAroundEvent({required this.viewModel});

  @override
  void update({required ScaleUpdateDetails details, required Size size}) {
    // user tapped down, then waited. He does not want to move the map, he wants to move something around
    _updateLocalFocalPoint = details.localFocalPoint;
    PositionInfo? positionInfo = RotateHelper.normalize(viewModel, size,
        details.localFocalPoint.dx, details.localFocalPoint.dy);
    if (positionInfo == null) return;

    MoveAroundEvent event = MoveAroundEvent(
      latitude: positionInfo.latitude,
      longitude: positionInfo.longitude,
      projection: viewModel.mapViewPosition!.projection,
      mappoint: positionInfo.mappoint,
    );

    viewModel.gestureMoveUpdateEvent(event);
  }

  @override
  bool end({required ScaleEndDetails details, required Size size}) {
    PositionInfo? positionInfo = RotateHelper.normalize(viewModel, size,
        _updateLocalFocalPoint!.dx, _updateLocalFocalPoint!.dy);
    if (positionInfo == null) return true;

    MoveAroundEvent event = MoveAroundEvent(
      latitude: positionInfo.latitude,
      longitude: positionInfo.longitude,
      projection: viewModel.mapViewPosition!.projection,
      mappoint: positionInfo.mappoint,
    );

    viewModel.gestureMoveEndEvent(event);
    return true;
  }

  @override
  void dispose() {}
}
