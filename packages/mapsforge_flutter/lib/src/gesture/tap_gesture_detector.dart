import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/util/rotate_helper.dart';

/// Recognizes short, long and double taps and informs [MapModel]
class TapGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  /// The maximum duration to wait for distinguishing between:
  /// short press: down-up - no further down event
  /// long press: down - no further up event
  /// double press: down - up - down, we do not wait for another up event
  final int longPressDuration;

  /// The maximum distance in pixels which the curser is allowed to move between tapDown and tapUp.
  final int maxDistance;

  const TapGestureDetector({super.key, required this.mapModel, this.longPressDuration = 350, this.maxDistance = 20});

  @override
  State<TapGestureDetector> createState() => _TapGestureDetectorState();
}

//////////////////////////////////////////////////////////////////////////////

class _TapGestureDetectorState extends State<TapGestureDetector> {
  static final _log = Logger('_TapGestureDetectorState');

  final bool doLog = false;

  _Handler? _handler;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (PointerDownEvent event) {
            if (doLog) _log.info("onPointerDown $event");
            _handler?._cancelIfMoved(event.localPosition);

            if (_handler != null) {
              if (_handler!._upCount > 0) {
                // already a double tap event
                _handler!._cancel();
                _handler!._sendDoubleMapModel(constraints.biggest, event.localPosition);
                _handler = null;
              }
              return;
            }
            _handler = _Handler(
              tapState: this,
              lastPosition: widget.mapModel.lastPosition!,
              mapModel: widget.mapModel,
              longPressDuration: widget.longPressDuration,
              maxDistance: widget.maxDistance,
              size: constraints.biggest,
              localPosition: event.localPosition,
            );
          },
          onPointerUp: (PointerUpEvent event) {
            if (doLog) _log.info("onPointerUp $event");
            _handler?._cancelIfMoved(event.localPosition);
            _handler?._incUpCount();
          },
          onPointerCancel: (PointerCancelEvent event) {
            if (doLog) _log.info("onPointerCancel $event");
            _handler?._cancel();
            _handler = null;
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

  final _TapGestureDetectorState tapState;

  _Handler({
    required this.tapState,
    required this.lastPosition,
    required this.mapModel,
    required this.longPressDuration,
    required this.maxDistance,
    required Size size,
    required Offset localPosition,
  }) {
    _init(size, localPosition);
  }

  int _upCount = 0;

  late Timer _timer;

  late Offset _tapDownOffset;

  void _init(Size size, Offset localPosition) {
    _upCount = 0;
    _tapDownOffset = localPosition;
    _timer = Timer(Duration(milliseconds: longPressDuration), () {
      // 0 _upCount: this is a long press, otherwise a single tap
      _sendToMapModel(size, localPosition);
      tapState._handler = null;
    });
  }

  void _incUpCount() {
    ++_upCount;
  }

  void _cancelIfMoved(Offset localPosition) {
    if ((localPosition.dx - _tapDownOffset.dx).abs() > maxDistance || (localPosition.dy - _tapDownOffset.dy).abs() > maxDistance) {
      _timer.cancel();
      tapState._handler = null;
    }
  }

  void _cancel() {
    _timer.cancel();
  }

  void _sendDoubleMapModel(Size size, Offset offset) {
    PositionInfo positionInfo = RotateHelper.normalize(lastPosition, size, offset.dx, offset.dy);

    TapEvent tapEvent = TapEvent(
      latitude: positionInfo.latitude,
      longitude: positionInfo.longitude,
      projection: lastPosition.projection,
      mappoint: positionInfo.mappoint,
    );
    // _upCount == 1
    mapModel.doubleTap(tapEvent);
  }

  void _sendToMapModel(Size size, Offset offset) {
    PositionInfo positionInfo = RotateHelper.normalize(lastPosition, size, offset.dx, offset.dy);

    TapEvent tapEvent = TapEvent(
      latitude: positionInfo.latitude,
      longitude: positionInfo.longitude,
      projection: lastPosition.projection,
      mappoint: positionInfo.mappoint,
    );
    if (_upCount == 0) {
      mapModel.longTap(tapEvent);
    } else {
      // _upCount == 1
      mapModel.tap(tapEvent);
    }
  }
}
