import 'dart:ui';

import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/gesture/default_handler.dart';

/// Recognizes a single tap event. The handler must be active to prevent recognizing the second tap of a double tap as a single tap.
class SingleTapHandler extends DefaultHandler {
  int _tapUpCount = 0;

  int _tapDownCount = 0;

  SingleTapHandler({required super.longPressDuration, required super.mapModel});

  @override
  void cancelTimer() {
    super.cancelTimer();
    _tapUpCount = 0;
    _tapDownCount = 0;
  }

  @override
  void onTimeout() {
    if (_tapUpCount == 1 && _tapDownCount == 1) mapModel.tap(createEvent(startOffset!));
    super.onTimeout();
  }

  @override
  void onPointerDown(MapPosition position, int pointerId, Offset offset, Map<int, Offset> pointers) {
    if (pointers.length > 1) {
      cancelTimer();
      return;
    }
    super.onPointerDown(position, pointerId, offset, pointers);
    ++_tapDownCount;
  }

  @override
  void onPointerUp(int pointerId, Offset offset, Map<int, Offset> pointers) {
    if (!activeTimer()) return;
    super.onPointerUp(pointerId, offset, pointers);
    ++_tapUpCount;
  }

  @override
  void onPointerMove(int pointerId, Offset offset, Map<int, Offset> pointers) {
    if (!activeTimer()) return;
    super.onPointerMove(pointerId, offset, pointers);
    if (hasMoved(offset)) {
      cancelTimer();
    }
  }
}
