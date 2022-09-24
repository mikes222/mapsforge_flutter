import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/src/model/mappoint.dart';

import '../../core.dart';

///
/// A detector for finger-gestures. It currently supports move, pinch-to-zoom and doubleclick
///
class FlutterGestureDetector extends StatefulWidget {
  final ViewModel viewModel;

  final Widget child;

  const FlutterGestureDetector(
      {Key? key, required this.viewModel, required this.child})
      : super(key: key);

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
  final double _swipeAbsorption = 0.8;

  Mappoint? _startLeftUpper;

  Offset? _startLocalFocalPoint;

  Offset? _updateLocalFocalPoint;

  double? _lastScale;

  Offset? _doubleTapLocalPosition;

  Timer? _swipeTimer;

  Offset? _swipeOffset;

  _TapDownEvent? _tapDownEvent;

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
        _startLocalFocalPoint = null;
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
          widget.viewModel.gestureMoveCancelEvent(
              _tapDownEvent!.tapDownLocalPosition.dx,
              _tapDownEvent!.tapDownLocalPosition.dy);
          _tapDownEvent!.stop();
          _tapDownEvent = null;
          widget.viewModel
              .longTapEvent(details.localPosition.dx, details.localPosition.dy);
          return;
        } else {
          _tapDownEvent!.stop();
          _tapDownEvent = null;
          widget.viewModel
              .tapEvent(details.localPosition.dx, details.localPosition.dy);
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
        if (widget.viewModel.mapViewPosition?.leftUpper != null) {
          // lat/lon of the position where we double-clicked
          double latitude = widget.viewModel.mapViewPosition!.projection!
              .pixelYToLatitude(widget.viewModel.mapViewPosition!.leftUpper!.y +
                  _doubleTapLocalPosition!.dy *
                      widget.viewModel.viewScaleFactor);
          double longitude = widget.viewModel.mapViewPosition!.projection!
              .pixelXToLongitude(
                  widget.viewModel.mapViewPosition!.leftUpper!.x +
                      _doubleTapLocalPosition!.dx *
                          widget.viewModel.viewScaleFactor);
          // interpolate the new center between the old center and where we pressed now. The new center is half-way between our double-pressed point and the old-center
          widget.viewModel.zoomInAround(
              (latitude - widget.viewModel.mapViewPosition!.latitude!) / 2 +
                  widget.viewModel.mapViewPosition!.latitude!,
              (longitude - widget.viewModel.mapViewPosition!.longitude!) / 2 +
                  widget.viewModel.mapViewPosition!.longitude!);
          // widget.viewModel
          //     .doubleTapEvent(latitude, longitude);
          //widget.viewModel.gestureEvent();
        }
        _swipeTimer?.cancel();
        _swipeTimer = null;
        _swipeOffset = null;
        _tapDownEvent?.stop();
        _tapDownEvent = null;
      },
      onScaleStart: (ScaleStartDetails details) {
        if (doLog) _log.info("onScaleStart $details");
        _startLocalFocalPoint = details.localFocalPoint;
        _startLeftUpper = widget.viewModel.mapViewPosition?.leftUpper;
        _lastScale = null;
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
        if (details.scale == 1) {
          // move around
          if (_startLeftUpper == null) return;
          if (_startLocalFocalPoint == null) return;
          // do not react if less than 5 points dragged
          // if ((_startLocalFocalPoint!.dx - details.localFocalPoint.dx) *
          //             (_startLocalFocalPoint!.dx - details.localFocalPoint.dx) +
          //         (_startLocalFocalPoint!.dy - details.localFocalPoint.dy) *
          //             (_startLocalFocalPoint!.dy - details.localFocalPoint.dy) <
          //     _minDragThresholdSquared) return;
          _updateLocalFocalPoint = details.localFocalPoint;
          if (_tapDownEvent != null && _tapDownEvent!.longPressed) {
            // user tapped down, then waited. He does not want to move the map, he wants to move something around
            widget.viewModel.gestureMoveUpdateEvent(
                details.localFocalPoint.dx, details.localFocalPoint.dy);
            return;
          }
          // move map around
          widget.viewModel.setLeftUpper(
              _startLeftUpper!.x +
                  _startLocalFocalPoint!.dx * widget.viewModel.viewScaleFactor -
                  details.localFocalPoint.dx * widget.viewModel.viewScaleFactor,
              _startLeftUpper!.y +
                  _startLocalFocalPoint!.dy * widget.viewModel.viewScaleFactor -
                  details.localFocalPoint.dy *
                      widget.viewModel.viewScaleFactor);
        } else {
          // zoom
          // do not send tiny changes
          if (_lastScale != null &&
              ((details.scale / _lastScale!) - 1).abs() < 0.01) return;
          if (doLog)
            _log.info(
                "onScaleUpdate scale ${details.scale} around ${details.localFocalPoint}");
          _lastScale = details.scale;
          /*MapViewPosition? newPost =*/ widget.viewModel.setScaleAround(
              Mappoint(
                  details.localFocalPoint.dx * widget.viewModel.viewScaleFactor,
                  details.localFocalPoint.dy *
                      widget.viewModel.viewScaleFactor),
              _lastScale!);
        }
      },
      onScaleEnd: (ScaleEndDetails details) {
        if (doLog) _log.info("onScaleEnd $details");
        // stop here if this was just a move-operation and NOT a scale-operation
        if (_lastScale != null) {
          // no zoom: 0, double zoom: 1, half zoom: -1
          double zoomLevelOffset = log(this._lastScale!) / log(2);
          int zoomLevelDiff = zoomLevelOffset.round();
          if (zoomLevelDiff != 0) {
            // Complete large zooms towards gesture direction
            num mult = pow(2, zoomLevelDiff);
            if (doLog)
              _log.info("onScaleEnd zooming now zoomLevelDiff $zoomLevelDiff");
            // lat/lon of the position of the focus
            widget.viewModel.mapViewPosition!
                .calculateBoundingBox(widget.viewModel.mapDimension);
            // lat/lon of the focalPoint
            double latitude = widget.viewModel.mapViewPosition!.projection!
                .pixelYToLatitude(
                    widget.viewModel.mapViewPosition!.leftUpper!.y +
                        _startLocalFocalPoint!.dy *
                            widget.viewModel.viewScaleFactor);
            double longitude = widget.viewModel.mapViewPosition!.projection!
                .pixelXToLongitude(
                    widget.viewModel.mapViewPosition!.leftUpper!.x +
                        _startLocalFocalPoint!.dx *
                            widget.viewModel.viewScaleFactor);
            MapViewPosition newPost = widget.viewModel.zoomAround(
                latitude +
                    (widget.viewModel.mapViewPosition!.latitude! - latitude) /
                        mult,
                longitude +
                    (widget.viewModel.mapViewPosition!.longitude! - longitude) /
                        mult,
                widget.viewModel.mapViewPosition!.zoomLevel + zoomLevelDiff);
            if (doLog)
              _log.info("onScaleEnd  resulting in ${newPost.toString()}");
          } else if (_lastScale != 1) {
            // no significant zoom. Restore the old zoom
            /*MapViewPosition newPost =*/ widget.viewModel
                .setZoomLevel((widget.viewModel.mapViewPosition!.zoomLevel));
            if (doLog)
              _log.info(
                  "onScaleEnd Restored zoom to ${widget.viewModel.mapViewPosition!.zoomLevel}");
          }
          _swipeTimer?.cancel();
          _swipeTimer = null;
          _swipeOffset = null;
        } else {
          // there was no zoom , check for swipe
          if (_tapDownEvent != null && _tapDownEvent!.longPressed) {
            // user tapped down, then waited. He does not want to swipe, he wants to move something around
            widget.viewModel.gestureMoveEndEvent(
                _updateLocalFocalPoint!.dx, _updateLocalFocalPoint!.dy);
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
          if (_updateLocalFocalPoint != null && _startLocalFocalPoint != null) {
            // check the direction of velocity. If velocity points to wrong direction do not swipe
            if ((_updateLocalFocalPoint!.dx - _startLocalFocalPoint!.dx).sign !=
                details.velocity.pixelsPerSecond.dx.sign) return;
            if ((_updateLocalFocalPoint!.dy - _startLocalFocalPoint!.dy).sign !=
                details.velocity.pixelsPerSecond.dy.sign) return;
          }
          // calculate the offset per iteration
          _swipeOffset = details.velocity.pixelsPerSecond /
              1000 *
              _swipeSleepMs.toDouble();
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
    if (widget.viewModel.mapViewPosition?.leftUpper != null) {
      widget.viewModel.setLeftUpper(
          widget.viewModel.mapViewPosition!.leftUpper!.x - _swipeOffset!.dx,
          widget.viewModel.mapViewPosition!.leftUpper!.y - _swipeOffset!.dy);
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
      viewModel.gestureMoveStartEvent(
          tapDownLocalPosition.dx, tapDownLocalPosition.dy);
    });
  }

  void stop() {
    _stop = true;
  }

  bool get longPressed => _longPressed;
}
