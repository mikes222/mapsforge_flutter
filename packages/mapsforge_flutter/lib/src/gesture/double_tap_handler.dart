import 'dart:ui';

import 'package:mapsforge_flutter/mapsforge.dart';
import 'package:mapsforge_flutter/src/gesture/default_handler.dart';

class DoubleTapHandler extends DefaultHandler {
  DoubleTapHandler({required super.longPressDuration, required super.mapModel});

  @override
  void onPointerDown(MapPosition position, int pointerId, Offset offset, Map<int, Offset> pointers) {
    if (pointers.length > 1) {
      cancelTimer();
      return;
    }
    if (activeTimer()) {
      cancelTimer();
      mapModel.doubleTap(createEvent(offset));
      return;
    }
    super.onPointerDown(position, pointerId, offset, pointers);
  }

  @override
  void onPointerUp(int pointerId, Offset offset, Map<int, Offset> pointers) {
    if (!activeTimer()) return;
    super.onPointerUp(pointerId, offset, pointers);
  }

  @override
  void onPointerMove(int pointerId, Offset offset, Map<int, Offset> pointers) {
    if (hasMoved(offset)) {
      cancelTimer();
    }
    super.onPointerMove(pointerId, offset, pointers);
  }
}
