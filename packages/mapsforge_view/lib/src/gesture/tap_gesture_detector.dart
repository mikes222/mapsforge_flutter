import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:logging/logging.dart';
import 'package:mapsforge_view/mapsforge.dart';
import 'package:mapsforge_view/src/util/rotate_helper.dart';

/// Recognizes short, long and double taps and informs [MapModel]
class TapGestureDetector extends StatefulWidget {
  final MapModel mapModel;

  final int longPressDuration;

  const TapGestureDetector({super.key, required this.mapModel, this.longPressDuration = 350});

  @override
  State<TapGestureDetector> createState() => _TapGestureDetectorState();
}

//////////////////////////////////////////////////////////////////////////////

class _TapGestureDetectorState extends State<TapGestureDetector> {
  static final _log = Logger('_TapGestureDetectorState');

  final bool doLog = false;

  int _upCount = 0;

  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, BoxConstraints constraints) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (PointerDownEvent event) {
            if (doLog) _log.info("onPointerDown $event");
            if (_timer != null) {
              if (_upCount > 0) {
                // already a double tap event
                _timer?.cancel();
                _timer = null;
                MapPosition lastPosition = widget.mapModel.lastPosition!;
                _sendToMapModel(lastPosition, constraints.biggest, event.localPosition, _upCount == 0, _upCount > 0);
              }
              return;
            }
            _upCount = 0;
            _timer = Timer(Duration(milliseconds: widget.longPressDuration), () {
              _timer = null;
              MapPosition lastPosition = widget.mapModel.lastPosition!;
              // 0 _upCount: this is a long press, otherwise a single tap
              _sendToMapModel(lastPosition, constraints.biggest, event.localPosition, _upCount == 0, _upCount > 1);
            });
          },
          onPointerUp: (PointerUpEvent event) {
            if (doLog) _log.info("onPointerUp $event");
            ++_upCount;
          },
          child: const SizedBox.expand(),
        );
      },
    );
  }

  void _sendToMapModel(MapPosition lastPosition, Size size, Offset offset, bool longPressed, bool doublePressed) {
    PositionInfo positionInfo = RotateHelper.normalize(lastPosition, size, offset.dx, offset.dy);

    TapEvent tapEvent = TapEvent(
      latitude: positionInfo.latitude,
      longitude: positionInfo.longitude,
      projection: lastPosition.projection,
      mappoint: positionInfo.mappoint,
    );
    if (longPressed) {
      widget.mapModel.longTap(tapEvent);
    } else if (doublePressed) {
      widget.mapModel.doubleTap(tapEvent);
    } else {
      widget.mapModel.tap(tapEvent);
    }
  }
}
