import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/gesture/simple_velocity_calculator.dart';
import 'package:mapsforge_flutter/src/util/rotate_helper.dart';
import 'package:mapsforge_flutter_core/model.dart';
import 'package:mapsforge_flutter_core/utils.dart';

class GenericGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  /// The maximum duration to wait for distinguishing between:
  /// short press: down-up - no further down event
  /// long press: down - no further up event
  /// double press: down - up - down, we do not wait for another up event
  final int longPressDuration;

  /// The maximum distance in pixels which the curser is allowed to move between tapDown and tapUp.
  final int maxDistance;

  final TapEventListener tapEventListener;

  /// The absorption factor of a swipe. The lower the factor the faster swiping
  /// stops.
  final double swipeAbsorption;

  const GenericGestureDetector({
    super.key,
    required this.mapModel,
    this.longPressDuration = 350,
    this.maxDistance = 20,
    this.tapEventListener = TapEventListener.longTap,
    this.swipeAbsorption = 0.9,
  }) : assert(swipeAbsorption >= 0 && swipeAbsorption <= 1);

  @override
  State<GenericGestureDetector> createState() => _GenericGestureDetectorState();
}

//////////////////////////////////////////////////////////////////////////////

class _GenericGestureDetectorState extends State<GenericGestureDetector> {
  final List<Handler> _handlers = [];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (PointerDownEvent event) {
            MapPosition? position = widget.mapModel.lastPosition;
            if (position == null) return;
            for (var handler in List.of(_handlers)) {
              handler.onPointerDown(event.pointer, event.localPosition);
            }
            _createHandlerOnPointerDown(constraints.biggest, position, event.pointer, event.localPosition);
          },
          onPointerMove: (PointerMoveEvent event) {
            for (var handler in List.of(_handlers)) {
              handler.onPointerMove(event.pointer, event.localPosition);
            }
          },
          onPointerCancel: (PointerCancelEvent event) {
            for (var handler in List.of(_handlers)) {
              handler.onPointerCancel(event.pointer, event.localPosition);
            }
          },
          onPointerUp: (PointerUpEvent event) {
            for (var handler in List.of(_handlers)) {
              handler.onPointerUp(event.pointer, event.localPosition);
            }
          },
        );
      },
    );
  }

  void removeHandler(Handler handler) {
    _handlers.remove(handler);
  }

  void _createHandlerOnPointerDown(Size size, MapPosition position, int pointerId, Offset offset) {
    if (_handlers.firstWhereOrNull((test) => test is SingleTapHandler) == null) {
      _handlers.add(
        SingleTapHandler(
          longPressDuration: widget.longPressDuration,
          tapState: this,
          mapModel: widget.mapModel,
          size: size,
          startPosition: position,
          startOffset: offset,
          pointerId: pointerId,
        ),
      );
    }
    if (_handlers.firstWhereOrNull((test) => test is LongTapHandler) == null) {
      _handlers.add(
        LongTapHandler(
          longPressDuration: widget.longPressDuration,
          tapState: this,
          mapModel: widget.mapModel,
          size: size,
          startPosition: position,
          startOffset: offset,
        ),
      );
    }
    if (_handlers.firstWhereOrNull((test) => test is DoubleTapHandler) == null) {
      _handlers.add(
        DoubleTapHandler(
          longPressDuration: widget.longPressDuration,
          tapState: this,
          mapModel: widget.mapModel,
          size: size,
          startPosition: position,
          startOffset: offset,
          pointerId: pointerId,
        ),
      );
    }
    if (_handlers.firstWhereOrNull((test) => test is DragNdropHandler) == null) {
      _handlers.add(
        DragNdropHandler(
          longPressDuration: widget.longPressDuration,
          tapState: this,
          mapModel: widget.mapModel,
          size: size,
          startPosition: position,
          startOffset: offset,
          pointerId: pointerId,
        ),
      );
    }
    if (_handlers.firstWhereOrNull((test) => test is MoveHandler) == null) {
      _handlers.add(
        MoveHandler(
          longPressDuration: widget.longPressDuration,
          tapState: this,
          mapModel: widget.mapModel,
          size: size,
          startPosition: position,
          startOffset: offset,
          pointerId: pointerId,
          swipeAbsorption: widget.swipeAbsorption,
        ),
      );
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class Handler {
  final int longPressDuration;

  late final Timer _timer;

  final _GenericGestureDetectorState tapState;

  final MapModel mapModel;

  final Size size;

  final MapPosition startPosition;

  final Offset startOffset;

  final int maxDistance = 20;

  Handler({
    required this.longPressDuration,
    required this.tapState,
    required this.mapModel,
    required this.size,
    required this.startPosition,
    required this.startOffset,
  }) {
    _timer = Timer(Duration(milliseconds: longPressDuration), () {
      onTimeout();
    });
  }

  void dispose() {
    _timer.cancel();
  }

  void onTimeout() {}

  void onPointerDown(int pointerId, Offset offset) {}

  void onPointerUp(int pointerId, Offset offset) {}

  void onPointerMove(int pointerId, Offset offset) {}

  void onPointerCancel(int pointerId, Offset offset) {
    _timer.cancel();
    tapState.removeHandler(this);
  }

  TapEvent createEvent(Offset offset) {
    PositionInfo positionInfo = RotateHelper.normalize(startPosition, size, offset.dx, offset.dy);
    // interpolate the new center between the old center and where we
    // pressed now. The new center is half-way between our double-pressed point and the old-center
    TapEvent tapEvent = TapEvent(
      latitude: positionInfo.latitude,
      longitude: positionInfo.longitude,
      projection: startPosition.projection,
      mappoint: positionInfo.mappoint,
    );
    return tapEvent;
  }

  bool hasMoved(Offset offset) {
    if ((startOffset.dx - offset.dx).abs() > maxDistance || (startOffset.dy - offset.dy).abs() > maxDistance) {
      return true;
    }
    return false;
  }
}

//////////////////////////////////////////////////////////////////////////////

/// Recognizes a single tap event. The handler must be active to prevent recognizing the second tap of a double tap as a single tap.
class SingleTapHandler extends Handler {
  int _tapUpCount = 0;

  int _tapDownCount = 0;

  int pointerId = -1;

  SingleTapHandler({
    required super.longPressDuration,
    required super.tapState,
    required super.mapModel,
    required super.size,
    required super.startPosition,
    required super.startOffset,
    required this.pointerId,
  });

  @override
  void onTimeout() {
    super.onTimeout();
    if (_tapUpCount == 1 && _tapDownCount == 0) mapModel.tap(createEvent(startOffset));
    tapState.removeHandler(this);
  }

  @override
  void onPointerDown(int pointerId, Offset offset) {
    super.onPointerDown(pointerId, offset);
    // a second pointer went down, cancel the handler
    if (_tapUpCount == 0 && pointerId != this.pointerId) {
      _timer.cancel();
      tapState.removeHandler(this);
    }
    ++_tapDownCount;
  }

  @override
  void onPointerUp(int pointerId, Offset offset) {
    super.onPointerUp(pointerId, offset);
    ++_tapUpCount;
  }

  @override
  void onPointerMove(int pointerId, Offset offset) {
    super.onPointerMove(pointerId, offset);
    if (hasMoved(offset)) {
      _timer.cancel();
      tapState.removeHandler(this);
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class LongTapHandler extends Handler {
  LongTapHandler({
    required super.longPressDuration,
    required super.tapState,
    required super.mapModel,
    required super.size,
    required super.startPosition,
    required super.startOffset,
  });

  @override
  void onTimeout() {
    super.onTimeout();
    mapModel.longTap(createEvent(startOffset));
    _timer.cancel();
    tapState.removeHandler(this);
  }

  @override
  void onPointerDown(int pointerId, Offset offset) {
    super.onPointerDown(pointerId, offset);
    // a second pointer went down, cancel the handler
    _timer.cancel();
    tapState.removeHandler(this);
  }

  @override
  void onPointerUp(int pointerId, Offset offset) {
    super.onPointerUp(pointerId, offset);
    _timer.cancel();
    tapState.removeHandler(this);
  }

  @override
  void onPointerMove(int pointerId, Offset offset) {
    super.onPointerMove(pointerId, offset);
    if (hasMoved(offset)) {
      _timer.cancel();
      tapState.removeHandler(this);
    }
  }
}

//////////////////////////////////////////////////////////////////////////////

class DoubleTapHandler extends Handler {
  int _tapUpCount = 0;

  //int _tapDownCount = 0;

  int pointerId = -1;

  DoubleTapHandler({
    required super.longPressDuration,
    required super.tapState,
    required super.mapModel,
    required super.size,
    required super.startPosition,
    required super.startOffset,
    required this.pointerId,
  });

  @override
  void onTimeout() {
    super.onTimeout();
    tapState.removeHandler(this);
  }

  @override
  void onPointerDown(int pointerId, Offset offset) {
    super.onPointerDown(pointerId, offset);
    if (_tapUpCount == 0) {
      _timer.cancel();
      tapState.removeHandler(this);
      return;
    }
    mapModel.doubleTap(createEvent(offset));
    _timer.cancel();
    tapState.removeHandler(this);
  }

  @override
  void onPointerUp(int pointerId, Offset offset) {
    super.onPointerUp(pointerId, offset);
    ++_tapUpCount;
  }
}

//////////////////////////////////////////////////////////////////////////////

class DragNdropHandler extends Handler {
  int pointerId = -1;

  DragNdropStatus status = DragNdropStatus.start;

  DragNdropHandler({
    required super.longPressDuration,
    required super.tapState,
    required super.mapModel,
    required super.size,
    required super.startPosition,
    required super.startOffset,
    required this.pointerId,
  });

  @override
  void onTimeout() {
    super.onTimeout();
    mapModel.dragNdrop(_createEvent(DragNdropEventType.start, startOffset));
    status = DragNdropStatus.move;
  }

  @override
  void onPointerDown(int pointerId, Offset offset) {
    super.onPointerDown(pointerId, offset);
    if (pointerId != this.pointerId) {
      mapModel.dragNdrop(_createEvent(DragNdropEventType.cancel, startOffset));
      _timer.cancel();
      tapState.removeHandler(this);
      return;
    }
    _timer.cancel();
    tapState.removeHandler(this);
  }

  @override
  void onPointerUp(int pointerId, Offset offset) {
    super.onPointerUp(pointerId, offset);
    if (status == DragNdropStatus.start) {
      _timer.cancel();
      tapState.removeHandler(this);
    } else {
      mapModel.dragNdrop(_createEvent(DragNdropEventType.finish, offset));
      _timer.cancel();
      tapState.removeHandler(this);
    }
  }

  @override
  void onPointerMove(int pointerId, Offset offset) {
    super.onPointerMove(pointerId, offset);
    if (status == DragNdropStatus.start) {
      if (hasMoved(offset)) {
        _timer.cancel();
        tapState.removeHandler(this);
        return;
      }
    } else {
      mapModel.dragNdrop(_createEvent(DragNdropEventType.move, offset));
    }
  }

  DragNdropEvent _createEvent(DragNdropEventType type, Offset offset) {
    PositionInfo positionInfo = RotateHelper.normalize(startPosition, size, offset.dx, offset.dy);

    DragNdropEvent tapEvent = DragNdropEvent(
      latitude: positionInfo.latitude,
      longitude: positionInfo.longitude,
      projection: startPosition.projection,
      mappoint: positionInfo.mappoint,
      type: type,
    );
    return tapEvent;
  }
}

//////////////////////////////////////////////////////////////////////////////

enum DragNdropStatus { start, move }

//////////////////////////////////////////////////////////////////////////////

class MoveHandler extends Handler {
  int pointerId = -1;

  int _nextManualMoveEvent = 0;

  /// The absorption factor of a swipe. The lower the factor the faster swiping
  /// stops.
  final double swipeAbsorption;

  final SimpleVelocityCalculator velocityCalculator = SimpleVelocityCalculator();

  Timer? _swipeTimer;

  Offset? _swipeOffset;

  final int _swipeSleepMs = 33; // milliseconds between swipes

  MoveHandler({
    required super.longPressDuration,
    required super.tapState,
    required super.mapModel,
    required super.size,
    required super.startPosition,
    required super.startOffset,
    required this.pointerId,
    required this.swipeAbsorption,
  });

  @override
  void dispose() {
    super.dispose();
    _swipeTimer?.cancel();
    _swipeTimer = null;
  }

  @override
  void onTimeout() {
    super.onTimeout();
    tapState.removeHandler(this);
  }

  @override
  void onPointerDown(int pointerId, Offset offset) {
    super.onPointerDown(pointerId, offset);
    _timer.cancel();
    tapState.removeHandler(this);
  }

  @override
  void onPointerUp(int pointerId, Offset offset) {
    super.onPointerUp(pointerId, offset);
    _timer.cancel();

    if (_swipeTimer != null) {
      // swipe still active
      _swipeTimer?.cancel();
      _swipeTimer = null;
      _swipeOffset = null;
      tapState.removeHandler(this);
      return;
    }
    // calculate the offset per iteration
    _swipeOffset = velocityCalculator.lastVelocity.offsetPerMillisecond * _swipeSleepMs.toDouble();
    if (mapModel.lastPosition?.rotation != 0) {
      double hyp = sqrt(_swipeOffset!.dx * _swipeOffset!.dx + _swipeOffset!.dy * _swipeOffset!.dy);
      double rad = atan2(_swipeOffset!.dy, _swipeOffset!.dx);
      double rot = mapModel.lastPosition!.rotationRadian;
      _swipeOffset = Offset(cos(-rot + rad) * hyp, sin(-rot + rad) * hyp);
      // print(
      //     "diff: $diffX/$diffY @ ${widget.viewModel.mapViewPosition!.rotation}($rad) from ${(details.localFocalPoint.dx - _startLocalFocalPoint!.dx) * widget.viewModel.viewScaleFactor}/${(details.localFocalPoint.dy - _startLocalFocalPoint!.dy) * widget.viewModel.viewScaleFactor}");
    }
    _swipeTimer = Timer.periodic(Duration(milliseconds: _swipeSleepMs), (timer) {
      _swipeTimerProcess();
    });

    tapState.removeHandler(this);
  }

  @override
  void onPointerMove(int pointerId, Offset offset) {
    super.onPointerMove(pointerId, offset);
    _timer.cancel();

    velocityCalculator.addEvent(offset);
    double diffX = (offset.dx - startOffset.dx) * MapsforgeSettingsMgr().getDeviceScaleFactor();
    double diffY = (offset.dy - startOffset.dy) * MapsforgeSettingsMgr().getDeviceScaleFactor();
    if (mapModel.lastPosition?.rotation != 0) {
      double hyp = sqrt(diffX * diffX + diffY * diffY);
      double rad = atan2(diffY, diffX);
      double rot = mapModel.lastPosition!.rotationRadian;
      diffX = cos(-rot + rad) * hyp;
      diffY = sin(-rot + rad) * hyp;
    }
    if (_nextManualMoveEvent == 0 || _nextManualMoveEvent < DateTime.now().millisecondsSinceEpoch) {
      _nextManualMoveEvent = DateTime.now().millisecondsSinceEpoch + 1000;
      mapModel.manualMove(Object());
    }
    mapModel.setCenter(startPosition.getCenter().x - diffX, startPosition.getCenter().y - diffY);
  }

  void _swipeTimerProcess() {
    Mappoint? center = mapModel.lastPosition?.getCenter();
    if (center != null) {
      if (_nextManualMoveEvent == 0 || _nextManualMoveEvent < DateTime.now().millisecondsSinceEpoch) {
        _nextManualMoveEvent = DateTime.now().millisecondsSinceEpoch + 1000;
        mapModel.manualMove(Object());
      }
      mapModel.setCenter(center.x - _swipeOffset!.dx, center.y - _swipeOffset!.dy);
    }
    // slow down after each iteration
    _swipeOffset = _swipeOffset! * swipeAbsorption;
    if (_swipeOffset!.distanceSquared < 5) {
      // only 2 pixels for the next iteration, now lets stop swiping
      _swipeTimer?.cancel();
      _swipeTimer = null;
      _swipeOffset = null;
      tapState.removeHandler(this);
    }
  }
}

//////////////////////////////////////////////////////////////////////////////
