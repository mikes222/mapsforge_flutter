import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/util/rotate_helper.dart';
import 'package:mapsforge_flutter_core/model.dart';

/// Recognizes short, long and double taps and informs [MapModel]
class DragAndDropGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  /// The maximum duration to wait for distinguishing between:
  /// short press: down-up - no further down event
  /// long press: down - no further up event
  /// double press: down - up - down, we do not wait for another up event
  final int longPressDuration;

  /// The maximum distance in pixels which the curser is allowed to move between tapDown and tapUp.
  final int maxDistance;

  final TapEventListener tapEventListener;

  const DragAndDropGestureDetector({
    super.key,
    required this.mapModel,
    this.longPressDuration = 350,
    this.maxDistance = 20,
    this.tapEventListener = TapEventListener.longTap,
  });

  @override
  State<DragAndDropGestureDetector> createState() => _DragAndDropGestureDetectorState();
}

//////////////////////////////////////////////////////////////////////////////

class _DragAndDropGestureDetectorState extends State<DragAndDropGestureDetector> {
  static final _log = Logger('_DragAndDropGestureDetectorState');

  final bool doLog = false;

  _Handler? _handler;

  _Status _status = _Status.start;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (PointerDownEvent event) {
            if (doLog) _log.info("onPointerDown $event");

            switch (_status) {
              case _Status.start:
                // second time down-event? check movement
                _handler?.cancelIfMoved(event.localPosition);
                if (_handler != null) {
                  // down after one fast click, maybe a double click
                  if (_handler!._upCount > 0) {
                    // already a double tap event
                    _handler!.sendDoubleClickToMapModel(event.localPosition);
                  }
                  return;
                }
                if (widget.mapModel.lastPosition == null) return;
                _handler = _Handler(
                  tapState: this,
                  lastPosition: widget.mapModel.lastPosition!,
                  mapModel: widget.mapModel,
                  longPressDuration: widget.longPressDuration,
                  maxDistance: widget.maxDistance,
                  size: constraints.biggest,
                  localPosition: event.localPosition,
                  tapEventListener: widget.tapEventListener,
                );
                break;
              case _Status.move:
                _handler?.cancel();
                _status = _Status.start;
                break;
            }
          },
          onPointerMove: (PointerMoveEvent event) {
            if (doLog) _log.info("onPointerMove $event");

            switch (_status) {
              case _Status.start:
                _handler?.cancelIfMoved(event.localPosition);
                break;
              case _Status.move:
                _handler?.sendMovement(event.localPosition);
                break;
            }
          },
          onPointerUp: (PointerUpEvent event) {
            if (doLog) _log.info("onPointerUp $event");

            switch (_status) {
              case _Status.start:
                _handler?.cancelIfMoved(event.localPosition);
                _handler?.incUpCount();
                break;
              case _Status.move:
                _handler?.sendFinish(event.localPosition);
                _status = _Status.start;
                break;
            }
          },
          onPointerCancel: (PointerCancelEvent event) {
            if (doLog) _log.info("onPointerCancel $event");

            _handler?.cancel();
            _status = _Status.start;
          },
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

//////////////////////////////////////////////////////////////////////////////

class _Handler {
  final int longPressDuration;

  final int maxDistance;

  final MapPosition lastPosition;

  final MapModel mapModel;

  final _DragAndDropGestureDetectorState tapState;

  final TapEventListener tapEventListener;

  final Size size;

  int _upCount = 0;

  late Timer _timer;

  late Offset _tapDownOffset;

  _Handler({
    required this.tapState,
    required this.lastPosition,
    required this.mapModel,
    required this.longPressDuration,
    required this.maxDistance,
    required this.size,
    required Offset localPosition,
    required this.tapEventListener,
  }) {
    _init(localPosition);
  }

  void dispose() {
    _timer.cancel();
    tapState._status = _Status.start;
    tapState._handler = null;
  }

  void _init(Offset localPosition) {
    _upCount = 0;
    _tapDownOffset = localPosition;
    _timer = Timer(Duration(milliseconds: longPressDuration), () {
      // 0 _upCount: this is a long press, otherwise a single tap
      if (tapState._status == _Status.start) {
        _timerExpired(localPosition);
      }
      if (tapState._status == _Status.start) {
        // timer expired, still in start state, so we should stop now
        dispose();
      }
      _timer.cancel();
    });
  }

  /// increments the number of up events. Only relevant for starting the dragNdrop process.
  void incUpCount() {
    ++_upCount;
  }

  /// cancel the starting process if the cursor moved too much. Only relevant for starting the dragNdrop process.
  void cancelIfMoved(Offset localPosition) {
    if ((localPosition.dx - _tapDownOffset.dx).abs() > maxDistance || (localPosition.dy - _tapDownOffset.dy).abs() > maxDistance) {
      dispose();
    }
  }

  void cancel() {
    mapModel.dragNdrop(
      DragNdropEvent(latitude: 0, longitude: 0, projection: lastPosition.projection, mappoint: const Mappoint(0, 0), type: DragNdropEventType.cancel),
    );
    dispose();
  }

  void sendMovement(Offset offset) {
    mapModel.dragNdrop(_createEvent(DragNdropEventType.move, offset));
  }

  void sendFinish(Offset offset) {
    mapModel.dragNdrop(_createEvent(DragNdropEventType.finish, offset));
    dispose();
  }

  /// Second click event in the timer period. Only relevant for starting the dragNdrop process.
  bool sendDoubleClickToMapModel(Offset offset) {
    // _upCount == 1
    if (tapEventListener == TapEventListener.doubleTap) {
      mapModel.dragNdrop(_createEvent(DragNdropEventType.start, offset));
      tapState._status = _Status.move;
      return true;
    }
    return false;
  }

  /// The two second timer is expired. This is relevant for starting the dragNdrop process. We can now decide
  /// between single tap and long tap.
  void _timerExpired(Offset offset) {
    if (_upCount == 0) {
      if (tapEventListener == TapEventListener.longTap) {
        mapModel.dragNdrop(_createEvent(DragNdropEventType.start, offset));
        tapState._status = _Status.move;
      }
    } else {
      // _upCount == 1
      if (tapEventListener == TapEventListener.singleTap) {
        mapModel.dragNdrop(_createEvent(DragNdropEventType.start, offset));
        tapState._status = _Status.move;
      }
    }
  }

  DragNdropEvent _createEvent(DragNdropEventType type, Offset offset) {
    PositionInfo positionInfo = RotateHelper.normalize(lastPosition, size, offset.dx, offset.dy);

    DragNdropEvent tapEvent = DragNdropEvent(
      latitude: positionInfo.latitude,
      longitude: positionInfo.longitude,
      projection: lastPosition.projection,
      mappoint: positionInfo.mappoint,
      type: type,
    );
    return tapEvent;
  }
}

//////////////////////////////////////////////////////////////////////////////

enum _Status { start, move }
