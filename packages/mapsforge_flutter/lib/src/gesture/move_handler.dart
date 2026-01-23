import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/gesture/default_handler.dart';
import 'package:mapsforge_flutter/src/gesture/simple_velocity_calculator.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';

/// A handler for swipe gestures. The timer is used to distinguish between normal move events and drag (=wait until the timer expires) and drop events.
class MoveHandler extends DefaultHandler {
  static final _log = Logger('MoveHandler');

  /// The absorption factor of a swipe. The lower the factor the faster swiping
  /// stops.
  final double swipeAbsorption;

  final int _swipeSleepMs = 33; // milliseconds between swipes

  /// Timestamp of the next event sent to the mapModel to inform it that manual move is still active
  int _nextManualMoveEvent = 0;

  final SimpleVelocityCalculator velocityCalculator = SimpleVelocityCalculator();

  Timer? _swipeTimer;

  Offset? _swipeOffset;

  bool _moveActive = false;

  MappointRelative _lastOffset = const MappointRelative.zero();

  MoveHandler({required super.longPressDuration, required super.mapModel, this.swipeAbsorption = 0.9}) : assert(swipeAbsorption >= 0 && swipeAbsorption <= 1);

  @override
  void cancelTimer() {
    super.cancelTimer();
    _swipeTimer?.cancel();
    _swipeTimer = null;
  }

  @override
  void onTimeout() {
    super.onTimeout();
    _moveActive = false;
    _nextManualMoveEvent = 0;
  }

  @override
  void onPointerDown(MapPosition position, int pointerId, Offset offset, Map<int, Offset> pointers) {
    //_log.info("down ${pointers.length}, active $_moveActive, timer: ${activeTimer()}, swipetimer: $_swipeTimer, offset $_swipeOffset");
    if (pointers.length > 1) {
      cancelTimer();
      _moveActive = false;
      _swipeOffset = null;
      _nextManualMoveEvent = 0;
      return;
    }
    // cancel swiping
    cancelTimer();
    _moveActive = false;
    _swipeOffset = null;
    _nextManualMoveEvent = 0;

    _lastOffset = const MappointRelative.zero();
    super.onPointerDown(position, pointerId, offset, pointers);
  }

  @override
  void onPointerUp(int pointerId, Offset offset, Map<int, Offset> pointers) {
    //_log.info("up ${pointers.length}, active $_moveActive, timer: ${activeTimer()}, swipetimer: $_swipeTimer, offset $_swipeOffset");
    if (pointers.isEmpty && !_moveActive) {
      // cancel if the only point went up
      cancelTimer();
      _moveActive = false;
      _swipeOffset = null;
      _nextManualMoveEvent = 0;
      return;
    }
    // if (!_moveActive) {
    //   return;
    // }
    super.onPointerUp(pointerId, offset, pointers);
    cancelTimer();

    if (_swipeTimer != null) {
      // swipe still active
      _swipeTimer?.cancel();
      _swipeTimer = null;
      _swipeOffset = null;
      _nextManualMoveEvent = 0;
      return;
    }
    velocityCalculator.addEvent(offset);
    // calculate the offset per iteration
    _swipeOffset = velocityCalculator.lastVelocity.offsetPerMillisecond * _swipeSleepMs.toDouble();
    if (startPosition?.rotation != 0) {
      double hyp = sqrt(_swipeOffset!.dx * _swipeOffset!.dx + _swipeOffset!.dy * _swipeOffset!.dy);
      double rad = atan2(_swipeOffset!.dy, _swipeOffset!.dx);
      double rot = startPosition!.rotationRadian;
      _swipeOffset = Offset(cos(-rot + rad) * hyp, sin(-rot + rad) * hyp);
      // print(
      //     "diff: $diffX/$diffY @ ${widget.viewModel.mapViewPosition!.rotation}($rad) from ${(details.localFocalPoint.dx - _startLocalFocalPoint!.dx) * widget.viewModel.viewScaleFactor}/${(details.localFocalPoint.dy - _startLocalFocalPoint!.dy) * widget.viewModel.viewScaleFactor}");
    }
    _swipeTimer = Timer.periodic(Duration(milliseconds: _swipeSleepMs), (timer) {
      _swipeTimerProcess();
    });
  }

  @override
  void onPointerMove(int pointerId, Offset offset, Map<int, Offset> pointers) {
    //_log.info("move ${pointers.length}, active $_moveActive, timer: ${activeTimer()}, swipetimer: $_swipeTimer, offset $_swipeOffset");
    if (!activeTimer() && !_moveActive) {
      return;
    }
    super.onPointerMove(pointerId, offset, pointers);
    cancelTimer();
    _moveActive = true;

    velocityCalculator.addEvent(offset);
    double diffX = (offset.dx - startOffset!.dx) * MapsforgeSettingsMgr().getDeviceScaleFactor();
    double diffY = (offset.dy - startOffset!.dy) * MapsforgeSettingsMgr().getDeviceScaleFactor();
    if (startPosition!.rotation != 0) {
      double hyp = sqrt(diffX * diffX + diffY * diffY);
      double rad = atan2(diffY, diffX);
      double rot = startPosition!.rotationRadian;
      diffX = cos(-rot + rad) * hyp;
      diffY = sin(-rot + rad) * hyp;
    }
    if (_nextManualMoveEvent == 0 || _nextManualMoveEvent < DateTime.now().millisecondsSinceEpoch) {
      _nextManualMoveEvent = DateTime.now().millisecondsSinceEpoch + 1000;
      mapModel.manualMove(Object());
    }
    // double x = max(startPosition!.getCenter().x - diffX, 0);
    // double y = max(startPosition!.getCenter().y - diffY, 0);
    mapModel.moveCenter(_lastOffset.dx - diffX, _lastOffset.dy - diffY);
    _lastOffset = MappointRelative(diffX, diffY);
    //_log.info("  center: $x/$y $diffX/$diffY");
  }

  void _swipeTimerProcess() {
    //_log.info("swipe active $_moveActive, timer: ${activeTimer()}, swipetimer: $_swipeTimer, offset $_swipeOffset, center: $center");
    if (_nextManualMoveEvent == 0 || _nextManualMoveEvent < DateTime.now().millisecondsSinceEpoch) {
      _nextManualMoveEvent = DateTime.now().millisecondsSinceEpoch + 1000;
      mapModel.manualMove(Object());
    }
    mapModel.moveCenter(-_swipeOffset!.dx, -_swipeOffset!.dy);
    // slow down after each iteration
    _swipeOffset = _swipeOffset! * swipeAbsorption;
    if (_swipeOffset!.distanceSquared < 5) {
      // only 2 pixels for the next iteration, now lets stop swiping
      _swipeTimer?.cancel();
      _swipeTimer = null;
      _swipeOffset = null;
      _moveActive = false;
    }
  }
}
