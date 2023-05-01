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

  const FlutterGestureDetector(
      {Key? key,
      required this.viewModel,
      required this.child,
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

  /// Minimum pixels per second (squared) to activate flinging
  final double _swipeThresholdSquared = 20000;

  //final double _minDragThresholdSquared = 10;

  final int _swipeSleepMs = 100; // milliseconds between swipes

  /// The rate of the slowdown after each iteration
  late final double _swipeAbsorption;

  Offset? _updateLocalFocalPoint;

  Offset? _doubleTapLocalPosition;

  Timer? _swipeTimer;

  Offset? _swipeOffset;

  _TapDownEvent? _tapDownEvent;

  _ScaleEvent? _scaleEvent;

  @override
  FlutterGestureDetector get widget => super.widget;

  @override
  void initState() {
    super.initState();
    _swipeAbsorption = widget.swipeAbsorption;
  }

  @override
  void dispose() {
    _swipeTimer?.cancel();
    _swipeTimer = null;
    _swipeOffset = null;
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
        _swipeTimer?.cancel();
        _swipeTimer = null;
        _swipeOffset = null;
        _tapDownEvent = _TapDownEvent(
            viewModel: widget.viewModel,
            tapDownLocalPosition: details.localPosition);
        _scaleEvent = null;
      },
      // onLongPressDown: (LongPressDownDetails details) {
      //   if (doLog) _log.info("onLongPressDown $details");
      // },
      // onPanDown: (DragDownDetails details) {
      //   if (doLog) _log.info("onPanDown $details");
      // },
      onTapUp: (TapUpDetails details) {
        if (doLog) _log.info("onTapUp $details");
        if (_tapDownEvent == null) return;
        if (_tapDownEvent!.longPressed) {
          // tapped at least 500 ms, long tap
          // we already reported a gestureMoveStartEvent, we should cancel it
          PositionInfo? positionInfo = RotateHelper.normalize(
              widget.viewModel,
              _tapDownEvent!.tapDownLocalPosition.dx,
              _tapDownEvent!.tapDownLocalPosition.dy);
          if (positionInfo == null) return;

          MoveAroundEvent event = MoveAroundEvent(
            latitude: positionInfo.latitude,
            longitude: positionInfo.longitude,
            mapPixelMappoint: Mappoint(positionInfo.center.x + positionInfo.dx,
                positionInfo.center.y + positionInfo.dy),
            projection: widget.viewModel.mapViewPosition!.projection,
          );

          widget.viewModel.gestureMoveCancelEvent(event);
          _tapDownEvent!.stop();
          _tapDownEvent = null;

          TapEvent tapEvent = TapEvent(
              latitude: positionInfo.latitude,
              longitude: positionInfo.longitude,
              mapPixelMappoint: Mappoint(
                  positionInfo.center.x + positionInfo.dx,
                  positionInfo.center.y + positionInfo.dy),
              projection: widget.viewModel.mapViewPosition!.projection);
          widget.viewModel.longTapEvent(tapEvent);
          return;
        } else {
          _tapDownEvent!.stop();
          _tapDownEvent = null;

          PositionInfo? positionInfo = RotateHelper.normalize(widget.viewModel,
              details.localPosition.dx, details.localPosition.dy);
          if (positionInfo == null) return;

          TapEvent event = TapEvent(
              latitude: positionInfo.latitude,
              longitude: positionInfo.longitude,
              mapPixelMappoint: Mappoint(
                  positionInfo.center.x + positionInfo.dx,
                  positionInfo.center.y + positionInfo.dy),
              projection: widget.viewModel.mapViewPosition!.projection);

          widget.viewModel.tapEvent(event);
          return;
        }
      },
      onDoubleTapDown: (TapDownDetails details) {
        if (doLog)
          _log.info(
              "onDoubleTapDown $details with localPosition ${details.localPosition}");
        _doubleTapLocalPosition = details.localPosition;
      },
      onDoubleTap: () {
        if (doLog)
          _log.info(
              "onDoubleTap with _doubleTapLocalPosition ${_doubleTapLocalPosition}");
        // it should always non-null but just for safety do a null-check
        if (_doubleTapLocalPosition == null) return;
        PositionInfo? positionInfo = RotateHelper.normalize(widget.viewModel,
            _doubleTapLocalPosition!.dx, _doubleTapLocalPosition!.dy);
        if (positionInfo == null) return;

        // interpolate the new center between the old center and where we
        // pressed now. The new center is half-way between our double-pressed point and the old-center
        widget.viewModel.zoomInAround(
            (positionInfo.latitude -
                        widget.viewModel.mapViewPosition!.latitude!) /
                    2 +
                widget.viewModel.mapViewPosition!.latitude!,
            (positionInfo.longitude -
                        widget.viewModel.mapViewPosition!.longitude!) /
                    2 +
                widget.viewModel.mapViewPosition!.longitude!);
        _swipeTimer?.cancel();
        _swipeTimer = null;
        _swipeOffset = null;
        _tapDownEvent?.stop();
        _tapDownEvent = null;
      },
      onScaleStart: (ScaleStartDetails details) {
        if (doLog) _log.info("onScaleStart $details");
        _scaleEvent = _ScaleEvent(
            startLocalFocalPoint: details.localFocalPoint,
            startCenter: widget.viewModel.mapViewPosition!.getCenter());
        if (_tapDownEvent != null) {
          if (_tapDownEvent!.longPressed) {
            // tapped at least 500 ms, user wants to move something
            return;
          } else {
            // swipe event
            _tapDownEvent?.stop();
          }
        }
        widget.viewModel.gestureEvent();
      },
      onScaleUpdate: (ScaleUpdateDetails details) {
        if (doLog) _log.info("onScaleUpdate $details");
        if (_scaleEvent == null) return;
        if (details.scale == 1) {
          // move around
          _updateLocalFocalPoint = details.localFocalPoint;
          if (_tapDownEvent != null && _tapDownEvent!.longPressed) {
            // user tapped down, then waited. He does not want to move the map, he wants to move something around
            PositionInfo? positionInfo = RotateHelper.normalize(
                widget.viewModel,
                details.localFocalPoint.dx,
                details.localFocalPoint.dy);
            if (positionInfo == null) return;

            MoveAroundEvent event = MoveAroundEvent(
              latitude: positionInfo.latitude,
              longitude: positionInfo.longitude,
              mapPixelMappoint: Mappoint(
                positionInfo.center.x + positionInfo.dx,
                positionInfo.center.y + positionInfo.dy,
              ),
              projection: widget.viewModel.mapViewPosition!.projection,
            );

            widget.viewModel.gestureMoveUpdateEvent(event);
            return;
          }
          // move map around
          double diffX = (details.localFocalPoint.dx -
                  _scaleEvent!.startLocalFocalPoint.dx) *
              widget.viewModel.viewScaleFactor;
          double diffY = (details.localFocalPoint.dy -
                  _scaleEvent!.startLocalFocalPoint.dy) *
              widget.viewModel.viewScaleFactor;
          if (widget.viewModel.mapViewPosition?.rotation != 0) {
            double hyp = sqrt(diffX * diffX + diffY * diffY);
            double rad = atan2(diffY, diffX);
            double rot = widget.viewModel.mapViewPosition!.rotationRadian;
            diffX = cos(-rot + rad) * hyp;
            diffY = sin(-rot + rad) * hyp;

            // print(
            //     "diff: $diffX/$diffY @ ${widget.viewModel.mapViewPosition!.rotation}($rad) from ${(details.localFocalPoint.dx - _startLocalFocalPoint!.dx) * widget.viewModel.viewScaleFactor}/${(details.localFocalPoint.dy - _startLocalFocalPoint!.dy) * widget.viewModel.viewScaleFactor}");
          }
          widget.viewModel.setCenter(_scaleEvent!.startCenter.x - diffX,
              _scaleEvent!.startCenter.y - diffY);
        } else {
          // zoom
          _scaleEvent!.scaleUpdate(doLog, widget.viewModel, details);
        }
      },
      onScaleEnd: (ScaleEndDetails details) {
        if (doLog) _log.info("onScaleEnd $details");
        // stop here if this was just a move-operation and NOT a scale-operation
        if (_scaleEvent?.lastScale != null) {
          _scaleEvent!.scaleEnd(doLog, widget.viewModel);
          _swipeTimer?.cancel();
          _swipeTimer = null;
          _swipeOffset = null;
        } else {
          // there was no zoom , check for swipe
          if (_tapDownEvent != null && _tapDownEvent!.longPressed) {
            // user tapped down, then waited. He does not want to swipe, he wants to move something around
            PositionInfo? positionInfo = RotateHelper.normalize(
                widget.viewModel,
                _updateLocalFocalPoint!.dx,
                _updateLocalFocalPoint!.dy);
            if (positionInfo == null) return;

            MoveAroundEvent event = MoveAroundEvent(
              latitude: positionInfo.latitude,
              longitude: positionInfo.longitude,
              mapPixelMappoint: Mappoint(
                  positionInfo.center.x + positionInfo.dx,
                  positionInfo.center.y + positionInfo.dy),
              projection: widget.viewModel.mapViewPosition!.projection,
            );

            widget.viewModel.gestureMoveEndEvent(event);
            _tapDownEvent = null;
            return;
          }
          _tapDownEvent?.stop();
          _tapDownEvent = null;
          if (doLog)
            _log.info(
                "Squared is ${details.velocity.pixelsPerSecond.distanceSquared}");
          if (details.velocity.pixelsPerSecond.distanceSquared <
              _swipeThresholdSquared) {
            return;
          }
          if (_updateLocalFocalPoint != null &&
              _scaleEvent?.startLocalFocalPoint != null) {
            // check the direction of velocity. If velocity points to wrong direction do not swipe
            if ((_updateLocalFocalPoint!.dx -
                        _scaleEvent!.startLocalFocalPoint.dx)
                    .sign !=
                details.velocity.pixelsPerSecond.dx.sign) return;
            if ((_updateLocalFocalPoint!.dy -
                        _scaleEvent!.startLocalFocalPoint.dy)
                    .sign !=
                details.velocity.pixelsPerSecond.dy.sign) return;
          }
          // calculate the offset per iteration
          _swipeOffset = details.velocity.pixelsPerSecond /
              1000 *
              _swipeSleepMs.toDouble();
          if (widget.viewModel.mapViewPosition?.rotation != 0) {
            double hyp = sqrt(_swipeOffset!.dx * _swipeOffset!.dx +
                _swipeOffset!.dy * _swipeOffset!.dy);
            double rad = atan2(_swipeOffset!.dy, _swipeOffset!.dx);
            double rot = widget.viewModel.mapViewPosition!.rotationRadian;
            _swipeOffset = Offset(cos(-rot + rad) * hyp, sin(-rot + rad) * hyp);
            // print(
            //     "diff: $diffX/$diffY @ ${widget.viewModel.mapViewPosition!.rotation}($rad) from ${(details.localFocalPoint.dx - _startLocalFocalPoint!.dx) * widget.viewModel.viewScaleFactor}/${(details.localFocalPoint.dy - _startLocalFocalPoint!.dy) * widget.viewModel.viewScaleFactor}");
          }
          // if there is still a timer running, stop it now
          _swipeTimer?.cancel();
          _swipeTimer =
              Timer.periodic(Duration(milliseconds: _swipeSleepMs), (timer) {
            _swipeTimerProcess(doLog);
          });
        }
      },
      child: widget.child,
    );
  }

  void _swipeTimerProcess(final bool doLog) {
    if (!mounted || _swipeOffset == null) {
      // we should stop swiping
      _swipeTimer?.cancel();
      _swipeTimer = null;
      _swipeOffset = null;
      return;
    }
    if (doLog) _log.info("Swiping ${_swipeOffset!.distance}");
    Mappoint? center = widget.viewModel.mapViewPosition?.getCenter();
    if (center != null) {
      widget.viewModel
          .setCenter(center.x - _swipeOffset!.dx, center.y - _swipeOffset!.dy);
    }
    // slow down after each iteration
    _swipeOffset = _swipeOffset! * _swipeAbsorption;
    if (_swipeOffset!.distanceSquared < 20) {
      // only 4 pixels for the next iteration, now lets stop swiping
      _swipeTimer?.cancel();
      _swipeTimer = null;
      _swipeOffset = null;
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

class _ScaleEvent {
  static final _log = new Logger('FlutterGestureDetectorState._ScaleEvent');

  final Offset startLocalFocalPoint;

  final Mappoint startCenter;

  double? lastScale = null;

  _ScaleEvent({required this.startLocalFocalPoint, required this.startCenter});

  void scaleUpdate(
      bool doLog, ViewModel viewModel, ScaleUpdateDetails details) {
    // do not send tiny changes
    if (lastScale != null && ((details.scale / lastScale!) - 1).abs() < 0.01)
      return;
    if (doLog)
      _log.info(
          "onScaleUpdate scale ${details.scale} around ${details.localFocalPoint}");
    lastScale = details.scale;
    /*MapViewPosition? newPost =*/
    viewModel.setScaleAround(
        Mappoint(details.localFocalPoint.dx * viewModel.viewScaleFactor,
            details.localFocalPoint.dy * viewModel.viewScaleFactor),
        lastScale!);
  }

  void scaleEnd(bool doLog, ViewModel viewModel) {
    // no zoom: 0, double zoom: 1, half zoom: -1
    double zoomLevelOffset = log(lastScale!) / log(2);
    int zoomLevelDiff = zoomLevelOffset.round();
    if (zoomLevelDiff != 0) {
      // Complete large zooms towards gesture direction
      num mult = pow(2, zoomLevelDiff);
      if (doLog)
        _log.info("onScaleEnd zooming now zoomLevelDiff $zoomLevelDiff");
      PositionInfo? positionInfo = RotateHelper.normalize(
          viewModel, startLocalFocalPoint.dx, startLocalFocalPoint.dy);
      if (positionInfo == null) return;
      MapViewPosition newPost = viewModel.zoomAround(
          positionInfo.latitude +
              (viewModel.mapViewPosition!.latitude! - positionInfo.latitude) /
                  mult,
          positionInfo.longitude +
              (viewModel.mapViewPosition!.longitude! - positionInfo.longitude) /
                  mult,
          viewModel.mapViewPosition!.zoomLevel + zoomLevelDiff);
      if (doLog) _log.info("onScaleEnd  resulting in ${newPost.toString()}");
    } else if (lastScale != 1) {
      // no significant zoom. Restore the old zoom
      /*MapViewPosition newPost =*/ viewModel
          .setZoomLevel((viewModel.mapViewPosition!.zoomLevel));
      if (doLog)
        _log.info(
            "onScaleEnd Restored zoom to ${viewModel.mapViewPosition!.zoomLevel}");
    }
  }
}

/////////////////////////////////////////////////////////////////////////////

class _TapDownEvent {
  final ViewModel viewModel;

  final Offset tapDownLocalPosition;

  final int tapDownTime;

  bool _stop = false;

  bool _longPressed = false;

  _TapDownEvent({required this.viewModel, required this.tapDownLocalPosition})
      : tapDownTime = DateTime.now().millisecondsSinceEpoch {
    Future.delayed(const Duration(milliseconds: 500), () {
      // tapped at least 500 ms, user wants to move something (or long-press, but the latter is reported at onTapUp)
      if (_stop) return;
      _longPressed = true;

      PositionInfo? positionInfo = RotateHelper.normalize(
          viewModel, tapDownLocalPosition.dx, tapDownLocalPosition.dy);
      if (positionInfo == null) return;

      MoveAroundEvent event = MoveAroundEvent(
        latitude: positionInfo.latitude,
        longitude: positionInfo.longitude,
        mapPixelMappoint: Mappoint(
          positionInfo.center.x + positionInfo.dx,
          positionInfo.center.y + positionInfo.dy,
        ),
        projection: viewModel.mapViewPosition!.projection,
      );

      viewModel.gestureMoveStartEvent(event);
    });
  }

  void processLongPress() {}

  void stop() {
    _stop = true;
  }

  bool get longPressed => _longPressed;
}
